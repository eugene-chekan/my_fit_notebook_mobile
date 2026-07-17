import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../app_navigator.dart';
import '../data/models/profile.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/schedule_repository.dart';
import '../l10n/app_localizations.dart';
import '../screens/routine_screen.dart';

/// Schedules local reminders for planned workouts that have a time set. The
/// single entry point is [resync]: it cancels all pending reminders and
/// reschedules the future timed plans straight from the DB, so it's safe to
/// call after any change and on app launch. Tapping a reminder opens the
/// routine. Reminders are best-effort — any failure is swallowed so it can
/// never break scheduling itself.
class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final ScheduleRepository _schedules = ScheduleRepository();

  bool _initialized = false;

  static const _channelId = 'workout_reminders';

  Future<void> init() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));

      const android = AndroidInitializationSettings('ic_workout_notification');
      const settings = InitializationSettings(android: android);
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) => _openRoutine(response.payload),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _initialized = true;
    } catch (error, stack) {
      debugPrint('ReminderService.init failed: $error\n$stack');
    }
  }

  /// Navigate to the routine that a tapped reminder was launched from — call
  /// this once after runApp so a tap from the terminated state lands correctly.
  Future<void> handleAppLaunch() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _openRoutine(details!.notificationResponse?.payload),
        );
      }
    } catch (_) {
      // No launch payload — nothing to do.
    }
  }

  void _openRoutine(String? payload) {
    final routineId = int.tryParse(payload ?? '');
    if (routineId == null) return;
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => RoutineScreen(routineId: routineId)),
    );
  }

  /// Cancel every pending reminder and reschedule the future timed plans from
  /// the DB. The single source of truth, mirroring the workout notification.
  Future<void> resync() async {
    if (!_initialized) await init();
    try {
      await _plugin.cancelAll();
      final now = DateTime.now();
      final todayIso = ScheduleRepository.isoDate(now);
      final plans = await _schedules.listRemindable(todayIso);
      if (plans.isEmpty) return;

      final t = await AppLocalizations.delegate.load(await _resolveLocale());
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          t.workoutReminderChannel,
          channelDescription: t.workoutReminderChannel,
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

      for (final plan in plans) {
        final when = _dateTimeFor(plan.scheduledDate, plan.scheduledTime);
        if (when == null || !when.isAfter(now)) continue;
        await _plugin.zonedSchedule(
          plan.id,
          t.reminderTitle,
          plan.routineName,
          tz.TZDateTime.from(when, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: '${plan.routineId}',
        );
      }
    } catch (error, stack) {
      debugPrint('ReminderService.resync failed: $error\n$stack');
    }
  }

  /// Combine a yyyy-MM-dd date and an HH:mm time into a local DateTime.
  static DateTime? _dateTimeFor(String date, String? time) {
    if (time == null) return null;
    try {
      final d = DateTime.parse(date);
      final parts = time.split(':');
      return DateTime(d.year, d.month, d.day, int.parse(parts[0]), int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  Future<Locale> _resolveLocale() async {
    final profile = await ProfileRepository().getProfile();
    switch (profile.language) {
      case AppLanguage.en:
        return const Locale('en');
      case AppLanguage.ru:
        return const Locale('ru');
      default:
        final device = PlatformDispatcher.instance.locale.languageCode;
        return device == 'ru' ? const Locale('ru') : const Locale('en');
    }
  }
}

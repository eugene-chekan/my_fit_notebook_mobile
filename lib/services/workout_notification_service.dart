import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../data/models/profile.dart';
import '../data/models/routine.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/routine_repository.dart';
import '../data/services/workout_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/formatters.dart';

/// Shared-prefs key for the small state blob the background task isolate reads
/// to render the live timer.
const String _kStateKey = 'workout_notification_state';

/// Notification action-button ids. Also the payload the task isolate sends back
/// to the app when a button is tapped.
const String _kPause = 'workout_pause';
const String _kResume = 'workout_resume';
const String _kFinish = 'workout_finish';

/// A snapshot of the running workout, serialised into the shared data blob so
/// the background isolate can render the notification without touching the DB.
/// The pause maths mirror [WorkoutService] exactly so the notification clock
/// matches the in-app one (net elapsed freezes while paused).
class _WorkoutState {
  const _WorkoutState({
    required this.title,
    required this.startMs,
    required this.pausedSeconds,
    required this.paused,
    required this.pausedAtMs,
    required this.pausedLabel,
    required this.pauseLabel,
    required this.resumeLabel,
    required this.finishLabel,
  });

  final String title;
  final int startMs;
  final int pausedSeconds;
  final bool paused;
  final int pausedAtMs;
  final String pausedLabel;
  final String pauseLabel;
  final String resumeLabel;
  final String finishLabel;

  int get elapsedSeconds {
    if (startMs <= 0) return 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    var paused = pausedSeconds;
    if (this.paused && pausedAtMs > 0) {
      paused += (now - pausedAtMs) ~/ 1000;
    }
    final net = ((now - startMs) ~/ 1000) - paused;
    return net < 0 ? 0 : net;
  }

  /// "12:34" while running, "paused · 12:34" while paused.
  String get notificationText {
    final clock = formatClock(elapsedSeconds);
    return paused ? '$pausedLabel · $clock' : clock;
  }

  List<NotificationButton> get buttons => [
    if (paused)
      NotificationButton(id: _kResume, text: resumeLabel)
    else
      NotificationButton(id: _kPause, text: pauseLabel),
    NotificationButton(id: _kFinish, text: finishLabel),
  ];

  String toJson() => jsonEncode({
    'title': title,
    'startMs': startMs,
    'pausedSeconds': pausedSeconds,
    'paused': paused,
    'pausedAtMs': pausedAtMs,
    'pausedLabel': pausedLabel,
    'pauseLabel': pauseLabel,
    'resumeLabel': resumeLabel,
    'finishLabel': finishLabel,
  });

  static _WorkoutState? tryParse(String? raw) {
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return _WorkoutState(
      title: map['title'] as String? ?? '',
      startMs: (map['startMs'] as num?)?.toInt() ?? 0,
      pausedSeconds: (map['pausedSeconds'] as num?)?.toInt() ?? 0,
      paused: map['paused'] as bool? ?? false,
      pausedAtMs: (map['pausedAtMs'] as num?)?.toInt() ?? 0,
      pausedLabel: map['pausedLabel'] as String? ?? 'paused',
      pauseLabel: map['pauseLabel'] as String? ?? 'Pause',
      resumeLabel: map['resumeLabel'] as String? ?? 'Resume',
      finishLabel: map['finishLabel'] as String? ?? 'Finish',
    );
  }
}

int _epochMs(String? iso) {
  if (iso == null) return 0;
  try {
    return DateTime.parse(iso).millisecondsSinceEpoch;
  } catch (_) {
    return 0;
  }
}

/// The task-isolate entry point. Must be a top-level (or static) function
/// annotated with `vm:entry-point` so it survives tree-shaking.
@pragma('vm:entry-point')
void workoutNotificationCallback() {
  FlutterForegroundTask.setTaskHandler(_WorkoutTaskHandler());
}

/// Runs in a background isolate: every second it re-reads the shared state and
/// repaints the ongoing notification's clock, so it keeps ticking on the lock
/// screen / drawer even when the app is backgrounded. Button taps are forwarded
/// to the app isolate, which owns the DB.
class _WorkoutTaskHandler extends TaskHandler {
  _WorkoutState? _state;

  Future<void> _reload() async {
    _state = _WorkoutState.tryParse(
      await FlutterForegroundTask.getData<String>(key: _kStateKey),
    );
  }

  void _render() {
    final state = _state;
    if (state == null) return;
    FlutterForegroundTask.updateService(
      notificationTitle: state.title,
      notificationText: state.notificationText,
      notificationButtons: state.buttons,
    );
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _reload();
    _render();
  }

  @override
  void onRepeatEvent(DateTime timestamp) => _render();

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  @override
  void onReceiveData(Object data) {
    // The app pokes us after writing new state (pause/resume/rename).
    if (data == 'refresh') {
      _reload().then((_) => _render());
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    FlutterForegroundTask.sendDataToMain(id);
  }
}

/// App-isolate controller: keeps the ongoing workout notification in lockstep
/// with the DB. The single entry point is [sync] — call it whenever the routine
/// state may have changed; it starts, updates, or stops the foreground service
/// to match. Notification buttons are handled here (the DB lives in this
/// isolate) via a global data callback.
class WorkoutNotificationService {
  WorkoutNotificationService._();

  static final WorkoutNotificationService instance =
      WorkoutNotificationService._();

  final RoutineRepository _routines = RoutineRepository();
  final WorkoutService _workoutService = WorkoutService();

  bool _initialized = false;
  bool _channelReady = false;
  int? _activeRoutineId;

  /// Wire up the isolate communication port and the button-tap callback. Safe
  /// to call more than once. Call once at app start.
  void bootstrap() {
    if (_initialized) return;
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    _initialized = true;
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

  void _configureChannel(AppLocalizations t) {
    if (_channelReady) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'workout_running',
        channelName: t.workoutRunning,
        channelDescription: t.workoutRunning,
        // Silent + persistent: no sound/vibration, only alerts once, and shows
        // its full content on the lock screen.
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    _channelReady = true;
  }

  _WorkoutState _stateFor(Routine routine, AppLocalizations t) => _WorkoutState(
    title: routine.name,
    startMs: _epochMs(routine.startedAt),
    pausedSeconds: routine.pausedSeconds,
    paused: routine.isPaused,
    pausedAtMs: _epochMs(routine.pausedAt),
    pausedLabel: t.paused,
    pauseLabel: t.pause,
    resumeLabel: t.resume,
    finishLabel: t.finish,
  );

  /// Reconcile the notification with [routine]: show/refresh it while the
  /// workout is running, tear it down otherwise. Idempotent — the provider
  /// calls this on every load, so on-screen start/pause/resume/finish all flow
  /// through here automatically. The notification is a best-effort side effect:
  /// any platform/permission failure is swallowed so it can never break the
  /// workout itself.
  Future<void> sync(Routine? routine) async {
    try {
      if (routine == null || !routine.isStarted) {
        await _stop();
        return;
      }
      _activeRoutineId = routine.id;
      final t = await AppLocalizations.delegate.load(await _resolveLocale());
      _configureChannel(t);

      final permission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (permission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }

      final state = _stateFor(routine, t);
      await FlutterForegroundTask.saveData(key: _kStateKey, value: state.toJson());

      if (await FlutterForegroundTask.isRunningService) {
        FlutterForegroundTask.sendDataToTask('refresh');
        await FlutterForegroundTask.updateService(
          notificationTitle: state.title,
          notificationText: state.notificationText,
          notificationButtons: state.buttons,
        );
      } else {
        await FlutterForegroundTask.startService(
          notificationTitle: state.title,
          notificationText: state.notificationText,
          notificationButtons: state.buttons,
          callback: workoutNotificationCallback,
        );
      }
    } catch (error, stack) {
      debugPrint('WorkoutNotificationService.sync failed: $error\n$stack');
    }
  }

  /// On app launch, re-arm (or clear) the notification from whatever the DB
  /// says — covers the case where the app was killed mid-workout.
  Future<void> resync() async {
    try {
      final routines = await _routines.listRoutines();
      Routine? active;
      for (final r in routines) {
        if (r.isStarted) {
          active = r;
          break;
        }
      }
      await sync(active);
    } catch (error, stack) {
      debugPrint('WorkoutNotificationService.resync failed: $error\n$stack');
    }
  }

  Future<void> _stop() async {
    _activeRoutineId = null;
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  /// A notification button was tapped. The app isolate owns the DB, so we run
  /// the same lifecycle actions the on-screen controls would, then reconcile.
  Future<void> _onTaskData(Object data) async {
    final routineId = _activeRoutineId;
    if (routineId == null) return;
    try {
      switch (data) {
        case _kPause:
          await _workoutService.pauseWorkout(routineId);
          await sync(await _routines.getRoutine(routineId));
        case _kResume:
          await _workoutService.resumeWorkout(routineId);
          await sync(await _routines.getRoutine(routineId));
        case _kFinish:
          await _workoutService.finishWorkout(routineId);
          await _stop();
      }
    } catch (error, stack) {
      debugPrint('WorkoutNotificationService._onTaskData failed: $error\n$stack');
    }
  }
}

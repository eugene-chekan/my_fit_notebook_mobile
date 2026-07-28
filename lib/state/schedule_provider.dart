import 'package:flutter/foundation.dart';

import '../data/models/scheduled_workout.dart';
import '../data/repositories/schedule_repository.dart';
import '../services/reminder_service.dart';

/// Backs the Schedule screen: upcoming planned workouts, past-missed ones, and
/// add/remove/reschedule. Reminders are re-synced after every change.
class ScheduleProvider extends ChangeNotifier {
  ScheduleProvider({ScheduleRepository? repository})
    : _repository = repository ?? ScheduleRepository();

  final ScheduleRepository _repository;

  List<ScheduledWorkout> upcoming = [];
  List<ScheduledWorkout> missed = [];
  bool loading = true;

  static String _todayIso() {
    final now = DateTime.now();
    return ScheduleRepository.isoDate(DateTime(now.year, now.month, now.day));
  }

  Future<void> load() async {
    // Roll the recurring rules forward first so freshly-exposed occurrences
    // show up in the lists (and get reminders) as the horizon advances.
    await _repository.topUpOccurrences();
    final today = _todayIso();
    upcoming = await _repository.listUpcoming(today);
    missed = await _repository.listMissed(today);
    loading = false;
    notifyListeners();
  }

  /// Returns false if the routine is already booked that day. [time] (HH:mm)
  /// is optional and enables a reminder.
  Future<bool> add(int routineId, DateTime date, {String? time}) async {
    final ok = await _repository.addSchedule(
      routineId,
      ScheduleRepository.isoDate(date),
      time: time,
    );
    if (ok) {
      await load();
      await ReminderService.instance.resync();
    }
    return ok;
  }

  /// Books [dates] as one-off plans in a single pass. Dates already taken by
  /// this routine are skipped (the UNIQUE constraint); returns how many landed.
  Future<int> addMany(int routineId, List<DateTime> dates, {String? time}) async {
    var added = 0;
    for (final date in dates) {
      final ok = await _repository.addSchedule(
        routineId,
        ScheduleRepository.isoDate(date),
        time: time,
      );
      if (ok) added++;
    }
    if (added > 0) {
      await load();
      await ReminderService.instance.resync();
    }
    return added;
  }

  /// Adds a weekly repeating rule (fires on [weekdays], 1=Mon…7=Sun) and
  /// materialises its occurrences. [time] (HH:mm) is optional and enables
  /// reminders on every occurrence. [startFrom] anchors the first week.
  Future<void> addSeries(
    int routineId,
    Set<int> weekdays, {
    String? time,
    DateTime? startFrom,
  }) async {
    await _repository.addRule(routineId, weekdays, time: time, startFrom: startFrom);
    await load();
    await ReminderService.instance.resync();
  }

  Future<void> remove(int id) async {
    upcoming = upcoming.where((s) => s.id != id).toList();
    missed = missed.where((s) => s.id != id).toList();
    notifyListeners();
    await _repository.deleteSchedule(id);
    await load();
    await ReminderService.instance.resync();
  }

  /// Ends a whole repeating series from [fromDate] on (keeping its past),
  /// used when a recurring occurrence is dismissed with "delete the series".
  Future<void> removeSeriesFuture(int ruleId, String fromDate) async {
    await _repository.deleteSeriesFuture(ruleId, fromDate);
    await load();
    await ReminderService.instance.resync();
  }

  Future<bool> reschedule(int id, DateTime date) async {
    final ok = await _repository.reschedule(id, ScheduleRepository.isoDate(date));
    if (ok) {
      await load();
      await ReminderService.instance.resync();
    }
    return ok;
  }
}

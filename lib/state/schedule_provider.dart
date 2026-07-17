import 'package:flutter/foundation.dart';

import '../data/models/scheduled_workout.dart';
import '../data/repositories/schedule_repository.dart';

/// Backs the Schedule screen: upcoming planned workouts, past-missed ones, and
/// add/remove/reschedule.
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
    final today = _todayIso();
    upcoming = await _repository.listUpcoming(today);
    missed = await _repository.listMissed(today);
    loading = false;
    notifyListeners();
  }

  /// Returns false if the routine is already booked that day.
  Future<bool> add(int routineId, DateTime date) async {
    final ok = await _repository.addSchedule(
      routineId,
      ScheduleRepository.isoDate(date),
    );
    if (ok) await load();
    return ok;
  }

  Future<void> remove(int id) async {
    upcoming = upcoming.where((s) => s.id != id).toList();
    missed = missed.where((s) => s.id != id).toList();
    notifyListeners();
    await _repository.deleteSchedule(id);
    await load();
  }

  Future<bool> reschedule(int id, DateTime date) async {
    final ok = await _repository.reschedule(id, ScheduleRepository.isoDate(date));
    if (ok) await load();
    return ok;
  }
}

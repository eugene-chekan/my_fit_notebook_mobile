import 'package:flutter/foundation.dart';

import '../data/models/scheduled_workout.dart';
import '../data/repositories/completion_repository.dart';
import '../data/repositories/schedule_repository.dart';

/// Backs the dashboard page: workouts + total time this week (Monday-start,
/// matching the calendar), the current training streak, and the next planned
/// workout.
class DashboardProvider extends ChangeNotifier {
  DashboardProvider({
    CompletionRepository? repository,
    ScheduleRepository? scheduleRepository,
  }) : _repository = repository ?? CompletionRepository(),
       _schedules = scheduleRepository ?? ScheduleRepository();

  final CompletionRepository _repository;
  final ScheduleRepository _schedules;

  bool loading = true;
  int weekWorkouts = 0;
  int weekMinutes = 0;
  int streakDays = 0;

  /// The soonest planned workout on/after today, or null.
  ScheduledWorkout? nextScheduled;

  /// True when [nextScheduled] is for today (vs a later date).
  bool nextIsToday = false;

  Future<void> load() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final (count, minutes) = await _repository.totalsSince(_iso(monday));
    weekWorkouts = count;
    weekMinutes = minutes;
    final trained = (await _repository.distinctTrainedDates()).toSet();
    streakDays = _computeStreak(trained, today);
    final todayIso = _iso(today);
    nextScheduled = await _schedules.nextUpcoming(todayIso);
    nextIsToday = nextScheduled?.scheduledDate == todayIso;
    loading = false;
    notifyListeners();
  }

  /// Consecutive trained days ending today — or ending yesterday, so the
  /// streak isn't shown as broken before today's workout happens.
  static int _computeStreak(Set<String> trained, DateTime today) {
    var day = today;
    if (!trained.contains(_iso(day))) {
      day = day.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (trained.contains(_iso(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

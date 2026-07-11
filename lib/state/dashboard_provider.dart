import 'package:flutter/foundation.dart';

import '../data/repositories/completion_repository.dart';

/// Backs the dashboard page: workouts + total time this week (Monday-start,
/// matching the calendar), and the current training streak.
class DashboardProvider extends ChangeNotifier {
  DashboardProvider({CompletionRepository? repository})
    : _repository = repository ?? CompletionRepository();

  final CompletionRepository _repository;

  bool loading = true;
  int weekWorkouts = 0;
  int weekMinutes = 0;
  int streakDays = 0;

  Future<void> load() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final (count, minutes) = await _repository.totalsSince(_iso(monday));
    weekWorkouts = count;
    weekMinutes = minutes;
    final trained = (await _repository.distinctTrainedDates()).toSet();
    streakDays = _computeStreak(trained, today);
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

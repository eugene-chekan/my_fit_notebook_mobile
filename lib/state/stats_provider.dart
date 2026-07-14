import 'package:flutter/foundation.dart';

import '../data/models/profile.dart';
import '../data/repositories/completion_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../utils/stats_math.dart';

/// Backs the Stats screen: training-time aggregates from the completion log
/// and body-measurement trends from the profile. Read-only over existing
/// data — it never writes anything.
class StatsProvider extends ChangeNotifier {
  StatsProvider({
    CompletionRepository? completions,
    ProfileRepository? profiles,
  }) : _completions = completions ?? CompletionRepository(),
       _profiles = profiles ?? ProfileRepository();

  final CompletionRepository _completions;
  final ProfileRepository _profiles;

  bool loading = true;

  // --- Training time ---
  int monthWorkouts = 0;
  int monthMinutes = 0;
  int prevMonthWorkouts = 0;
  int prevMonthMinutes = 0;
  bool hasPrevMonthData = false;
  int allTimeWorkouts = 0;
  int allTimeMinutes = 0;
  double? avgMinutes;
  List<WeekBucket> weekBuckets = const [];

  bool get hasWorkouts => allTimeWorkouts > 0;

  // --- Body trends ---
  Profile? profile;
  Map<String, Measurement> latest = {};
  Map<String, double> targets = {};
  /// Per-metric dated history, oldest first (charting order).
  Map<String, List<Measurement>> series = {};
  double? bmiValue;

  String get units => profile?.units ?? Units.metric;

  Future<void> load() async {
    final all = await _completions.completionsSince('1970-01-01');
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);
    final prevMonthStart = DateTime(now.year, now.month - 1, 1);

    final thisMonth = periodTotals(all, monthStart, nextMonthStart);
    final prevMonth = periodTotals(all, prevMonthStart, monthStart);
    monthWorkouts = thisMonth.workouts;
    monthMinutes = thisMonth.minutes;
    prevMonthWorkouts = prevMonth.workouts;
    prevMonthMinutes = prevMonth.minutes;
    hasPrevMonthData = prevMonth.workouts > 0;
    allTimeWorkouts = all.length;
    allTimeMinutes = all.fold(0, (sum, c) => sum + (c.durationMinutes ?? 0));
    avgMinutes = averageMinutes(all);
    weekBuckets = weeklyMinutes(all, weeks: 10, today: now);

    profile = await _profiles.getProfile();
    latest = await _profiles.latestByMetric();
    targets = await _profiles.targets();
    final loaded = <String, List<Measurement>>{};
    for (final metric in kBodyMetrics) {
      final history = await _profiles.history(metric.key); // newest first
      loaded[metric.key] = history.reversed.toList(); // oldest first
    }
    series = loaded;
    bmiValue = bmi(latest['weight']?.value, profile?.heightCm);

    loading = false;
    notifyListeners();
  }
}

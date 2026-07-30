/// Pure aggregation helpers for the Stats screen. Kept free of Flutter and
/// sqflite so they're trivially unit-testable; the provider feeds them raw
/// [Completion] rows and formats the results.
library;

import '../data/models/completion.dart';
import '../data/models/profile.dart';

/// One Monday-anchored week's worth of training, oldest-to-newest in a series.
class WeekBucket {
  const WeekBucket({
    required this.weekStart,
    required this.workouts,
    required this.minutes,
  });

  /// The Monday that opens this week (date-only).
  final DateTime weekStart;
  final int workouts;
  final int minutes;
}

/// The last [weeks] Monday-anchored weeks ending with the week containing
/// [today], each carrying that week's workout count and total minutes.
/// Weeks with no training come back with zeroes so the bar chart keeps its
/// rhythm. Mirrors the dashboard's Monday week start.
List<WeekBucket> weeklyMinutes(
  List<Completion> completions, {
  int weeks = 10,
  DateTime? today,
}) {
  final anchor = _mondayOf(today ?? DateTime.now());
  // weekStart for bucket i, oldest first; the last is the current week.
  final starts = [
    for (var i = weeks - 1; i >= 0; i--) anchor.subtract(Duration(days: 7 * i)),
  ];
  final workouts = List<int>.filled(weeks, 0);
  final minutes = List<int>.filled(weeks, 0);
  final firstStart = starts.first;
  for (final c in completions) {
    final monday = _mondayOf(_parseDate(c.completedOn));
    final index = monday.difference(firstStart).inDays ~/ 7;
    if (index < 0 || index >= weeks) continue;
    workouts[index] += 1;
    minutes[index] += c.durationMinutes ?? 0;
  }
  return [
    for (var i = 0; i < weeks; i++)
      WeekBucket(weekStart: starts[i], workouts: workouts[i], minutes: minutes[i]),
  ];
}

/// (workouts, total minutes) for completions whose date falls in
/// [from, toExclusive). Used for this-month / last-month / all-time totals.
({int workouts, int minutes}) periodTotals(
  List<Completion> completions,
  DateTime from,
  DateTime toExclusive,
) {
  final fromDay = _dateOnly(from);
  final toDay = _dateOnly(toExclusive);
  var workouts = 0;
  var minutes = 0;
  for (final c in completions) {
    final day = _parseDate(c.completedOn);
    if (!day.isBefore(fromDay) && day.isBefore(toDay)) {
      workouts += 1;
      minutes += c.durationMinutes ?? 0;
    }
  }
  return (workouts: workouts, minutes: minutes);
}

/// Mean length of the completions that recorded a duration, rounded to a
/// whole minute; null when none carry a duration.
double? averageMinutes(List<Completion> completions) {
  final durations = [
    for (final c in completions)
      if (c.durationMinutes != null) c.durationMinutes!,
  ];
  if (durations.isEmpty) return null;
  return durations.reduce((a, b) => a + b) / durations.length;
}

/// The Monday (date-only) of the week containing [d].
DateTime _mondayOf(DateTime d) {
  final day = _dateOnly(d);
  return day.subtract(Duration(days: day.weekday - 1));
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Parses a `completed_on` value (yyyy-MM-dd or yyyy-MM-ddTHH:mm) to a
/// date-only [DateTime]; falls back to the epoch on malformed input so a
/// bad row can't crash the whole aggregation.
DateTime _parseDate(String iso) {
  try {
    return _dateOnly(DateTime.parse(iso));
  } catch (_) {
    return DateTime(1970);
  }
}

/// A rolling body-weight average over a fixed window of days.
class WeightAverage {
  const WeightAverage({
    required this.mean,
    required this.days,
    required this.window,
    this.previousMean,
  });

  /// Mean of the daily values, in the same unit as the input (canonical kg).
  final double mean;

  /// How many distinct days in the window actually carried a reading. Shown
  /// alongside the mean so a sparse week can't masquerade as a full one.
  final int days;

  /// The window's length in days, so the UI can say "5 of 7".
  final int window;

  /// The same average over the window immediately before this one, or null
  /// when there isn't enough history to compare against.
  final double? previousMean;

  /// Change against the previous window — the number that answers whether the
  /// weight is actually moving. Null when there's nothing to compare to.
  double? get delta => previousMean == null ? null : mean - previousMean!;
}

/// The mean body weight over the [window] days ending on [today], and the same
/// figure for the window before it.
///
/// Readings are averaged **per day** before being averaged together, so a day
/// you happened to step on the scale twice doesn't pull the mean toward itself.
/// The window is a fixed span of calendar days rather than "the last N
/// readings": a fixed span always describes the period it names, while the last
/// N readings silently reach further back the less often you weigh in.
///
/// Returns null below [minDays] readings — an "average" of a single weigh-in is
/// just that weigh-in with a longer label.
WeightAverage? weightAverage(
  List<Measurement> measurements, {
  int window = 7,
  int minDays = 2,
  DateTime? today,
}) {
  final end = today ?? DateTime.now();
  final endDay = DateTime(end.year, end.month, end.day);
  // Inclusive of today, so a 7-day window is today and the six days before it.
  final currentStart = DateTime(endDay.year, endDay.month, endDay.day - window + 1);
  final previousStart =
      DateTime(currentStart.year, currentStart.month, currentStart.day - window);

  final current = _dailyMeans(measurements, currentStart, endDay);
  if (current.length < minDays) return null;

  final previousEnd =
      DateTime(currentStart.year, currentStart.month, currentStart.day - 1);
  final previous = _dailyMeans(measurements, previousStart, previousEnd);

  return WeightAverage(
    mean: _mean(current.values),
    days: current.length,
    window: window,
    previousMean: previous.length < minDays ? null : _mean(previous.values),
  );
}

/// {date-only day: mean of that day's readings} within [from]..[to] inclusive.
Map<DateTime, double> _dailyMeans(
  List<Measurement> measurements,
  DateTime from,
  DateTime to,
) {
  final byDay = <DateTime, List<double>>{};
  for (final m in measurements) {
    final day = DateTime.tryParse(m.measuredOn);
    if (day == null) continue;
    final dateOnly = DateTime(day.year, day.month, day.day);
    if (dateOnly.isBefore(from) || dateOnly.isAfter(to)) continue;
    byDay.putIfAbsent(dateOnly, () => []).add(m.value);
  }
  return {for (final e in byDay.entries) e.key: _mean(e.value)};
}

double _mean(Iterable<double> values) =>
    values.reduce((a, b) => a + b) / values.length;

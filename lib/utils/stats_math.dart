/// Pure aggregation helpers for the Stats screen. Kept free of Flutter and
/// sqflite so they're trivially unit-testable; the provider feeds them raw
/// [Completion] rows and formats the results.
library;

import '../data/models/completion.dart';

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

/// Body-mass index from a weight (kg) and height (cm); null when either is
/// missing or non-positive.
double? bmi(double? weightKg, double? heightCm) {
  if (weightKg == null || heightCm == null || weightKg <= 0 || heightCm <= 0) {
    return null;
  }
  final heightM = heightCm / 100;
  return weightKg / (heightM * heightM);
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

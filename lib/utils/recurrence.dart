/// Pure weekly-recurrence date math, kept free of Flutter so it's unit-testable.
///
/// The app's only recurrence kind is "weekly on one or more weekdays" (the
/// canonical training pattern — e.g. every Mon/Wed/Fri). A rule materialises
/// into concrete `scheduled_workouts` rows over a rolling horizon; this helper
/// is the generator those rows come from.
library;

/// Every date in [from]..[to] (both inclusive, date-only) whose ISO weekday
/// (1 = Mon … 7 = Sun) is listed in [weekdays]. Returns an empty list when
/// [weekdays] is empty or the range is inverted.
List<DateTime> weeklyOccurrences({
  required Set<int> weekdays,
  required DateTime from,
  required DateTime to,
}) {
  final result = <DateTime>[];
  if (weekdays.isEmpty) return result;
  var day = DateTime(from.year, from.month, from.day);
  final end = DateTime(to.year, to.month, to.day);
  while (!day.isAfter(end)) {
    if (weekdays.contains(day.weekday)) result.add(day);
    // Step by calendar day, not by 24 hours: across a DST boundary adding a
    // fixed Duration lands on 23:00 the same day (or 01:00 the next), which
    // would repeat or skip a date and shift every weekday after it.
    day = DateTime(day.year, day.month, day.day + 1);
  }
  return result;
}

/// Midnight on the Monday of the week containing [date] (ISO weeks, matching
/// the 1 = Mon … 7 = Sun weekday numbering used throughout).
DateTime startOfWeek(DateTime date) =>
    DateTime(date.year, date.month, date.day - (date.weekday - 1));

/// The dates in [anchor]'s own week that fall on [weekdays].
///
/// This is the "once" half of the scheduling model: the chosen weekdays are
/// booked in a single week rather than repeating. Dates before [notBefore]
/// (typically today) are dropped — a day that has already passed can't be
/// planned.
List<DateTime> weekOccurrences({
  required DateTime anchor,
  required Set<int> weekdays,
  DateTime? notBefore,
}) {
  final start = startOfWeek(anchor);
  final dates = weeklyOccurrences(
    weekdays: weekdays,
    from: start,
    to: DateTime(start.year, start.month, start.day + 6),
  );
  if (notBefore == null) return dates;
  final floor = DateTime(notBefore.year, notBefore.month, notBefore.day);
  return dates.where((d) => !d.isBefore(floor)).toList();
}

/// Parse a stored weekday CSV ("1,3,5") into a set of ISO weekday ints,
/// silently dropping anything out of the 1..7 range or unparseable.
Set<int> parseWeekdays(String csv) {
  final result = <int>{};
  for (final part in csv.split(',')) {
    final n = int.tryParse(part.trim());
    if (n != null && n >= 1 && n <= 7) result.add(n);
  }
  return result;
}

/// Serialise a weekday set to the stored CSV form ("1,3,5"), always ascending
/// so the string is stable regardless of insertion order.
String encodeWeekdays(Set<int> weekdays) {
  final sorted = weekdays.where((d) => d >= 1 && d <= 7).toList()..sort();
  return sorted.join(',');
}

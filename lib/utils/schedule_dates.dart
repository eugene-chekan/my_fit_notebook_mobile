/// Pure helpers for labelling/grouping scheduled dates, kept free of Flutter so
/// they're unit-testable.
library;

/// How far off a scheduled date is relative to today.
enum ScheduleDayKind { today, tomorrow, later }

/// Classifies an `iso` (yyyy-MM-dd) date against [today] (any time-of-day).
/// Past dates fold into [ScheduleDayKind.today] — callers list past plans
/// separately as "missed".
ScheduleDayKind scheduleDayKind(String iso, DateTime today) {
  final base = DateTime(today.year, today.month, today.day);
  DateTime date;
  try {
    final d = DateTime.parse(iso);
    date = DateTime(d.year, d.month, d.day);
  } catch (_) {
    return ScheduleDayKind.later;
  }
  final diff = date.difference(base).inDays;
  if (diff <= 0) return ScheduleDayKind.today;
  if (diff == 1) return ScheduleDayKind.tomorrow;
  return ScheduleDayKind.later;
}

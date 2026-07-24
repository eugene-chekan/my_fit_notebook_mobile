import '../../utils/recurrence.dart';

/// A repeating-workout rule. The app's only recurrence is "weekly on one or
/// more weekdays" — the concrete [ScheduledWorkout] occurrences are generated
/// from it over a rolling horizon. [routineName] is joined for display.
class ScheduleRule {
  const ScheduleRule({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.weekdays,
    this.scheduledTime,
    required this.startDate,
    this.generatedThrough,
    this.active = true,
  });

  final int id;
  final int routineId;
  final String routineName;

  /// ISO weekday ints (1 = Mon … 7 = Sun) this rule fires on.
  final Set<int> weekdays;

  /// HH:mm, or null for time-less occurrences (no reminder).
  final String? scheduledTime;

  /// yyyy-MM-dd anchor — occurrences never predate this.
  final String startDate;

  /// yyyy-MM-dd watermark: occurrences have been materialised up to and
  /// including this date. Null until the first top-up runs.
  final String? generatedThrough;

  final bool active;

  factory ScheduleRule.fromMap(Map<String, Object?> map) => ScheduleRule(
    id: map['id'] as int,
    routineId: map['routine_id'] as int,
    routineName: (map['routine_name'] as String?) ?? '',
    weekdays: parseWeekdays((map['weekdays'] as String?) ?? ''),
    scheduledTime: map['scheduled_time'] as String?,
    startDate: map['start_date'] as String,
    generatedThrough: map['generated_through'] as String?,
    active: ((map['active'] as int?) ?? 1) != 0,
  );
}

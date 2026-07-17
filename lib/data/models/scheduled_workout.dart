/// A planned workout: a routine pencilled in for a specific (usually future)
/// date. The future-facing mirror of a [Completion]. [routineName] is joined
/// from the routines table for display.
class ScheduledWorkout {
  const ScheduledWorkout({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.scheduledDate,
    this.scheduledTime,
    this.status = ScheduleStatus.planned,
    this.completionId,
  });

  final int id;
  final int routineId;
  final String routineName;

  /// yyyy-MM-dd.
  final String scheduledDate;

  /// HH:mm, or null for a date-only plan (no reminder).
  final String? scheduledTime;
  final String status;

  /// The completion that fulfilled this plan, once done.
  final int? completionId;

  factory ScheduledWorkout.fromMap(Map<String, Object?> map) => ScheduledWorkout(
    id: map['id'] as int,
    routineId: map['routine_id'] as int,
    routineName: (map['routine_name'] as String?) ?? '',
    scheduledDate: map['scheduled_date'] as String,
    scheduledTime: map['scheduled_time'] as String?,
    status: (map['status'] as String?) ?? ScheduleStatus.planned,
    completionId: map['completion_id'] as int?,
  );
}

/// Lifecycle of a [ScheduledWorkout]. A past `planned` entry (never fulfilled)
/// is treated as "missed" by the UI without a separate stored state.
class ScheduleStatus {
  static const planned = 'planned';
  static const done = 'done';
  static const skipped = 'skipped';
}

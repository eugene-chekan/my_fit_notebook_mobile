/// Mirrors the `Completion` dataclass in the Flask app's models.py.
class Completion {
  const Completion({
    required this.id,
    required this.routineId,
    required this.completedOn,
    this.durationMinutes,
    this.startedAt,
    this.pausedSeconds,
    this.exercisesCompleted,
    this.setsCompleted,
    this.repsTotal,
  });

  final int id;
  final int routineId;
  final String completedOn;
  final int? durationMinutes;
  final String? startedAt;
  final int? pausedSeconds;

  /// Per-session totals snapshotted at finish (DB v8). Null for sessions logged
  /// before v8 — the UI then shows only date + duration.
  final int? exercisesCompleted;
  final int? setsCompleted;
  final int? repsTotal;

  factory Completion.fromMap(Map<String, Object?> map) {
    return Completion(
      id: map['id'] as int,
      routineId: map['routine_id'] as int,
      completedOn: map['completed_on'] as String,
      durationMinutes: map['duration_minutes'] as int?,
      startedAt: map['started_at'] as String?,
      pausedSeconds: map['paused_seconds'] as int?,
      exercisesCompleted: map['exercises_completed'] as int?,
      setsCompleted: map['sets_completed'] as int?,
      repsTotal: map['reps_total'] as int?,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'routine_id': routineId,
    'completed_on': completedOn,
    'duration_minutes': durationMinutes,
    'started_at': startedAt,
    'paused_seconds': pausedSeconds,
    'exercises_completed': exercisesCompleted,
    'sets_completed': setsCompleted,
    'reps_total': repsTotal,
  };
}

/// Mirrors the `WorkoutStatistics` dataclass in the Flask app's models.py,
/// plus per-set totals ([setsCompleted]/[repsTotal]) captured at finish time.
class WorkoutStatistics {
  const WorkoutStatistics({
    required this.exercisesCompleted,
    required this.durationSeconds,
    required this.pausedSeconds,
    this.setsCompleted = 0,
    this.repsTotal = 0,
  });

  final int exercisesCompleted;
  final int durationSeconds;
  final int pausedSeconds;
  final int setsCompleted;
  final int repsTotal;
}

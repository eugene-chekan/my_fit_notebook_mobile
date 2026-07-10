/// Mirrors the `Completion` dataclass in the Flask app's models.py.
class Completion {
  const Completion({
    required this.id,
    required this.routineId,
    required this.completedOn,
    this.durationMinutes,
    this.startedAt,
    this.pausedSeconds,
  });

  final int id;
  final int routineId;
  final String completedOn;
  final int? durationMinutes;
  final String? startedAt;
  final int? pausedSeconds;

  factory Completion.fromMap(Map<String, Object?> map) {
    return Completion(
      id: map['id'] as int,
      routineId: map['routine_id'] as int,
      completedOn: map['completed_on'] as String,
      durationMinutes: map['duration_minutes'] as int?,
      startedAt: map['started_at'] as String?,
      pausedSeconds: map['paused_seconds'] as int?,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'routine_id': routineId,
    'completed_on': completedOn,
    'duration_minutes': durationMinutes,
    'started_at': startedAt,
    'paused_seconds': pausedSeconds,
  };
}

/// Mirrors the `WorkoutStatistics` dataclass in the Flask app's models.py.
class WorkoutStatistics {
  const WorkoutStatistics({
    required this.exercisesCompleted,
    required this.durationSeconds,
    required this.pausedSeconds,
  });

  final int exercisesCompleted;
  final int durationSeconds;
  final int pausedSeconds;
}

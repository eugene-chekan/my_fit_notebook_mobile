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

/// A workout that has logged sessions, summarized for the Training log's
/// index. Built by a GROUP BY over `completions`, so a workout with no
/// sessions never produces one.
class LoggedRoutine {
  const LoggedRoutine({
    required this.routineId,
    required this.name,
    required this.sessionCount,
    required this.lastCompletedOn,
  });

  final int routineId;
  final String name;
  final int sessionCount;

  /// The newest session's `completed_on` — either `yyyy-MM-dd` or
  /// `yyyy-MM-ddTHH:mm`, matching how completions are stored.
  final String lastCompletedOn;

  factory LoggedRoutine.fromMap(Map<String, Object?> map) {
    return LoggedRoutine(
      routineId: map['id'] as int,
      name: map['name'] as String,
      sessionCount: map['session_count'] as int,
      lastCompletedOn: map['last_completed_on'] as String,
    );
  }
}

/// One set snapshotted into `completion_sets` when a session finished — the
/// exercise it belonged to and the reps actually logged. Denormalized, so it
/// survives later edits/deletes of the routine's exercises.
class CompletionSet {
  const CompletionSet({
    required this.exerciseName,
    this.catalogId,
    required this.setIndex,
    this.reps,
    this.weightKg,
    required this.unit,
  });

  final String exerciseName;
  final int? catalogId;
  final int setIndex;
  final int? reps;

  /// The load carried, in kilograms, or null for a bodyweight set.
  final double? weightKg;
  final String unit;

  factory CompletionSet.fromMap(Map<String, Object?> map) {
    return CompletionSet(
      exerciseName: map['exercise_name'] as String,
      catalogId: map['catalog_id'] as int?,
      setIndex: map['set_index'] as int,
      reps: map['reps'] as int?,
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      unit: (map['unit'] as String?) ?? 'reps',
    );
  }
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

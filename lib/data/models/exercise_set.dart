/// One set of a prescribed exercise during a workout: its position, the
/// actual reps performed (prefilled from the prescription, editable), and
/// whether it's been checked off. Lives in the `exercise_sets` table.
class ExerciseSet {
  const ExerciseSet({
    required this.id,
    required this.exerciseId,
    required this.setIndex,
    this.actualReps,
    this.weightKg,
    this.isDone = false,
  });

  final int id;
  final int exerciseId;
  /// 1-based position within the exercise.
  final int setIndex;
  final int? actualReps;

  /// The load carried for this set, in kilograms, or null for a bodyweight
  /// set. Canonical metric; pounds are a display choice made at render time.
  final double? weightKg;
  final bool isDone;

  factory ExerciseSet.fromMap(Map<String, Object?> map) {
    return ExerciseSet(
      id: map['id'] as int,
      exerciseId: map['exercise_id'] as int,
      setIndex: map['set_index'] as int,
      actualReps: map['actual_reps'] as int?,
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      isDone: (map['is_done'] as int) != 0,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'exercise_id': exerciseId,
    'set_index': setIndex,
    'actual_reps': actualReps,
    'weight_kg': weightKg,
    'is_done': isDone ? 1 : 0,
  };
}

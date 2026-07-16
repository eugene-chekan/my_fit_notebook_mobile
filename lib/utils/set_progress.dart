/// Pure helpers for per-set tracking, kept free of Flutter/sqflite so they're
/// unit-testable and shared between the repository, provider, and UI.
library;

import '../data/models/exercise.dart';
import '../data/models/exercise_set.dart';

/// The reps a set is prefilled with from its prescription: the top of a range
/// (`repsMax`) when present, otherwise the single value (`repsMin`); null when
/// no reps are prescribed.
int? prefillReps(int? repsMin, int? repsMax) => repsMax ?? repsMin;

/// (done, total) across a set list.
({int done, int total}) setProgress(List<ExerciseSet> sets) {
  final done = sets.where((s) => s.isDone).length;
  return (done: done, total: sets.length);
}

/// True only when there is at least one set and every set is done — the signal
/// that the whole exercise is complete.
bool allSetsDone(List<ExerciseSet> sets) =>
    sets.isNotEmpty && sets.every((s) => s.isDone);

/// (done, total) across a routine's exercises for the live workout readout: a
/// prescribed exercise (it has seeded sets) is done when every set is done; a
/// bare exercise is done by its own checkbox.
({int done, int total}) exerciseCompletion(
  List<Exercise> exercises,
  Map<int, List<ExerciseSet>> setsByExercise,
) {
  var done = 0;
  for (final e in exercises) {
    final sets = setsByExercise[e.id] ?? const <ExerciseSet>[];
    final complete = sets.isNotEmpty ? allSetsDone(sets) : e.isDone;
    if (complete) done++;
  }
  return (done: done, total: exercises.length);
}

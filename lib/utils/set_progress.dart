/// Pure helpers for per-set tracking, kept free of Flutter/sqflite so they're
/// unit-testable and shared between the repository, provider, and UI.
library;

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

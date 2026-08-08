import 'package:sqflite/sqflite.dart';

import '../../utils/set_progress.dart';
import '../db/app_database.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';
import '../models/rep_unit.dart';
import 'exercise_catalog_repository.dart';

const _exerciseColumns =
    'id, routine_id, name, sort_order, is_done, catalog_id, sets, reps_min, reps_max, unit';

/// SQL access for exercises — a Dart port of repositories/exercises.py.
class ExerciseRepository {
  ExerciseRepository({ExerciseCatalogRepository? catalog})
    : _catalog = catalog ?? ExerciseCatalogRepository();

  final ExerciseCatalogRepository _catalog;

  Future<Database> get _db => AppDatabase.instance.database;

  Future<List<Exercise>> listExercises(int routineId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT $_exerciseColumns FROM exercises WHERE routine_id = ? '
      'ORDER BY sort_order ASC, id ASC',
      [routineId],
    );
    return rows.map(Exercise.fromMap).toList();
  }

  /// Adds an exercise to a routine with an optional per-routine prescription.
  /// A brand-new catalog entry is seeded with this prescription as its
  /// defaults; an existing entry keeps its own defaults.
  Future<void> addExercise(
    int routineId,
    String name, {
    int? sets,
    int? repsMin,
    int? repsMax,
    String unit = RepUnit.reps,
    String? description,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final entry = await _catalog.ensure(
      trimmed,
      defaultSets: sets,
      defaultReps: repsMin,
      defaultRepsMax: repsMax,
      defaultUnit: unit,
    );
    final db = await _db;
    final maxOrderRows = await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next_order FROM exercises WHERE routine_id = ?',
      [routineId],
    );
    final nextOrder = maxOrderRows.first['next_order'] as int;
    final exerciseId = await db.insert('exercises', {
      'routine_id': routineId,
      'name': entry.name, // canonical casing from the catalog
      'sort_order': nextOrder,
      'is_done': 0,
      'catalog_id': entry.id,
      'sets': sets,
      'reps_min': repsMin,
      'reps_max': repsMax,
      'unit': unit,
    });
    await _seedSets(db, exerciseId, sets, repsMin, repsMax);
  }

  /// Adds an exercise to a freestyle session, mid-workout.
  ///
  /// Differs from [addExercise] in two ways that matter, both of them about
  /// what survives the session:
  ///
  /// * The catalog is **looked up, never written**. A name that already exists
  ///   links to its entry (and inherits nothing else); a name that does not is
  ///   inserted with a null `catalog_id` and is never registered. That is what
  ///   makes a typed-once exercise leave no trace in the library — the row
  ///   itself is wiped when the session ends, so the log is all that remains.
  /// * At least one set is always seeded. [snapshotDoneSets] only carries
  ///   exercises that *have* sets into `completion_sets`; a bare checkbox
  ///   contributes to the session's exercise count and nothing else, so its
  ///   name would be lost the moment the row is wiped.
  Future<void> addAdhocExercise(
    int routineId,
    String name, {
    int? sets,
    int? repsMin,
    int? repsMax,
    String unit = RepUnit.reps,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final known = await _catalog.findByName(trimmed);
    final seededSets = (sets == null || sets <= 0) ? 1 : sets;
    final db = await _db;
    final maxOrderRows = await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next_order '
      'FROM exercises WHERE routine_id = ?',
      [routineId],
    );
    final exerciseId = await db.insert('exercises', {
      'routine_id': routineId,
      // Canonical casing when the library knows it, otherwise as typed.
      'name': known?.name ?? trimmed,
      'sort_order': maxOrderRows.first['next_order'] as int,
      'is_done': 0,
      'catalog_id': known?.id,
      'sets': seededSets,
      'reps_min': repsMin,
      'reps_max': repsMax,
      'unit': unit,
    });
    await _seedSets(db, exerciseId, seededSets, repsMin, repsMax);
  }

  /// Removes every exercise from a routine (its sets cascade). Used to blank
  /// the freestyle sheet between sessions — the record is in the log by then.
  Future<void> clearExercises(int routineId) async {
    final db = await _db;
    await db.delete('exercises', where: 'routine_id = ?', whereArgs: [routineId]);
  }

  /// Seeds one `exercise_sets` row per prescribed set (1-based), reps
  /// prefilled from the prescription, all unchecked. No-op when [sets] is
  /// null or non-positive (a bare exercise keeps its single checkbox).
  Future<void> _seedSets(
    Database db,
    int exerciseId,
    int? sets,
    int? repsMin,
    int? repsMax,
  ) async {
    if (sets == null || sets <= 0) return;
    final prefill = prefillReps(repsMin, repsMax);
    final batch = db.batch();
    for (var i = 1; i <= sets; i++) {
      batch.insert('exercise_sets', {
        'exercise_id': exerciseId,
        'set_index': i,
        'actual_reps': prefill,
        'is_done': 0,
      });
    }
    await batch.commit(noResult: true);
  }

  /// Updates the per-routine sets/reps/unit prescription for one exercise.
  Future<void> updatePrescription(
    int exerciseId,
    int routineId, {
    int? sets,
    int? repsMin,
    int? repsMax,
    String unit = RepUnit.reps,
  }) async {
    final db = await _db;
    await db.update(
      'exercises',
      {'sets': sets, 'reps_min': repsMin, 'reps_max': repsMax, 'unit': unit},
      where: 'id = ? AND routine_id = ?',
      whereArgs: [exerciseId, routineId],
    );
    // A prescription change is a plan change: rebuild the set rows to match
    // the new count (and clear any logged progress). Also refreshes the
    // parent done flag, since the set list changed.
    await db.delete('exercise_sets', where: 'exercise_id = ?', whereArgs: [exerciseId]);
    await _seedSets(db, exerciseId, sets, repsMin, repsMax);
    await _recomputeExerciseDone(db, exerciseId);
  }

  Future<void> updateName(int exerciseId, int routineId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final entry = await _catalog.ensure(trimmed);
    final db = await _db;
    await db.update(
      'exercises',
      {'name': entry.name, 'catalog_id': entry.id},
      where: 'id = ? AND routine_id = ?',
      whereArgs: [exerciseId, routineId],
    );
  }

  /// Copies one exercise (name + " (copy)", unchecked) to the end of its
  /// routine's list. Reuses the source's catalog link and does not register
  /// the "(copy)" string in the catalog, so suggestions stay clean.
  Future<void> duplicateExercise(int exerciseId, int routineId) async {
    final db = await _db;
    final rows = await db.query(
      'exercises',
      columns: ['name', 'catalog_id', 'sets', 'reps_min', 'reps_max', 'unit'],
      where: 'id = ? AND routine_id = ?',
      whereArgs: [exerciseId, routineId],
    );
    if (rows.isEmpty) return;
    final maxOrderRows = await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next_order FROM exercises WHERE routine_id = ?',
      [routineId],
    );
    final sets = rows.first['sets'] as int?;
    final repsMin = rows.first['reps_min'] as int?;
    final repsMax = rows.first['reps_max'] as int?;
    final newId = await db.insert('exercises', {
      'routine_id': routineId,
      'name': '${rows.first['name'] as String} (copy)',
      'sets': sets,
      'reps_min': repsMin,
      'reps_max': repsMax,
      'unit': rows.first['unit'] as String? ?? RepUnit.reps,
      'sort_order': maxOrderRows.first['next_order'] as int,
      'is_done': 0,
      'catalog_id': rows.first['catalog_id'] as int?,
    });
    await _seedSets(db, newId, sets, repsMin, repsMax);
  }

  Future<void> deleteExercise(int exerciseId, int routineId) async {
    final db = await _db;
    await db.delete(
      'exercises',
      where: 'id = ? AND routine_id = ?',
      whereArgs: [exerciseId, routineId],
    );
  }

  /// True if the routine has at least one exercise and all are done.
  Future<bool> allExercisesDone(int routineId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS total, SUM(is_done) AS done FROM exercises WHERE routine_id = ?',
      [routineId],
    );
    final total = rows.first['total'] as int;
    final done = (rows.first['done'] as int?) ?? 0;
    return total > 0 && total == done;
  }

  Future<void> resetExercises(int routineId) async {
    final db = await _db;
    await db.update(
      'exercises',
      {'is_done': 0},
      where: 'routine_id = ?',
      whereArgs: [routineId],
    );
    // Clear per-set progress too, and re-prefill reps to the prescription so
    // each session starts clean.
    await db.rawUpdate(
      'UPDATE exercise_sets SET is_done = 0, '
      'actual_reps = (SELECT COALESCE(e.reps_max, e.reps_min) FROM exercises e '
      '               WHERE e.id = exercise_sets.exercise_id) '
      'WHERE exercise_id IN (SELECT id FROM exercises WHERE routine_id = ?)',
      [routineId],
    );
  }

  Future<void> toggleDone(int exerciseId, int routineId) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE exercises SET is_done = CASE is_done WHEN 0 THEN 1 ELSE 0 END '
      'WHERE id = ? AND routine_id = ?',
      [exerciseId, routineId],
    );
  }

  Future<void> reorderExercises(int routineId, List<int> orderedIds) async {
    if (orderedIds.isEmpty) return;
    final db = await _db;
    final batch = db.batch();
    for (var i = 0; i < orderedIds.length; i++) {
      batch.update(
        'exercises',
        {'sort_order': i},
        where: 'id = ? AND routine_id = ?',
        whereArgs: [orderedIds[i], routineId],
      );
    }
    await batch.commit(noResult: true);
  }

  // --- Per-set tracking -------------------------------------------------

  /// Every routine's set rows, keyed by exercise id and ordered by set index.
  Future<Map<int, List<ExerciseSet>>> listSetsForRoutine(int routineId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT s.id, s.exercise_id, s.set_index, s.actual_reps, s.weight_kg, s.is_done '
      'FROM exercise_sets s JOIN exercises e ON s.exercise_id = e.id '
      'WHERE e.routine_id = ? ORDER BY s.exercise_id ASC, s.set_index ASC',
      [routineId],
    );
    final result = <int, List<ExerciseSet>>{};
    for (final row in rows) {
      final set = ExerciseSet.fromMap(row);
      result.putIfAbsent(set.exerciseId, () => []).add(set);
    }
    return result;
  }

  /// Flips one set's done flag, then refreshes the parent exercise's done flag.
  Future<void> toggleSet(int setId, int exerciseId) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE exercise_sets SET is_done = CASE is_done WHEN 0 THEN 1 ELSE 0 END '
      'WHERE id = ?',
      [setId],
    );
    await _recomputeExerciseDone(db, exerciseId);
  }

  /// Sets/clears every set of an exercise, then refreshes its done flag.
  Future<void> markAllSets(int exerciseId, bool done) async {
    final db = await _db;
    await db.update(
      'exercise_sets',
      {'is_done': done ? 1 : 0},
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
    );
    await _recomputeExerciseDone(db, exerciseId);
  }

  /// Records what was actually lifted for a set: the reps, and optionally the
  /// load in kilograms. Both are nullable — null reps means unlogged, and null
  /// weight means bodyweight — so each is written on every call rather than
  /// merged, letting the caller clear either one.
  Future<void> setSetLog(int setId, int? reps, {double? weightKg}) async {
    final db = await _db;
    await db.update(
      'exercise_sets',
      {'actual_reps': reps, 'weight_kg': weightKg},
      where: 'id = ?',
      whereArgs: [setId],
    );
  }

  /// Snapshots the done sets of a finished routine into `completion_sets`,
  /// carrying the exercise name/catalog link and unit so the history stays
  /// readable if the exercise is later edited or deleted.
  Future<void> snapshotDoneSets(int routineId, int completionId) async {
    final db = await _db;
    await db.rawInsert(
      'INSERT INTO completion_sets '
      '(completion_id, exercise_name, catalog_id, set_index, reps, weight_kg, unit) '
      'SELECT ?, e.name, e.catalog_id, s.set_index, s.actual_reps, s.weight_kg, e.unit '
      'FROM exercise_sets s JOIN exercises e ON s.exercise_id = e.id '
      'WHERE e.routine_id = ? AND s.is_done = 1 '
      'ORDER BY e.sort_order, s.set_index',
      [completionId, routineId],
    );
  }

  /// (done set count, total reps across done sets) for a routine — feeds the
  /// finish summary.
  Future<(int, int)> doneSetStats(int routineId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS sets, COALESCE(SUM(s.actual_reps), 0) AS reps '
      'FROM exercise_sets s JOIN exercises e ON s.exercise_id = e.id '
      'WHERE e.routine_id = ? AND s.is_done = 1',
      [routineId],
    );
    return (rows.first['sets'] as int, rows.first['reps'] as int);
  }

  /// Derives the parent exercise's `is_done` from its set rows: done only when
  /// it has sets and all of them are checked.
  Future<void> _recomputeExerciseDone(Database db, int exerciseId) async {
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS total, SUM(is_done) AS done FROM exercise_sets '
      'WHERE exercise_id = ?',
      [exerciseId],
    );
    final total = rows.first['total'] as int;
    final done = (rows.first['done'] as int?) ?? 0;
    final allDone = total > 0 && total == done;
    await db.update(
      'exercises',
      {'is_done': allDone ? 1 : 0},
      where: 'id = ?',
      whereArgs: [exerciseId],
    );
  }
}

import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/exercise.dart';
import 'exercise_catalog_repository.dart';

const _exerciseColumns =
    'id, routine_id, name, sort_order, is_done, catalog_id, sets, reps_min, reps_max';

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
    String? description,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final entry = await _catalog.ensure(
      trimmed,
      defaultSets: sets,
      defaultReps: repsMin,
      defaultRepsMax: repsMax,
    );
    final db = await _db;
    final maxOrderRows = await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next_order FROM exercises WHERE routine_id = ?',
      [routineId],
    );
    final nextOrder = maxOrderRows.first['next_order'] as int;
    await db.insert('exercises', {
      'routine_id': routineId,
      'name': entry.name, // canonical casing from the catalog
      'sort_order': nextOrder,
      'is_done': 0,
      'catalog_id': entry.id,
      'sets': sets,
      'reps_min': repsMin,
      'reps_max': repsMax,
    });
  }

  /// Updates the per-routine sets/reps prescription for one exercise.
  Future<void> updatePrescription(
    int exerciseId,
    int routineId, {
    int? sets,
    int? repsMin,
    int? repsMax,
  }) async {
    final db = await _db;
    await db.update(
      'exercises',
      {'sets': sets, 'reps_min': repsMin, 'reps_max': repsMax},
      where: 'id = ? AND routine_id = ?',
      whereArgs: [exerciseId, routineId],
    );
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
      columns: ['name', 'catalog_id', 'sets', 'reps_min', 'reps_max'],
      where: 'id = ? AND routine_id = ?',
      whereArgs: [exerciseId, routineId],
    );
    if (rows.isEmpty) return;
    final maxOrderRows = await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next_order FROM exercises WHERE routine_id = ?',
      [routineId],
    );
    await db.insert('exercises', {
      'routine_id': routineId,
      'name': '${rows.first['name'] as String} (copy)',
      'sets': rows.first['sets'] as int?,
      'reps_min': rows.first['reps_min'] as int?,
      'reps_max': rows.first['reps_max'] as int?,
      'sort_order': maxOrderRows.first['next_order'] as int,
      'is_done': 0,
      'catalog_id': rows.first['catalog_id'] as int?,
    });
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
}

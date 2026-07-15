import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/routine.dart';

const _routineColumns =
    'id, name, sort_order, created_at, description, started_at, paused_at, paused_seconds';

/// SQL access for routines — a Dart port of repositories/routines.py.
class RoutineRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  Future<List<Routine>> listRoutines() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT $_routineColumns FROM routines ORDER BY sort_order ASC, id ASC',
    );
    return rows.map(Routine.fromMap).toList();
  }

  Future<Routine?> getRoutine(int routineId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT $_routineColumns FROM routines WHERE id = ?',
      [routineId],
    );
    if (rows.isEmpty) return null;
    return Routine.fromMap(rows.first);
  }

  Future<int> addRoutine(String name) async {
    final db = await _db;
    final maxOrderRows = await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next_order FROM routines',
    );
    final nextOrder = maxOrderRows.first['next_order'] as int;
    final now = DateTime.now().toIso8601String().substring(0, 19);
    return db.insert('routines', {
      'name': name.trim(),
      'sort_order': nextOrder,
      'created_at': now,
    });
  }

  Future<void> updateDetails(int routineId, String name, String description) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final db = await _db;
    await db.update(
      'routines',
      {'name': trimmed, 'description': description.trim()},
      where: 'id = ?',
      whereArgs: [routineId],
    );
  }

  Future<void> deleteRoutine(int routineId) async {
    final db = await _db;
    await db.delete('routines', where: 'id = ?', whereArgs: [routineId]);
  }

  /// Copies a routine (name + " (copy)", description, exercises with their
  /// order, checkmarks cleared) to the end of the list. Session history is
  /// deliberately not copied — it belongs to the original.
  Future<void> duplicateRoutine(int routineId) async {
    final db = await _db;
    await db.transaction((txn) async {
      final rows = await txn.rawQuery(
        'SELECT $_routineColumns FROM routines WHERE id = ?',
        [routineId],
      );
      if (rows.isEmpty) return;
      final src = Routine.fromMap(rows.first);
      final orderRows = await txn.rawQuery(
        'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next_order FROM routines',
      );
      final now = DateTime.now().toIso8601String().substring(0, 19);
      final newId = await txn.insert('routines', {
        'name': '${src.name} (copy)',
        'sort_order': orderRows.first['next_order'] as int,
        'created_at': now,
        'description': src.description,
      });
      final exercises = await txn.rawQuery(
        'SELECT name, sort_order, catalog_id, sets, reps_min, reps_max, unit '
        'FROM exercises WHERE routine_id = ? ORDER BY sort_order ASC, id ASC',
        [routineId],
      );
      for (final ex in exercises) {
        final newExerciseId = await txn.insert('exercises', {
          'routine_id': newId,
          'name': ex['name'],
          'sort_order': ex['sort_order'],
          'is_done': 0,
          'catalog_id': ex['catalog_id'],
          'sets': ex['sets'],
          'reps_min': ex['reps_min'],
          'reps_max': ex['reps_max'],
          'unit': ex['unit'] ?? 'reps',
        });
        // Seed fresh, unchecked set rows for a copied prescribed exercise.
        final sets = ex['sets'] as int?;
        if (sets != null && sets > 0) {
          final prefill = (ex['reps_max'] as int?) ?? (ex['reps_min'] as int?);
          for (var i = 1; i <= sets; i++) {
            await txn.insert('exercise_sets', {
              'exercise_id': newExerciseId,
              'set_index': i,
              'actual_reps': prefill,
              'is_done': 0,
            });
          }
        }
      }
    });
  }

  Future<void> setStartedAt(int routineId, DateTime startedAt) async {
    final db = await _db;
    await db.update(
      'routines',
      {
        'started_at': startedAt.toIso8601String().substring(0, 19),
        'paused_at': null,
        'paused_seconds': 0,
      },
      where: 'id = ?',
      whereArgs: [routineId],
    );
  }

  Future<void> clearStartedAt(int routineId) async {
    final db = await _db;
    await db.update(
      'routines',
      {'started_at': null, 'paused_at': null, 'paused_seconds': 0},
      where: 'id = ?',
      whereArgs: [routineId],
    );
  }

  /// Records the moment a workout was paused (only if not already paused).
  Future<void> pauseRoutine(int routineId) async {
    final db = await _db;
    await db.update(
      'routines',
      {'paused_at': DateTime.now().toIso8601String().substring(0, 19)},
      where: 'id = ? AND paused_at IS NULL AND started_at IS NOT NULL',
      whereArgs: [routineId],
    );
  }

  /// Accumulates paused seconds and clears paused_at.
  Future<void> resumeRoutine(int routineId) async {
    final db = await _db;
    final rows = await db.query(
      'routines',
      columns: ['paused_at', 'paused_seconds'],
      where: 'id = ?',
      whereArgs: [routineId],
    );
    if (rows.isEmpty) return;
    final pausedAt = rows.first['paused_at'] as String?;
    if (pausedAt == null) return;
    final pausedSeconds = rows.first['paused_seconds'] as int;
    int elapsed;
    try {
      elapsed = DateTime.now().difference(DateTime.parse(pausedAt)).inSeconds;
    } catch (_) {
      elapsed = 0;
    }
    await db.update(
      'routines',
      {'paused_at': null, 'paused_seconds': pausedSeconds + elapsed},
      where: 'id = ?',
      whereArgs: [routineId],
    );
  }
}

import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/program.dart';
import '../models/routine.dart';

/// SQL access for programs — named groups of routines — and their membership.
class ProgramRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  /// Every program, with its workout count joined for the list line.
  Future<List<Program>> listPrograms() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT p.id, p.name, p.description, p.sort_order,
             COUNT(pr.routine_id) AS workout_count
      FROM programs p
      LEFT JOIN program_routines pr ON pr.program_id = p.id
      GROUP BY p.id
      ORDER BY p.sort_order ASC, p.id ASC
    ''');
    return rows.map(Program.fromMap).toList();
  }

  Future<Program?> getProgram(int id) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT p.id, p.name, p.description, p.sort_order,
             COUNT(pr.routine_id) AS workout_count
      FROM programs p
      LEFT JOIN program_routines pr ON pr.program_id = p.id
      WHERE p.id = ?
      GROUP BY p.id
    ''', [id]);
    if (rows.isEmpty) return null;
    return Program.fromMap(rows.first);
  }

  /// Creates a program, appending it to the end of the list. Returns its id.
  Future<int> createProgram(String name, {String description = ''}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return -1;
    final db = await _db;
    final orderRows = await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next_order FROM programs',
    );
    return db.insert('programs', {
      'name': trimmed,
      'description': description.trim(),
      'sort_order': orderRows.first['next_order'] as int,
      'created_at': DateTime.now().toIso8601String().substring(0, 19),
    });
  }

  Future<void> updateDetails(int id, String name, String description) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final db = await _db;
    await db.update(
      'programs',
      {'name': trimmed, 'description': description.trim()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Drops a program. Its membership rows cascade; the routines themselves are
  /// untouched — a program is a shelf, not an owner.
  Future<void> deleteProgram(int id) async {
    final db = await _db;
    await db.delete('programs', where: 'id = ?', whereArgs: [id]);
  }

  /// Copies a program and its membership (not the routines themselves).
  Future<void> duplicateProgram(int id) async {
    final source = await getProgram(id);
    if (source == null) return;
    final newId = await createProgram(
      '${source.name} (copy)',
      description: source.description,
    );
    final db = await _db;
    await db.rawInsert(
      'INSERT INTO program_routines (program_id, routine_id, sort_order) '
      'SELECT ?, routine_id, sort_order FROM program_routines WHERE program_id = ?',
      [newId, id],
    );
  }

  /// The routines in a program, in the program's own order.
  Future<List<Routine>> routinesFor(int programId) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT r.id, r.name, r.sort_order, r.created_at, r.description,
             r.started_at, r.paused_at, r.paused_seconds
      FROM program_routines pr
      JOIN routines r ON r.id = pr.routine_id
      WHERE pr.program_id = ?
      ORDER BY pr.sort_order ASC, pr.id ASC
    ''', [programId]);
    return rows.map(Routine.fromMap).toList();
  }

  /// The ids of the programs a routine already belongs to — lets the picker
  /// show what's ticked without a second round trip.
  Future<Set<int>> programIdsFor(int routineId) async {
    final db = await _db;
    final rows = await db.query(
      'program_routines',
      columns: ['program_id'],
      where: 'routine_id = ?',
      whereArgs: [routineId],
    );
    return rows.map((r) => r['program_id'] as int).toSet();
  }

  /// Adds a routine to a program, appending it. Returns false when it is
  /// already a member (the UNIQUE constraint).
  Future<bool> addRoutine(int programId, int routineId) async {
    final db = await _db;
    final orderRows = await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next_order '
      'FROM program_routines WHERE program_id = ?',
      [programId],
    );
    try {
      await db.insert('program_routines', {
        'program_id': programId,
        'routine_id': routineId,
        'sort_order': orderRows.first['next_order'] as int,
      });
      return true;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) return false;
      rethrow;
    }
  }

  Future<void> removeRoutine(int programId, int routineId) async {
    final db = await _db;
    await db.delete(
      'program_routines',
      where: 'program_id = ? AND routine_id = ?',
      whereArgs: [programId, routineId],
    );
  }

  /// Persists a drag-reordered membership list.
  Future<void> reorderRoutines(int programId, List<int> orderedRoutineIds) async {
    final db = await _db;
    await db.transaction((txn) async {
      for (var i = 0; i < orderedRoutineIds.length; i++) {
        await txn.update(
          'program_routines',
          {'sort_order': i},
          where: 'program_id = ? AND routine_id = ?',
          whereArgs: [programId, orderedRoutineIds[i]],
        );
      }
    });
  }
}

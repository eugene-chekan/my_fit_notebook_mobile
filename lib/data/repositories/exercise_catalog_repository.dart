import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/exercise_catalog.dart';

const _catalogColumns =
    'id, name, description, default_sets, default_reps, default_reps_max';

/// SQL access for the canonical exercise catalog.
class ExerciseCatalogRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  /// Get-or-create the catalog entry for [name], returning the canonical
  /// row. Case-insensitive (the unique NOCASE index enforces it), so "squat"
  /// and "Squat" resolve to the same entry with its first-stored casing.
  ///
  /// When the entry is created fresh, the optional defaults are seeded onto
  /// it; for an entry that already exists, its defaults are left untouched.
  Future<CatalogEntry> ensure(
    String name, {
    int? defaultSets,
    int? defaultReps,
    int? defaultRepsMax,
  }) async {
    final trimmed = name.trim();
    final db = await _db;
    final now = DateTime.now().toIso8601String().substring(0, 19);
    await db.rawInsert(
      'INSERT OR IGNORE INTO exercise_catalog '
      '(name, description, default_sets, default_reps, default_reps_max, notes, created_at) '
      "VALUES (?, '', ?, ?, ?, '', ?)",
      [trimmed, defaultSets, defaultReps, defaultRepsMax, now],
    );
    final rows = await db.query(
      'exercise_catalog',
      columns: _catalogColumns.split(', '),
      where: 'name = ? COLLATE NOCASE',
      whereArgs: [trimmed],
      limit: 1,
    );
    return CatalogEntry.fromMap(rows.first);
  }

  /// All catalog names, alphabetical — the option pool for autocomplete.
  Future<List<String>> allNames() async {
    final db = await _db;
    final rows = await db.query(
      'exercise_catalog',
      columns: ['name'],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map((r) => r['name'] as String).toList();
  }

  /// Full catalog entries, alphabetical — backs the Exercises screen.
  Future<List<CatalogEntry>> listAll() async {
    final db = await _db;
    final rows = await db.query(
      'exercise_catalog',
      columns: _catalogColumns.split(', '),
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(CatalogEntry.fromMap).toList();
  }

  /// Creates a new library exercise. Returns false if the (case-insensitive)
  /// name already exists — the caller can surface that.
  Future<bool> create({
    required String name,
    String description = '',
    int? defaultSets,
    int? defaultReps,
    int? defaultRepsMax,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    final db = await _db;
    final now = DateTime.now().toIso8601String().substring(0, 19);
    try {
      await db.insert('exercise_catalog', {
        'name': trimmed,
        'description': description.trim(),
        'default_sets': defaultSets,
        'default_reps': defaultReps,
        'default_reps_max': defaultRepsMax,
        'notes': '',
        'created_at': now,
      });
      return true;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) return false;
      rethrow;
    }
  }

  /// Updates metadata and cascades a rename to linked routine exercises so
  /// library edits propagate to every routine using the exercise. Returns
  /// false on a name collision with a different entry.
  Future<bool> update(CatalogEntry entry) async {
    final name = entry.name.trim();
    if (name.isEmpty) return false;
    final db = await _db;
    try {
      await db.transaction((txn) async {
        await txn.update(
          'exercise_catalog',
          {
            'name': name,
            'description': entry.description.trim(),
            'default_sets': entry.defaultSets,
            'default_reps': entry.defaultReps,
            'default_reps_max': entry.defaultRepsMax,
          },
          where: 'id = ?',
          whereArgs: [entry.id],
        );
        await txn.update(
          'exercises',
          {'name': name},
          where: 'catalog_id = ?',
          whereArgs: [entry.id],
        );
      });
      return true;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) return false;
      rethrow;
    }
  }

  /// Deletes a library exercise. Routine rows that used it are unlinked
  /// (catalog_id → NULL) but keep their name snapshot and prescription.
  Future<void> delete(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update(
        'exercises',
        {'catalog_id': null},
        where: 'catalog_id = ?',
        whereArgs: [id],
      );
      await txn.delete('exercise_catalog', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// How many routine exercises currently reference [id] — shown in the
  /// delete confirmation.
  Future<int> usageCount(int id) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM exercises WHERE catalog_id = ?',
      [id],
    );
    return rows.first['c'] as int;
  }
}

import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/exercise_catalog.dart';

/// SQL access for the canonical exercise catalog.
class ExerciseCatalogRepository {
  Future<Database> get _db => AppDatabase.instance.database;

  /// Get-or-create the catalog entry for [name], returning the canonical
  /// row. Case-insensitive: "squat" and "Squat" resolve to the same entry
  /// (the unique NOCASE index enforces it), and the returned name carries
  /// whatever casing was first stored — so picking a suggestion or retyping
  /// an existing name yields consistent casing.
  Future<CatalogEntry> ensure(String name) async {
    final trimmed = name.trim();
    final db = await _db;
    final now = DateTime.now().toIso8601String().substring(0, 19);
    await db.rawInsert(
      "INSERT OR IGNORE INTO exercise_catalog (name, notes, created_at) VALUES (?, '', ?)",
      [trimmed, now],
    );
    final rows = await db.query(
      'exercise_catalog',
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
}

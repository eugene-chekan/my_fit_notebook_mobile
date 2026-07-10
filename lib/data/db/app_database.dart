import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Opens (and lazily creates) the on-device SQLite database. Table shape is
/// kept identical to the Flask app's database.py so a future sync layer can
/// map rows across the two stores without translation.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    final db = await _open();
    _db = db;
    return db;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'fitness.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE routines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            sort_order INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            description TEXT NOT NULL DEFAULT '',
            started_at TEXT,
            paused_at TEXT,
            paused_seconds INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE exercises (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            routine_id INTEGER NOT NULL REFERENCES routines(id) ON DELETE CASCADE,
            name TEXT NOT NULL,
            sort_order INTEGER NOT NULL DEFAULT 0,
            is_done INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE completions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            routine_id INTEGER NOT NULL REFERENCES routines(id) ON DELETE CASCADE,
            completed_on TEXT NOT NULL,
            duration_minutes INTEGER,
            started_at TEXT,
            paused_seconds INTEGER,
            UNIQUE(routine_id, completed_on)
          )
        ''');
        await db.execute('CREATE INDEX idx_exercises_routine ON exercises(routine_id)');
        await db.execute('CREATE INDEX idx_completions_date ON completions(completed_on)');
      },
    );
  }
}

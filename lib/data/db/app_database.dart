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
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createWorkoutTables(db);
        await _createProfileTables(db);
        await _createCatalogTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createProfileTables(db);
        if (oldVersion < 3) await _migrateToCatalog(db);
        if (oldVersion < 4) await _migrateToPrescriptions(db);
      },
    );
  }

  Future<void> _createWorkoutTables(Database db) async {
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
        is_done INTEGER NOT NULL DEFAULT 0,
        catalog_id INTEGER,
        sets INTEGER,
        reps_min INTEGER,
        reps_max INTEGER
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
  }

  /// v2: local user profile. A single-row `profile` table, a dated
  /// `measurements` history (values stored canonically in metric), and
  /// per-metric `targets`. All strictly on-device.
  Future<void> _createProfileTables(Database db) async {
    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT NOT NULL DEFAULT '',
        birth_date TEXT,
        height_cm REAL,
        units TEXT NOT NULL DEFAULT 'metric'
      )
    ''');
    await db.execute('''
      CREATE TABLE measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        metric TEXT NOT NULL,
        value REAL NOT NULL,
        measured_on TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_measurements_metric ON measurements(metric, measured_on)',
    );
    await db.execute('''
      CREATE TABLE targets (
        metric TEXT PRIMARY KEY,
        value REAL NOT NULL
      )
    ''');
  }

  /// v3: a canonical catalog of distinct exercises carrying metadata. It is
  /// the authoritative source for name suggestions; routine exercises link to
  /// it via `exercises.catalog_id` while keeping their own name snapshot.
  Future<void> _createCatalogTable(Database db) async {
    await db.execute('''
      CREATE TABLE exercise_catalog (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        default_sets INTEGER,
        default_reps INTEGER,
        default_reps_max INTEGER,
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX idx_catalog_name ON exercise_catalog(name COLLATE NOCASE)',
    );
  }

  /// v2 → v3: stand up the catalog, add the link column, then seed the
  /// catalog from existing exercise names (case-deduped by the unique index)
  /// and backfill each exercise's link. Ordered and non-destructive.
  Future<void> _migrateToCatalog(Database db) async {
    await _createCatalogTable(db);
    await db.execute('ALTER TABLE exercises ADD COLUMN catalog_id INTEGER');
    final now = DateTime.now().toIso8601String().substring(0, 19);
    await db.rawInsert(
      "INSERT OR IGNORE INTO exercise_catalog (name, notes, created_at) "
      "SELECT DISTINCT name, '', ? FROM exercises",
      [now],
    );
    await db.execute(
      'UPDATE exercises SET catalog_id = '
      '(SELECT id FROM exercise_catalog WHERE name = exercises.name COLLATE NOCASE)',
    );
  }

  /// v3 → v4: per-routine sets/reps prescriptions on exercises, and
  /// description + rep-range default on the catalog. Additive columns only.
  Future<void> _migrateToPrescriptions(Database db) async {
    await db.execute('ALTER TABLE exercises ADD COLUMN sets INTEGER');
    await db.execute('ALTER TABLE exercises ADD COLUMN reps_min INTEGER');
    await db.execute('ALTER TABLE exercises ADD COLUMN reps_max INTEGER');
    await db.execute(
      "ALTER TABLE exercise_catalog ADD COLUMN description TEXT NOT NULL DEFAULT ''",
    );
    await db.execute('ALTER TABLE exercise_catalog ADD COLUMN default_reps_max INTEGER');
  }
}

import 'package:flutter/foundation.dart';
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

  /// Current schema version. Bump alongside a new entry in [_onUpgrade].
  static const schemaVersion = 17;

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'fitness.db');
    return openDatabase(
      path,
      version: schemaVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// The schema lifecycle, named rather than inlined so [openForTesting] can
  /// build the very same database off-device — a test that ran different
  /// creation code would prove nothing about the app.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createWorkoutTables(db);
    await _createProfileTables(db);
    await _createCatalogTable(db);
    await _createSetLoggingTables(db);
    await _createScheduleRulesTable(db);
    await _createScheduleTable(db);
    await _createProgramTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await _createProfileTables(db);
    if (oldVersion < 3) await _migrateToCatalog(db);
    if (oldVersion < 4) await _migrateToPrescriptions(db);
    if (oldVersion < 5) await _migrateToRepUnits(db);
    if (oldVersion < 6) await _migrateToSetLogging(db);
    if (oldVersion < 7) await _migrateToLanguage(db);
    if (oldVersion < 8) await _migrateToCompletionStats(db);
    if (oldVersion < 9) await _migrateToSchedule(db);
    if (oldVersion < 10) await _migrateToScheduleTime(db);
    if (oldVersion < 11) await _migrateToTheme(db);
    if (oldVersion < 12) await _migrateToPaperStyles(db);
    if (oldVersion < 13) await _migrateToRecurrence(db);
    if (oldVersion < 14) await _migrateToProfilePhoto(db);
    if (oldVersion < 15) await _createProgramTables(db);
    if (oldVersion < 16) await _migrateToSetWeight(db);
    if (oldVersion < 17) await _migrateToFontScale(db);
  }

  /// Opens a throwaway database through [factory] (an in-memory one under
  /// sqflite_common_ffi) and hands the singleton to it, so repositories can be
  /// exercised on the test VM against the real schema. Never called by app code.
  ///
  /// Pass a [path] to use a file instead, which is what a migration test needs:
  /// an in-memory database is discarded on close, so reopening one can only ever
  /// run [_onCreate] again. To exercise [_onUpgrade] a test must lay down the
  /// old schema itself and then open through here — [_onCreate] always builds
  /// today's tables whatever version it is handed, so it cannot stand in for a
  /// historical one.
  @visibleForTesting
  Future<Database> openForTesting(
    DatabaseFactory factory, {
    int version = schemaVersion,
    String? path,
  }) async {
    final db = await factory.openDatabase(
      path ?? inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
    _db = db;
    return db;
  }

  /// Drops the cached handle so the next test opens a clean database.
  @visibleForTesting
  Future<void> resetForTesting() async {
    await _db?.close();
    _db = null;
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
        reps_max INTEGER,
        unit TEXT NOT NULL DEFAULT 'reps'
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
        exercises_completed INTEGER,
        sets_completed INTEGER,
        reps_total INTEGER,
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
        units TEXT NOT NULL DEFAULT 'metric',
        language TEXT NOT NULL DEFAULT 'system',
        theme TEXT NOT NULL DEFAULT 'paper',
        paper_styles TEXT NOT NULL DEFAULT '{}',
        photo_path TEXT,
        font_scale TEXT NOT NULL DEFAULT 'normal'
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
        default_unit TEXT NOT NULL DEFAULT 'reps',
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

  /// v4 → v5: a unit alongside sets/reps, so a prescription can be reps
  /// ("2x10"), seconds ("2x45sec"), or minutes ("1x2min"). Additive only;
  /// existing rows default to 'reps', preserving their current meaning.
  Future<void> _migrateToRepUnits(Database db) async {
    await db.execute("ALTER TABLE exercises ADD COLUMN unit TEXT NOT NULL DEFAULT 'reps'");
    await db.execute(
      "ALTER TABLE exercise_catalog ADD COLUMN default_unit TEXT NOT NULL DEFAULT 'reps'",
    );
  }

  /// v6: per-set tracking. `exercise_sets` holds the live working state — one
  /// row per set of a prescribed exercise, checkable individually with an
  /// adjustable actual-reps value. `completion_sets` snapshots the sets that
  /// were done when a session is finished (denormalized so history survives
  /// later edits/deletes of the exercise). Both cascade-delete via FKs.
  Future<void> _createSetLoggingTables(Database db) async {
    await db.execute('''
      CREATE TABLE exercise_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
        set_index INTEGER NOT NULL,
        actual_reps INTEGER,
        weight_kg REAL,
        is_done INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_exercise_sets_exercise ON exercise_sets(exercise_id)',
    );
    await db.execute('''
      CREATE TABLE completion_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        completion_id INTEGER NOT NULL REFERENCES completions(id) ON DELETE CASCADE,
        exercise_name TEXT NOT NULL,
        catalog_id INTEGER,
        set_index INTEGER NOT NULL,
        reps INTEGER,
        weight_kg REAL,
        unit TEXT NOT NULL DEFAULT 'reps'
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_completion_sets_completion ON completion_sets(completion_id)',
    );
  }

  /// v5 → v6: stand up the set-logging tables, then seed `exercise_sets` for
  /// every existing prescribed exercise (one row per set, reps prefilled to
  /// the top of the range, all unchecked) so current routines gain their sets
  /// without data loss. `completion_sets` starts empty (no history to backfill).
  Future<void> _migrateToSetLogging(Database db) async {
    await _createSetLoggingTables(db);
    final exercises = await db.rawQuery(
      'SELECT id, sets, reps_min, reps_max FROM exercises WHERE sets > 0',
    );
    for (final row in exercises) {
      final exerciseId = row['id'] as int;
      final sets = row['sets'] as int;
      final prefill = (row['reps_max'] as int?) ?? (row['reps_min'] as int?);
      for (var i = 1; i <= sets; i++) {
        await db.insert('exercise_sets', {
          'exercise_id': exerciseId,
          'set_index': i,
          'actual_reps': prefill,
          'is_done': 0,
        });
      }
    }
  }

  /// v6 → v7: a UI-language preference on the profile. `'system'` follows the
  /// device locale; `'en'`/`'ru'` pin a choice. Additive, non-destructive.
  Future<void> _migrateToLanguage(Database db) async {
    await db.execute(
      "ALTER TABLE profile ADD COLUMN language TEXT NOT NULL DEFAULT 'system'",
    );
  }

  /// v7 → v8: snapshot each session's totals on its completion row so the
  /// logged-sessions list can show what a workout contained, not just when it
  /// happened. Additive and nullable — existing rows keep NULLs and simply
  /// show date + duration as before.
  Future<void> _migrateToCompletionStats(Database db) async {
    await db.execute('ALTER TABLE completions ADD COLUMN exercises_completed INTEGER');
    await db.execute('ALTER TABLE completions ADD COLUMN sets_completed INTEGER');
    await db.execute('ALTER TABLE completions ADD COLUMN reps_total INTEGER');
  }

  /// v9: planned workouts. One row per (routine, future date) plan. `status`
  /// is planned/done/skipped; when a plan is fulfilled it links the resulting
  /// completion (cleared to NULL if that completion is later deleted). Cascade
  /// deletes with its routine. UNIQUE keeps a routine from being double-booked
  /// on the same day.
  Future<void> _createScheduleTable(Database db) async {
    await db.execute('''
      CREATE TABLE scheduled_workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        routine_id INTEGER NOT NULL REFERENCES routines(id) ON DELETE CASCADE,
        scheduled_date TEXT NOT NULL,
        scheduled_time TEXT,
        status TEXT NOT NULL DEFAULT 'planned',
        completion_id INTEGER REFERENCES completions(id) ON DELETE SET NULL,
        rule_id INTEGER REFERENCES schedule_rules(id) ON DELETE CASCADE,
        created_at TEXT NOT NULL,
        UNIQUE(routine_id, scheduled_date)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_scheduled_date ON scheduled_workouts(scheduled_date)',
    );
  }

  /// A repeating-workout rule. This app's only recurrence kind is "weekly on
  /// one or more weekdays" — [weekdays] is a CSV of ISO weekday ints (1=Mon).
  /// [generated_through] is the watermark up to which occurrences have already
  /// been materialised into `scheduled_workouts`; the rolling top-up only ever
  /// adds dates strictly after it, so a manually deleted occurrence in the past
  /// range is never resurrected.
  Future<void> _createScheduleRulesTable(Database db) async {
    await db.execute('''
      CREATE TABLE schedule_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        routine_id INTEGER NOT NULL REFERENCES routines(id) ON DELETE CASCADE,
        freq TEXT NOT NULL DEFAULT 'weekly',
        weekdays TEXT NOT NULL,
        scheduled_time TEXT,
        start_date TEXT NOT NULL,
        generated_through TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// v8 → v9: stand up the scheduled-workouts table. Additive — nothing to
  /// backfill.
  Future<void> _migrateToSchedule(Database db) async {
    await _createScheduleTable(db);
  }

  /// v9 → v10: an optional time-of-day on a plan (HH:mm). A plan with a time
  /// gets a reminder; date-only plans stay quiet. Additive and nullable.
  Future<void> _migrateToScheduleTime(Database db) async {
    await db.execute('ALTER TABLE scheduled_workouts ADD COLUMN scheduled_time TEXT');
  }

  /// v10 → v11: a selectable notebook theme on the profile. `'paper'` is the
  /// light default; other ids name a dark ground. Additive, non-destructive.
  Future<void> _migrateToTheme(Database db) async {
    await db.execute(
      "ALTER TABLE profile ADD COLUMN theme TEXT NOT NULL DEFAULT 'paper'",
    );
  }

  /// v11 → v12: per-theme ruled/grid paper-style overrides, stored as a JSON
  /// object string on the profile row. Additive; empty map = all defaults.
  Future<void> _migrateToPaperStyles(Database db) async {
    await db.execute(
      "ALTER TABLE profile ADD COLUMN paper_styles TEXT NOT NULL DEFAULT '{}'",
    );
  }

  /// v12 → v13: repeating scheduled workouts. Stands up the `schedule_rules`
  /// table and links each generated occurrence back to its rule via a nullable
  /// `rule_id` on `scheduled_workouts` (one-off plans leave it null). Additive
  /// and non-destructive — existing plans keep working untouched.
  Future<void> _migrateToRecurrence(Database db) async {
    await _createScheduleRulesTable(db);
    await db.execute(
      'ALTER TABLE scheduled_workouts ADD COLUMN rule_id INTEGER '
      'REFERENCES schedule_rules(id) ON DELETE CASCADE',
    );
  }

  /// Programs: named groups of routines, the shelf a training split lives on
  /// ("Push / Pull / Legs"). The membership table is a plain many-to-many, so a
  /// routine can sit in several programs at once and dropping either side
  /// cleans up its links.
  Future<void> _createProgramTables(Database db) async {
    await db.execute('''
      CREATE TABLE programs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE program_routines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        program_id INTEGER NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
        routine_id INTEGER NOT NULL REFERENCES routines(id) ON DELETE CASCADE,
        sort_order INTEGER NOT NULL DEFAULT 0,
        UNIQUE(program_id, routine_id)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_program_routines_program ON program_routines(program_id)',
    );
  }

  /// v15 → v16: an optional load per set, in kilograms. Canonical metric like
  /// every other measurement in the app — pounds are a display choice, made at
  /// the point the number is shown. Nullable, so a bodyweight set simply has
  /// no weight rather than a zero.
  Future<void> _migrateToSetWeight(Database db) async {
    await db.execute('ALTER TABLE exercise_sets ADD COLUMN weight_kg REAL');
    await db.execute('ALTER TABLE completion_sets ADD COLUMN weight_kg REAL');
  }

  /// v13 → v14: an optional profile photo. Stores just the file *name* of an
  /// image copied into the app documents dir (resolved to an absolute path at
  /// read time, so it survives the sandbox path changing). Additive, nullable.
  Future<void> _migrateToProfilePhoto(Database db) async {
    await db.execute('ALTER TABLE profile ADD COLUMN photo_path TEXT');
  }

  /// v16 → v17: a text-size preference on the profile. Stored as the name of
  /// an `AppFontScale` value rather than a number so the scale factors stay a
  /// UI decision and can be re-tuned without touching stored data. Additive,
  /// defaulting to the size every existing install is already reading at.
  Future<void> _migrateToFontScale(Database db) async {
    await db.execute(
      "ALTER TABLE profile ADD COLUMN font_scale TEXT NOT NULL DEFAULT 'normal'",
    );
  }
}

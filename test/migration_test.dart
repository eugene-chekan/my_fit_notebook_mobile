import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:my_fit_notebook_mobile/data/db/app_database.dart';
import 'package:my_fit_notebook_mobile/data/models/profile.dart';
import 'package:my_fit_notebook_mobile/data/repositories/exercise_repository.dart';
import 'package:my_fit_notebook_mobile/data/repositories/profile_repository.dart';
import 'package:my_fit_notebook_mobile/data/repositories/routine_repository.dart';

/// Migrations are the one part of this schema that runs against data someone
/// already has, so they are tested against a real file: an in-memory database
/// is thrown away on close, and reopening one only ever runs onCreate again.
///
/// The old schema is laid down by hand here rather than by the app's own
/// onCreate, which always builds today's tables whatever version it is handed
/// and so cannot impersonate an older install.
void main() {
  setUpAll(sqfliteFfiInit);

  late Directory dir;
  late String dbPath;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('mfn_migration');
    dbPath = p.join(dir.path, 'fitness.db');
    await AppDatabase.instance.resetForTesting();
  });

  tearDown(() async {
    await AppDatabase.instance.resetForTesting();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  /// The v15 shape of every table a later migration touches, with one routine,
  /// one exercise, one logged set and a filled-in profile already in them.
  Future<void> layDownV15() async {
    final db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(version: 15),
    );
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
    // v15 shape: no weight_kg on either table.
    await db.execute('''
      CREATE TABLE exercise_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
        set_index INTEGER NOT NULL,
        actual_reps INTEGER,
        is_done INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE completion_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        completion_id INTEGER NOT NULL,
        exercise_name TEXT NOT NULL,
        catalog_id INTEGER,
        set_index INTEGER NOT NULL,
        reps INTEGER,
        unit TEXT NOT NULL DEFAULT 'reps'
      )
    ''');

    // v15 shape: no font_scale.
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
        photo_path TEXT
      )
    ''');

    await db.insert('profile', {
      'id': 1,
      'name': 'Sam',
      'height_cm': 178.0,
      'units': 'imperial',
      'theme': 'blueprint',
    });
    await db.insert('routines', {
      'name': 'Leg day',
      'created_at': '2026-01-01T00:00:00',
    });
    await db.insert('exercises', {
      'routine_id': 1,
      'name': 'Squat',
      'sets': 3,
      'reps_min': 5,
    });
    await db.insert('exercise_sets', {
      'exercise_id': 1,
      'set_index': 1,
      'actual_reps': 5,
      'is_done': 1,
    });
    await db.close();
  }

  Future<List<String>> columnsOf(dynamic db, String table) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return [for (final r in rows) r['name'] as String];
  }

  test('v15 → v16 adds the load columns without disturbing logged sets',
      () async {
    await layDownV15();

    final db = await AppDatabase.instance
        .openForTesting(databaseFactoryFfi, path: dbPath);

    expect(await columnsOf(db, 'exercise_sets'), contains('weight_kg'));
    expect(await columnsOf(db, 'completion_sets'), contains('weight_kg'));

    // The set that was already logged is still there, now simply without a load.
    final sets = await ExerciseRepository().listSetsForRoutine(1);
    expect(sets[1], hasLength(1));
    expect(sets[1]!.single.actualReps, 5);
    expect(sets[1]!.single.weightKg, isNull);
    expect(sets[1]!.single.isDone, isTrue);
  });

  test('a load can be written the moment the upgrade lands', () async {
    await layDownV15();
    await AppDatabase.instance.openForTesting(databaseFactoryFfi, path: dbPath);

    final exercises = ExerciseRepository();
    final set = (await exercises.listSetsForRoutine(1))[1]!.single;
    await exercises.setSetLog(set.id, 5, weightKg: 90);

    final reloaded = (await exercises.listSetsForRoutine(1))[1]!.single;
    expect(reloaded.weightKg, 90);
  });

  test('v16 → v17 adds font_scale without disturbing the rest of the profile',
      () async {
    await layDownV15();

    final db = await AppDatabase.instance
        .openForTesting(databaseFactoryFfi, path: dbPath);
    expect(await columnsOf(db, 'profile'), contains('font_scale'));

    // An existing reader keeps everything they had set, and lands on the size
    // they were already reading at rather than a surprise resize.
    final profile = await ProfileRepository().getProfile();
    expect(profile.name, 'Sam');
    expect(profile.units, Units.imperial);
    expect(profile.theme, AppTheme.blueprint);
    expect(profile.fontScale, AppFontScale.normal);
  });

  test('v17 → v18 seeds the freestyle workout beside the existing ones',
      () async {
    await layDownV15();

    final db = await AppDatabase.instance
        .openForTesting(databaseFactoryFfi, path: dbPath);
    expect(await columnsOf(db, 'routines'), contains('is_adhoc'));

    final all = await RoutineRepository().listRoutines();
    // The workout the user already had is untouched, and is not the new one.
    expect(all.where((r) => !r.isAdhoc).map((r) => r.name), ['Leg day']);
    expect(all.where((r) => r.isAdhoc), hasLength(1));
    // It sorts ahead of everything already in the book.
    expect(all.first.isAdhoc, isTrue);
  });

  test('a text size can be chosen the moment the upgrade lands', () async {
    await layDownV15();
    await AppDatabase.instance.openForTesting(databaseFactoryFfi, path: dbPath);

    final profiles = ProfileRepository();
    await profiles.setFontScale(AppFontScale.large);

    expect((await profiles.getProfile()).fontScale, AppFontScale.large);
  });
}

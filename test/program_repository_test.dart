import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:my_fit_notebook_mobile/data/db/app_database.dart';
import 'package:my_fit_notebook_mobile/data/repositories/program_repository.dart';
import 'package:my_fit_notebook_mobile/data/repositories/routine_repository.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late ProgramRepository programs;
  late RoutineRepository routines;

  setUp(() async {
    await AppDatabase.instance.resetForTesting();
    await AppDatabase.instance.openForTesting(databaseFactoryFfi);
    programs = ProgramRepository();
    routines = RoutineRepository();
  });

  tearDown(() => AppDatabase.instance.resetForTesting());

  /// Creates a routine and returns its id.
  Future<int> newRoutine(String name) async {
    await routines.addRoutine(name);
    final all = await routines.listRoutines();
    return all.firstWhere((r) => r.name == name).id;
  }

  test('a program starts empty and counts its workouts', () async {
    final id = await programs.createProgram('Push / Pull / Legs');
    expect((await programs.listPrograms()).single.workoutCount, 0);

    await programs.addRoutine(id, await newRoutine('Push'));
    await programs.addRoutine(id, await newRoutine('Pull'));

    expect((await programs.listPrograms()).single.workoutCount, 2);
  });

  test('routinesFor returns the filed workouts in order', () async {
    // Guards the join's column list: the Routine model casts created_at
    // non-null, so omitting it from the SELECT throws at parse time.
    final id = await programs.createProgram('Split');
    final push = await newRoutine('Push');
    final pull = await newRoutine('Pull');
    await programs.addRoutine(id, push);
    await programs.addRoutine(id, pull);

    final filed = await programs.routinesFor(id);
    expect(filed.map((r) => r.name), ['Push', 'Pull']);
    expect(filed.first.createdAt, isNotEmpty);
  });

  test('adding the same workout twice reports it was already there', () async {
    final id = await programs.createProgram('Split');
    final push = await newRoutine('Push');

    expect(await programs.addRoutine(id, push), isTrue);
    expect(await programs.addRoutine(id, push), isFalse);
    expect((await programs.routinesFor(id)).length, 1);
  });

  test('a workout can sit in several programs at once', () async {
    final a = await programs.createProgram('Strength block');
    final b = await programs.createProgram('Deload week');
    final squat = await newRoutine('Squat day');

    await programs.addRoutine(a, squat);
    await programs.addRoutine(b, squat);

    expect(await programs.programIdsFor(squat), {a, b});
  });

  test('deleting a program leaves its workouts in the library', () async {
    final id = await programs.createProgram('Split');
    final push = await newRoutine('Push');
    await programs.addRoutine(id, push);

    await programs.deleteProgram(id);

    expect(await programs.listPrograms(), isEmpty);
    expect((await routines.listRoutines()).map((r) => r.name), ['Push']);
    expect(await programs.programIdsFor(push), isEmpty); // link cascaded away
  });

  test('deleting a workout removes it from the programs holding it', () async {
    final id = await programs.createProgram('Split');
    final push = await newRoutine('Push');
    await programs.addRoutine(id, push);

    await routines.deleteRoutine(push);

    expect((await programs.listPrograms()).single.workoutCount, 0);
  });

  test('removing a workout from a program keeps the others', () async {
    final id = await programs.createProgram('Split');
    final push = await newRoutine('Push');
    final pull = await newRoutine('Pull');
    await programs.addRoutine(id, push);
    await programs.addRoutine(id, pull);

    await programs.removeRoutine(id, push);

    expect((await programs.routinesFor(id)).map((r) => r.name), ['Pull']);
  });

  test('duplicating a program copies its membership, not its workouts',
      () async {
    final id = await programs.createProgram('Split');
    await programs.addRoutine(id, await newRoutine('Push'));

    await programs.duplicateProgram(id);

    final all = await programs.listPrograms();
    expect(all.map((p) => p.name), ['Split', 'Split (copy)']);
    expect(all.last.workoutCount, 1);
    // The workout itself was not cloned — both programs point at the one row.
    expect((await routines.listRoutines()).length, 1);
  });

  test('reordering membership sticks', () async {
    final id = await programs.createProgram('Split');
    final push = await newRoutine('Push');
    final pull = await newRoutine('Pull');
    await programs.addRoutine(id, push);
    await programs.addRoutine(id, pull);

    await programs.reorderRoutines(id, [pull, push]);

    expect((await programs.routinesFor(id)).map((r) => r.name), ['Pull', 'Push']);
  });

  test('an upgrade from v14 gains the program tables', () async {
    // Programs arrived in v15; existing installs must pick them up.
    await AppDatabase.instance.resetForTesting();
    await AppDatabase.instance.openForTesting(databaseFactoryFfi, version: 14);
    await AppDatabase.instance.resetForTesting();
    await AppDatabase.instance.openForTesting(databaseFactoryFfi);

    final id = await ProgramRepository().createProgram('After upgrade');
    expect((await ProgramRepository().listPrograms()).single.id, id);
  });
}

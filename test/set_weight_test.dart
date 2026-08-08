import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:my_fit_notebook_mobile/data/db/app_database.dart';
import 'package:my_fit_notebook_mobile/data/repositories/completion_repository.dart';
import 'package:my_fit_notebook_mobile/data/repositories/exercise_repository.dart';
import 'package:my_fit_notebook_mobile/data/repositories/routine_repository.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late ExerciseRepository exercises;
  late RoutineRepository routines;
  late CompletionRepository completions;

  setUp(() async {
    await AppDatabase.instance.resetForTesting();
    await AppDatabase.instance.openForTesting(databaseFactoryFfi);
    exercises = ExerciseRepository();
    routines = RoutineRepository();
    completions = CompletionRepository();
  });

  tearDown(() => AppDatabase.instance.resetForTesting());

  /// A routine with one prescribed exercise, and its seeded set rows.
  Future<(int routineId, int exerciseId)> seed() async {
    await routines.addRoutine('Leg day');
    // Skip the built-in freestyle row every database is seeded with.
    final routine =
        (await routines.listRoutines()).firstWhere((r) => !r.isAdhoc);
    await exercises.addExercise(routine.id, 'Squat', sets: 3, repsMin: 5);
    final exercise = (await exercises.listExercises(routine.id)).single;
    return (routine.id, exercise.id);
  }

  test('a set carries an optional load alongside its reps', () async {
    final (routineId, exerciseId) = await seed();
    final sets = (await exercises.listSetsForRoutine(routineId))[exerciseId]!;

    await exercises.setSetLog(sets.first.id, 5, weightKg: 82.5);

    final reloaded = (await exercises.listSetsForRoutine(routineId))[exerciseId]!;
    expect(reloaded.first.actualReps, 5);
    expect(reloaded.first.weightKg, 82.5);
  });

  test('a bodyweight set simply has no load', () async {
    final (routineId, exerciseId) = await seed();
    final sets = (await exercises.listSetsForRoutine(routineId))[exerciseId]!;

    await exercises.setSetLog(sets.first.id, 12);

    final reloaded = (await exercises.listSetsForRoutine(routineId))[exerciseId]!;
    expect(reloaded.first.actualReps, 12);
    expect(reloaded.first.weightKg, isNull);
  });

  test('clearing the load writes it away again', () async {
    final (routineId, exerciseId) = await seed();
    final sets = (await exercises.listSetsForRoutine(routineId))[exerciseId]!;
    await exercises.setSetLog(sets.first.id, 5, weightKg: 60);

    await exercises.setSetLog(sets.first.id, 5);

    final reloaded = (await exercises.listSetsForRoutine(routineId))[exerciseId]!;
    expect(reloaded.first.weightKg, isNull);
  });

  test('the load survives into the session history', () async {
    final (routineId, exerciseId) = await seed();
    final sets = (await exercises.listSetsForRoutine(routineId))[exerciseId]!;
    await exercises.setSetLog(sets[0].id, 5, weightKg: 100);
    await exercises.setSetLog(sets[1].id, 5); // bodyweight
    await exercises.toggleSet(sets[0].id, exerciseId);
    await exercises.toggleSet(sets[1].id, exerciseId);

    final completionId = await completions.addCompletionReturningId(
      routineId,
      DateTime(2026, 7, 28),
    );
    await exercises.snapshotDoneSets(routineId, completionId!);

    final logged = await completions.setsFor(completionId);
    expect(logged, hasLength(2));
    expect(logged.first.weightKg, 100);
    expect(logged.last.weightKg, isNull);
  });
}

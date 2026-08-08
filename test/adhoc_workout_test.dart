import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:my_fit_notebook_mobile/data/db/app_database.dart';
import 'package:my_fit_notebook_mobile/data/repositories/completion_repository.dart';
import 'package:my_fit_notebook_mobile/data/repositories/exercise_catalog_repository.dart';
import 'package:my_fit_notebook_mobile/data/repositories/exercise_repository.dart';
import 'package:my_fit_notebook_mobile/data/repositories/routine_repository.dart';
import 'package:my_fit_notebook_mobile/data/services/workout_service.dart';

/// The freestyle workout's whole point is what it *doesn't* keep: a name typed
/// once for one session must reach the log and nowhere else. These pin both
/// halves of that — what survives, and what must not.
void main() {
  setUpAll(sqfliteFfiInit);

  late RoutineRepository routines;
  late ExerciseRepository exercises;
  late ExerciseCatalogRepository catalog;
  late CompletionRepository completions;
  late WorkoutService service;

  setUp(() async {
    await AppDatabase.instance.resetForTesting();
    await AppDatabase.instance.openForTesting(databaseFactoryFfi);
    routines = RoutineRepository();
    exercises = ExerciseRepository();
    catalog = ExerciseCatalogRepository();
    completions = CompletionRepository();
    service = WorkoutService();
  });

  tearDown(() => AppDatabase.instance.resetForTesting());

  Future<int> adhocId() async => (await routines.adhocRoutine())!.id;

  /// Runs a whole freestyle session: start, add [names], tick every set, finish.
  Future<void> session(List<String> names) async {
    final id = await adhocId();
    await service.startWorkout(id);
    for (final name in names) {
      await exercises.addAdhocExercise(id, name);
    }
    for (final entry in (await exercises.listSetsForRoutine(id)).entries) {
      await exercises.markAllSets(entry.key, true);
    }
    await service.finishWorkout(id);
  }

  group('the seeded routine', () {
    test('exists on a fresh database, exactly once', () async {
      final all = await routines.listRoutines();
      expect(all.where((r) => r.isAdhoc), hasLength(1));
    });

    test('sorts ahead of the workouts you make yourself', () async {
      await routines.addRoutine('Leg day');
      expect((await routines.listRoutines()).first.isAdhoc, isTrue);
    });

    test('refuses to be deleted', () async {
      await routines.deleteRoutine(await adhocId());
      expect(await routines.adhocRoutine(), isNotNull);
    });

    test('a copy of it is an ordinary workout', () async {
      await routines.duplicateRoutine(await adhocId());
      expect((await routines.listRoutines()).where((r) => r.isAdhoc), hasLength(1));
    });
  });

  group('adding an exercise mid-session', () {
    test('a name the library has never seen is never registered', () async {
      await exercises.addAdhocExercise(await adhocId(), 'Sandbag carry');

      expect(await catalog.allNames(), isEmpty);
      final added = (await exercises.listExercises(await adhocId())).single;
      expect(added.name, 'Sandbag carry');
      expect(added.catalogId, isNull);
    });

    test('a name the library knows links to it, without duplicating it',
        () async {
      await catalog.ensure('Squat');
      final entry = (await catalog.listAll()).single;

      await exercises.addAdhocExercise(await adhocId(), 'squat');

      expect(await catalog.allNames(), ['Squat']);
      final added = (await exercises.listExercises(await adhocId())).single;
      expect(added.catalogId, entry.id);
      // Canonical casing from the library, not what was typed.
      expect(added.name, 'Squat');
    });

    test('always gets at least one set, so its name can reach the log',
        () async {
      // snapshotDoneSets only carries exercises that *have* sets; a bare
      // checkbox would leave nothing behind but a count.
      await exercises.addAdhocExercise(await adhocId(), 'Sled push');

      final sets = await exercises.listSetsForRoutine(await adhocId());
      expect(sets.values.single, hasLength(1));
    });

    test('honours a prescription when one is given', () async {
      await exercises.addAdhocExercise(
        await adhocId(),
        'Sled push',
        sets: 4,
        repsMin: 8,
      );

      final sets = await exercises.listSetsForRoutine(await adhocId());
      expect(sets.values.single, hasLength(4));
      expect(sets.values.single.first.actualReps, 8);
    });
  });

  group('what the session leaves behind', () {
    test('the log keeps the exercise by name', () async {
      await session(['Sandbag carry']);

      final logged = (await completions.listForRoutine(await adhocId())).single;
      final sets = await completions.setsFor(logged.id);
      expect(sets.single.exerciseName, 'Sandbag carry');
    });

    test('the sheet is blank again, and the library still empty', () async {
      await session(['Sandbag carry']);

      expect(await exercises.listExercises(await adhocId()), isEmpty);
      expect(await catalog.allNames(), isEmpty);
    });

    test('a second session logs only its own work', () async {
      final id = await adhocId();
      await session(['Sandbag carry']);
      // Back-date the first session. `completed_on` is stored to the minute
      // and is UNIQUE per routine, so two sessions finished inside the same
      // minute collide and the second is dropped — a pre-existing rule that
      // this test would otherwise trip over rather than exercise.
      final first = (await completions.listForRoutine(id)).single;
      await completions.updateCompletionDate(
        first.id,
        id,
        DateTime(2026, 5, 1, 9, 30),
      );

      await session(['Tyre flip']);

      final logs = await completions.listForRoutine(id);
      expect(logs, hasLength(2));
      // Newest first: the second session, carrying only what it did.
      expect(
        (await completions.setsFor(logs.first.id)).map((s) => s.exerciseName),
        ['Tyre flip'],
      );
      expect(
        (await completions.setsFor(logs.last.id)).map((s) => s.exerciseName),
        ['Sandbag carry'],
      );
    });

    test('an abandoned session does not bleed into the next one', () async {
      final id = await adhocId();
      await service.startWorkout(id);
      await exercises.addAdhocExercise(id, 'Sandbag carry');
      // …and the user simply walks away, never finishing.

      await service.startWorkout(id);

      expect(await exercises.listExercises(id), isEmpty);
    });

    test('an ordinary workout keeps its exercises across a session', () async {
      final legs = await routines.addRoutine('Leg day');
      await exercises.addExercise(legs, 'Squat', sets: 3, repsMin: 5);

      await service.startWorkout(legs);
      await service.finishWorkout(legs);

      expect(await exercises.listExercises(legs), hasLength(1));
      expect(await catalog.allNames(), ['Squat']);
    });
  });
}

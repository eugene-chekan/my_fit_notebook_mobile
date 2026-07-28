import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:my_fit_notebook_mobile/data/db/app_database.dart';
import 'package:my_fit_notebook_mobile/data/repositories/exercise_repository.dart';
import 'package:my_fit_notebook_mobile/data/repositories/routine_repository.dart';
import 'package:my_fit_notebook_mobile/l10n/app_localizations.dart';
import 'package:my_fit_notebook_mobile/screens/manage_routine_screen.dart';
import 'package:my_fit_notebook_mobile/theme/notebook_theme.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  setUp(() async {
    await AppDatabase.instance.resetForTesting();
    await AppDatabase.instance.openForTesting(databaseFactoryFfiNoIsolate);
  });

  tearDown(() => AppDatabase.instance.resetForTesting());

  testWidgets('the exercise list renders inside its reorderable list',
      (tester) async {
    // Regression: the reorderable list asserts that every child it is handed
    // carries a key. When the row widget kept the key only on the Dismissible
    // inside it, the whole list rendered as a grey error box.
    final routines = RoutineRepository();
    await routines.addRoutine('Cycling');
    final routine = (await routines.listRoutines()).single;
    final exercises = ExerciseRepository();
    await exercises.addExercise(routine.id, 'Warm up', sets: 1, repsMin: 10);
    await exercises.addExercise(routine.id, 'Intervals', sets: 5, repsMin: 60);

    await tester.pumpWidget(
      MaterialApp(
        theme: NotebookTheme.forId(ThemeId.paper),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ManageRoutineScreen(routineId: routine.id),
      ),
    );
    await tester.pumpAndSettle();

    // The rows draw their name and prescription as one rich span, so match
    // through it rather than looking for a plain Text.
    expect(tester.takeException(), isNull);
    expect(find.byType(ReorderableListView), findsOneWidget);
    expect(
      find.textContaining('Warm up', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Intervals', findRichText: true),
      findsOneWidget,
    );
  });
}

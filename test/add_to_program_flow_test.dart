import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:my_fit_notebook_mobile/data/db/app_database.dart';
import 'package:my_fit_notebook_mobile/data/repositories/program_repository.dart';
import 'package:my_fit_notebook_mobile/data/repositories/routine_repository.dart';
import 'package:my_fit_notebook_mobile/l10n/app_localizations.dart';
import 'package:my_fit_notebook_mobile/screens/routines_screen.dart';
import 'package:my_fit_notebook_mobile/theme/notebook_theme.dart';

/// Drives the real screen, so the long-press → pick → feedback path is
/// exercised exactly as a user meets it.
void main() {
  setUpAll(sqfliteFfiInit);

  late ProgramRepository programs;
  late RoutineRepository routines;

  setUp(() async {
    await AppDatabase.instance.resetForTesting();
    // The no-isolate factory keeps SQLite on the test isolate: testWidgets runs
    // inside a fake-async zone, and work handed to a background isolate never
    // completes under it, so the default factory hangs here.
    await AppDatabase.instance.openForTesting(databaseFactoryFfiNoIsolate);
    programs = ProgramRepository();
    routines = RoutineRepository();
  });

  tearDown(() => AppDatabase.instance.resetForTesting());

  Future<int> seedRoutine(String name) async {
    await routines.addRoutine(name);
    return (await routines.listRoutines()).firstWhere((r) => r.name == name).id;
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NotebookTheme.forId(ThemeId.paper),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const RoutinesScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('long-pressing a workout files it into a program',
      (tester) async {
    await seedRoutine('Cycling');
    await programs.createProgram('Cardio block');
    await pumpScreen(tester);

    await tester.longPress(find.text('Cycling'));
    await tester.pumpAndSettle();
    expect(find.text('Cardio block'), findsOneWidget);

    await tester.tap(find.text('Cardio block'));
    await tester.pumpAndSettle();

    expect(find.text('Filed “Cardio block”.'), findsOneWidget);
  });

  testWidgets('a workout already filed there says so', (tester) async {
    final cycling = await seedRoutine('Cycling');
    final program = await programs.createProgram('Cardio block');
    await programs.addRoutine(program, cycling);
    await pumpScreen(tester);

    await tester.longPress(find.text('Cycling'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cardio block'));
    await tester.pumpAndSettle();

    expect(find.text('Already in “Cardio block”.'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:my_fit_notebook_mobile/data/db/app_database.dart';
import 'package:my_fit_notebook_mobile/data/repositories/completion_repository.dart';
import 'package:my_fit_notebook_mobile/data/repositories/routine_repository.dart';
import 'package:my_fit_notebook_mobile/l10n/app_localizations.dart';
import 'package:my_fit_notebook_mobile/screens/training_log_screen.dart';
import 'package:my_fit_notebook_mobile/theme/notebook_theme.dart';

/// The Training log is the only place the whole history is readable, so this
/// drives the real screens down the path a user takes: workout → session →
/// report.
void main() {
  setUpAll(sqfliteFfiInit);

  late CompletionRepository completions;
  late RoutineRepository routines;

  setUp(() async {
    await AppDatabase.instance.resetForTesting();
    // The no-isolate factory keeps SQLite on the test isolate: testWidgets runs
    // inside a fake-async zone, and work handed to a background isolate never
    // completes under it, so the default factory hangs here.
    await AppDatabase.instance.openForTesting(databaseFactoryFfiNoIsolate);
    completions = CompletionRepository();
    routines = RoutineRepository();
  });

  tearDown(() => AppDatabase.instance.resetForTesting());

  Future<int> seedRoutine(String name) async {
    await routines.addRoutine(name);
    return (await routines.listRoutines()).firstWhere((r) => r.name == name).id;
  }

  Future<void> seedSession(int routineId, DateTime on, {int minutes = 45}) {
    return completions.addCompletion(routineId, on, durationMinutes: minutes);
  }

  Future<void> pumpLog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NotebookTheme.forId(ThemeId.paper),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const TrainingLogScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the logged-workouts query', () {
    test('lists only workouts that have sessions, most recent first', () async {
      final legs = await seedRoutine('Leg day');
      final push = await seedRoutine('Push day');
      await seedRoutine('Never trained');

      await seedSession(legs, DateTime(2026, 5, 1));
      await seedSession(push, DateTime(2026, 6, 1));

      final logged = await completions.loggedRoutines();
      expect(logged.map((e) => e.name), ['Push day', 'Leg day']);
    });

    test('counts the sessions and reports the latest date', () async {
      final legs = await seedRoutine('Leg day');
      await seedSession(legs, DateTime(2026, 5, 1));
      await seedSession(legs, DateTime(2026, 5, 8));
      await seedSession(legs, DateTime(2026, 5, 15));

      final entry = (await completions.loggedRoutines()).single;
      expect(entry.routineId, legs);
      expect(entry.sessionCount, 3);
      expect(entry.lastCompletedOn, startsWith('2026-05-15'));
    });

    test('a workout drops off the list once its last session is deleted',
        () async {
      final legs = await seedRoutine('Leg day');
      await seedSession(legs, DateTime(2026, 5, 1));
      final session = (await completions.listForRoutine(legs)).single;

      await completions.deleteCompletion(session.id, legs);

      expect(await completions.loggedRoutines(), isEmpty);
    });
  });

  testWidgets('an empty log says so rather than showing a blank page',
      (tester) async {
    await seedRoutine('Never trained');
    await pumpLog(tester);

    expect(
      find.text('Nothing logged yet — finish a workout and it lands here.'),
      findsOneWidget,
    );
  });

  testWidgets('tapping a workout lists its sessions, and a session opens '
      'the full report', (tester) async {
    final legs = await seedRoutine('Leg day');
    await seedSession(legs, DateTime(2026, 5, 1), minutes: 45);
    await seedSession(legs, DateTime(2026, 5, 8), minutes: 50);
    await pumpLog(tester);

    expect(find.text('Leg day'), findsOneWidget);
    expect(find.text('2 sessions · last 08.05.2026'), findsOneWidget);

    await tester.tap(find.text('Leg day'));
    await tester.pumpAndSettle();

    // Both sessions, newest first, each with its duration.
    expect(find.textContaining('08.05.2026'), findsOneWidget);
    expect(find.textContaining('01.05.2026'), findsOneWidget);

    await tester.tap(find.textContaining('08.05.2026'));
    await tester.pumpAndSettle();

    // The report sheet — the date as its heading, plus the duration line.
    expect(find.textContaining('Total duration'), findsOneWidget);
  });
}

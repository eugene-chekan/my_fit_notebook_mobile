import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_fit_notebook_mobile/l10n/app_localizations.dart';
import 'package:my_fit_notebook_mobile/theme/notebook_theme.dart';
import 'package:my_fit_notebook_mobile/widgets/schedule_options_dialog.dart';

/// Opens the dialog for [anchor] and records what it returns. `result` stays
/// null both when the user cancels and while the dialog is still open, so the
/// tests assert on `closed` too.
class _Harness {
  ScheduleOptions? result;
  bool closed = false;
}

Future<_Harness> _open(WidgetTester tester, DateTime anchor) async {
  final harness = _Harness();
  await tester.pumpWidget(
    MaterialApp(
      theme: NotebookTheme.forId(ThemeId.paper),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                harness.result = await showScheduleOptions(context, anchor: anchor);
                harness.closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return harness;
}

void main() {
  // A Wednesday, comfortably in the future so no weekday is disabled.
  final anchor = DateTime.now().add(const Duration(days: 30));

  testWidgets('cancelling returns nothing — it must never schedule',
      (tester) async {
    final harness = await _open(tester, anchor);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(harness.closed, isTrue);
    expect(harness.result, isNull);
  });

  testWidgets('the anchor day starts selected and saves as a one-off',
      (tester) async {
    final harness = await _open(tester, anchor);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(harness.result, isNotNull);
    expect(harness.result!.weekly, isFalse);
    expect(harness.result!.weekdays, {anchor.weekday});
    expect(harness.result!.time, isNull); // no reminder unless one is picked
  });

  testWidgets('the once/weekly slider switches the mode', (tester) async {
    final harness = await _open(tester, anchor);
    await tester.tap(find.text('weekly'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(harness.result!.weekly, isTrue);
  });

  testWidgets('up to seven days can be picked', (tester) async {
    final harness = await _open(tester, anchor);
    for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
      final chip = find.text(day);
      // Tapping the already-selected anchor day would clear it, so only add.
      if (day != _labelFor(anchor.weekday)) await tester.tap(chip);
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(harness.result!.weekdays, {1, 2, 3, 4, 5, 6, 7});
  });

  testWidgets('clearing every day disables Save', (tester) async {
    final harness = await _open(tester, anchor);
    // Deselect the anchor day, leaving nothing to book.
    await tester.tap(find.text(_labelFor(anchor.weekday)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(harness.closed, isFalse); // the dialog is still up
    expect(harness.result, isNull);
  });

  testWidgets('the options are on screen as soon as the dialog opens',
      (tester) async {
    // Bug: the calendar path used to show a bare time picker with no
    // recurrence choice at all.
    await _open(tester, anchor);
    expect(find.text('once'), findsOneWidget);
    expect(find.text('weekly'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);
    expect(find.text('no reminder'), findsOneWidget);
  });
}

String _labelFor(int weekday) => const {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    }[weekday]!;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_fit_notebook_mobile/l10n/app_localizations.dart';
import 'package:my_fit_notebook_mobile/theme/notebook_theme.dart';
import 'package:my_fit_notebook_mobile/widgets/pick_target_sheet.dart';

class _Harness {
  int? result;
  bool closed = false;
}

Future<_Harness> _open(
  WidgetTester tester, {
  required List<PickOption> options,
  String? createLabel,
  String? emptyMessage,
}) async {
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
                harness.result = await showPickTarget(
                  context,
                  title: 'Add to a program',
                  options: options,
                  createLabel: createLabel,
                  emptyMessage: emptyMessage,
                );
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
  const options = [
    PickOption(id: 7, label: 'Push / Pull / Legs', detail: '3 workouts'),
    PickOption(id: 9, label: 'Deload week', alreadyHas: true),
  ];

  testWidgets('picking a row returns its id', (tester) async {
    final harness = await _open(tester, options: options);
    await tester.tap(find.text('Push / Pull / Legs'));
    await tester.pumpAndSettle();

    expect(harness.result, 7);
  });

  testWidgets('a target it already belongs to says so in words', (tester) async {
    // A bare tick is ambiguous — it reads just as easily as "selected".
    await _open(tester, options: options);
    expect(find.text('already added'), findsOneWidget);
  });

  testWidgets('a target the item already belongs to is still tappable',
      (tester) async {
    // It answers "already in …" rather than sitting there as a dead row.
    final harness = await _open(tester, options: options);
    await tester.tap(find.text('Deload week'));
    await tester.pumpAndSettle();

    expect(harness.result, 9);
  });

  testWidgets('the create line returns the new-target sentinel', (tester) async {
    final harness = await _open(
      tester,
      options: options,
      createLabel: '+ new program…',
    );
    await tester.tap(find.text('+ new program…'));
    await tester.pumpAndSettle();

    expect(harness.result, newTargetId);
  });

  testWidgets('no create line means no way to conjure a target',
      (tester) async {
    await _open(tester, options: options);
    expect(find.text('+ new program…'), findsNothing);
  });

  testWidgets('an empty list shows the caller message', (tester) async {
    await _open(
      tester,
      options: const [],
      emptyMessage: 'No workouts yet — create one first.',
    );
    expect(find.text('No workouts yet — create one first.'), findsOneWidget);
  });

  testWidgets('dismissing returns nothing', (tester) async {
    final harness = await _open(tester, options: options);
    await tester.tapAt(const Offset(10, 10)); // outside the sheet
    await tester.pumpAndSettle();

    expect(harness.closed, isTrue);
    expect(harness.result, isNull);
  });
}

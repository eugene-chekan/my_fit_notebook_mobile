import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_fit_notebook_mobile/l10n/app_localizations.dart';
import 'package:my_fit_notebook_mobile/theme/notebook_theme.dart';
import 'package:my_fit_notebook_mobile/widgets/swipe_actions.dart';

Widget _host(Widget child) => MaterialApp(
      theme: NotebookTheme.forId(ThemeId.paper),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

Widget _row({
  Future<void> Function()? onCopy,
  required Future<bool> Function() onDelete,
}) =>
    _host(
      SwipeableRow(
        itemKey: const ValueKey('row'),
        onCopy: onCopy,
        onDelete: onDelete,
        child: const SizedBox(height: 40, child: Text('row')),
      ),
    );

void main() {
  testWidgets('swiping right copies and the row stays put', (tester) async {
    var copies = 0;
    await tester.pumpWidget(
      _row(onCopy: () async => copies++, onDelete: () async => true),
    );

    await tester.drag(find.text('row'), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(copies, 1);
    expect(find.text('row'), findsOneWidget); // the copy is a new row elsewhere
  });

  testWidgets('swiping left runs the delete', (tester) async {
    var deletes = 0;
    await tester.pumpWidget(
      _row(
        onCopy: () async {},
        onDelete: () async {
          deletes++;
          return false;
        },
      ),
    );

    await tester.drag(find.text('row'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(deletes, 1);
  });

  testWidgets('a delete that returns false snaps the row back', (tester) async {
    await tester.pumpWidget(_row(onDelete: () async => false));

    await tester.drag(find.text('row'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('row'), findsOneWidget);
  });

  testWidgets('without onCopy the row refuses to swipe right', (tester) async {
    var deletes = 0;
    await tester.pumpWidget(
      _row(
        onDelete: () async {
          deletes++;
          return false;
        },
      ),
    );

    await tester.drag(find.text('row'), const Offset(500, 0));
    await tester.pumpAndSettle();

    // A rightward drag on a delete-only row must do nothing at all — in
    // particular it must never fall through to the delete.
    expect(deletes, 0);
    expect(find.text('row'), findsOneWidget);
  });

  test('itemKey is the widget\'s own key, not just the Dismissible\'s', () {
    // A reorderable list keys off the child it is handed; keying only the
    // Dismissible inside leaves the outer widget unkeyed, which fails at
    // runtime (a grey error box where the list should be), not at compile time.
    const key = ValueKey('row');
    final row = SwipeableRow(
      itemKey: key,
      onDelete: () async => false,
      child: const SizedBox(),
    );
    expect(row.key, key);
  });

  testWidgets('the copy reveal only exists when copying is allowed',
      (tester) async {
    await tester.pumpWidget(_row(onDelete: () async => false));
    var dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
    expect(dismissible.direction, DismissDirection.endToStart);
    expect(dismissible.background, isA<SwipeDeleteBackground>());

    await tester.pumpWidget(
      _row(onCopy: () async {}, onDelete: () async => false),
    );
    dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
    expect(dismissible.direction, DismissDirection.horizontal);
    expect(dismissible.background, isA<SwipeCopyBackground>());
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_fit_notebook_mobile/l10n/app_localizations.dart';
import 'package:my_fit_notebook_mobile/theme/notebook_theme.dart';
import 'package:my_fit_notebook_mobile/widgets/notebook_drawer.dart';

Widget _app(Widget home) => MaterialApp(
      theme: NotebookTheme.forId(ThemeId.paper),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MarginMenuHost(child: child!),
      home: home,
    );

void main() {
  testWidgets('openMarginMenu reveals the nav items; a tap closes it',
      (tester) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => openMarginMenu(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Routines'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Menu items must be hittable — the masthead closes the menu (no navigation),
    // isolating that taps reach the panel's InkWells.
    await tester.tap(find.text('My fit notebook'));
    await tester.pumpAndSettle();
    expect(find.text('Routines'), findsNothing);
  });

  testWidgets('a left-edge drag pulls the menu open', (tester) async {
    await tester.pumpWidget(_app(const Scaffold(body: SizedBox.expand())));

    // Fling rightward from within the left-edge strip.
    await tester.flingFrom(const Offset(6, 300), const Offset(400, 0), 1200);
    await tester.pumpAndSettle();

    expect(find.text('Routines'), findsOneWidget);

    // Tapping the scrim closes it again.
    await tester.tapAt(const Offset(790, 300));
    await tester.pumpAndSettle();
    expect(find.text('Routines'), findsNothing);
  });
}

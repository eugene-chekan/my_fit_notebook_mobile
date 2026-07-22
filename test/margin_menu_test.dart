import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_fit_notebook_mobile/l10n/app_localizations.dart';
import 'package:my_fit_notebook_mobile/theme/notebook_theme.dart';
import 'package:my_fit_notebook_mobile/widgets/notebook_drawer.dart';
import 'package:my_fit_notebook_mobile/widgets/notebook_page.dart';

void main() {
  testWidgets('margin menu expands open and shows the nav items', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NotebookTheme.forId(ThemeId.paper),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
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

    // The panel built and revealed its content without layout errors.
    expect(find.text('Routines'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Tapping a menu item must be hittable and fire its onTap. The masthead
    // closes the menu (no DB-backed screen pushed), so it isolates the tap.
    await tester.tap(find.text('My fit notebook'));
    await tester.pumpAndSettle();
    expect(find.text('Routines'), findsNothing);
  });

  testWidgets('a left-edge swipe opens the menu', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NotebookTheme.forId(ThemeId.paper),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: NotebookPage(child: SizedBox(height: 100)),
        ),
      ),
    );

    // Drag rightward starting inside the left-edge strip.
    await tester.dragFrom(const Offset(6, 300), const Offset(140, 0));
    await tester.pumpAndSettle();

    expect(find.text('Routines'), findsOneWidget);
  });
}

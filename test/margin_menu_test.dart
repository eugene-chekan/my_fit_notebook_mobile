import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:my_fit_notebook_mobile/app_navigator.dart';
import 'package:my_fit_notebook_mobile/l10n/app_localizations.dart';
import 'package:my_fit_notebook_mobile/theme/notebook_theme.dart';
import 'package:my_fit_notebook_mobile/widgets/notebook_drawer.dart';

Widget _app(Widget home, {NavigatorObserver? observer}) => MaterialApp(
      theme: NotebookTheme.forId(ThemeId.paper),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MarginMenuHost(child: child!),
      // The panel sits above the Navigator, so it routes through the app-wide
      // key rather than an ancestor context — without it, taps go nowhere.
      navigatorKey: navigatorKey,
      navigatorObservers: [?observer],
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
    expect(find.text('Workouts'), findsOneWidget);
    // Settings, Profile and Stats are pen glyphs along the bottom now, so they
    // are found by the label a screen reader would read out, not by body text.
    expect(find.bySemanticsLabel('Settings'), findsOneWidget);
    expect(find.bySemanticsLabel('Profile'), findsOneWidget);
    expect(find.bySemanticsLabel('Stats'), findsOneWidget);

    // Menu items must be hittable — the masthead closes the menu (no navigation),
    // isolating that taps reach the panel's InkWells.
    await tester.tap(find.text('My fit notebook'));
    await tester.pumpAndSettle();
    expect(find.text('Workouts'), findsNothing);
  });

  testWidgets('a left-edge drag pulls the menu open', (tester) async {
    await tester.pumpWidget(_app(const Scaffold(body: SizedBox.expand())));

    // Fling rightward from within the left-edge strip.
    await tester.flingFrom(const Offset(6, 300), const Offset(400, 0), 1200);
    await tester.pumpAndSettle();

    expect(find.text('Workouts'), findsOneWidget);

    // Tapping the scrim closes it again.
    await tester.tapAt(const Offset(790, 300));
    await tester.pumpAndSettle();
    expect(find.text('Workouts'), findsNothing);
  });

  testWidgets('the bottom glyph row navigates', (tester) async {
    // Assert the push itself rather than the destination's contents: the
    // Settings page wants the app's root providers, which this harness has no
    // business standing up just to prove a glyph is wired.
    final pushes = <Route<dynamic>>[];
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
        observer: _RecordingObserver(pushes),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    pushes.clear(); // ignore the initial route

    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pump();

    expect(pushes, hasLength(1));
    // The Settings page then fails to build here for want of the app's root
    // providers. That is this harness's boundary, not a fault in the glyph —
    // consume it so the wiring assertion above is what the test reports on.
    expect(tester.takeException(), isA<ProviderNotFoundException>());
  });
}

class _RecordingObserver extends NavigatorObserver {
  _RecordingObserver(this.pushes);

  final List<Route<dynamic>> pushes;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      pushes.add(route);
}

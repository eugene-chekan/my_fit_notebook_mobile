import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_fit_notebook_mobile/l10n/app_localizations.dart';
import 'package:my_fit_notebook_mobile/theme/notebook_theme.dart';
import 'package:my_fit_notebook_mobile/widgets/tip_note.dart';

const _tip = 'swipe left to delete · tap to edit';

Widget _host(Widget child) => MaterialApp(
      theme: NotebookTheme.forId(ThemeId.paper),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('the tip stays out of the way until asked for', (tester) async {
    await tester.pumpWidget(_host(const TipNoteButton(text: _tip)));

    expect(find.text(_tip), findsNothing);
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('tapping the glyph tears off the note', (tester) async {
    await tester.pumpWidget(_host(const TipNoteButton(text: _tip)));

    await tester.tap(find.text('?'));
    await tester.pumpAndSettle();

    expect(find.text(_tip), findsOneWidget);
  });

  testWidgets('the note dismisses again', (tester) async {
    await tester.pumpWidget(_host(const TipNoteButton(text: _tip)));
    await tester.tap(find.text('?'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.text(_tip), findsNothing);
  });

  testWidgets('the glyph is announced for screen readers', (tester) async {
    // The button's own label merges with its "?" glyph, so match within.
    await tester.pumpWidget(_host(const TipNoteButton(text: _tip)));
    expect(find.bySemanticsLabel(RegExp('Show the tip')), findsOneWidget);
  });
}

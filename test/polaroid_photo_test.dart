import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_fit_notebook_mobile/theme/notebook_theme.dart';
import 'package:my_fit_notebook_mobile/widgets/notebook_page.dart';
import 'package:my_fit_notebook_mobile/widgets/polaroid_photo.dart';

Widget _host(Widget child, {ThemeId theme = ThemeId.paper}) => MaterialApp(
      theme: NotebookTheme.forId(theme),
      home: Scaffold(body: Center(child: child)),
    );

/// The resolved stock (card) colour of the rendered print.
Color _stockOf(WidgetTester tester) {
  final card = tester.widget<Container>(find.byKey(PolaroidPhoto.cardKey));
  return (card.decoration as BoxDecoration).color!;
}

void main() {
  testWidgets('shows the caption on the chin', (tester) async {
    await tester.pumpWidget(
      _host(
        PolaroidPhoto(
          caption: 'Eugene',
          semanticLabel: 'Profile photo',
          onTap: () {},
        ),
      ),
    );
    expect(find.text('Eugene'), findsOneWidget);
  });

  testWidgets('a blank caption leaves the chin empty', (tester) async {
    await tester.pumpWidget(
      _host(
        PolaroidPhoto(
          caption: '   ',
          semanticLabel: 'Profile photo',
          onTap: () {},
        ),
      ),
    );
    expect(find.text('   '), findsNothing);
  });

  testWidgets('with no photo it draws the ink placeholder, not an Image',
      (tester) async {
    await tester.pumpWidget(
      _host(PolaroidPhoto(semanticLabel: 'Profile photo', onTap: () {})),
    );
    expect(find.byType(Image), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets); // the placeholder bust
  });

  testWidgets('a missing photo file falls back to the placeholder',
      (tester) async {
    await tester.pumpWidget(
      _host(
        PolaroidPhoto(
          photo: File('/definitely/not/a/real/photo.jpg'),
          semanticLabel: 'Profile photo',
          onTap: () {},
        ),
      ),
    );
    await tester.pump();
    // Image.file's errorBuilder swaps in the bust rather than throwing.
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the print fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        PolaroidPhoto(
          semanticLabel: 'Profile photo',
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.byType(PolaroidPhoto));
    expect(taps, 1);
  });

  testWidgets('the print stays short enough to clear the fields below it',
      (tester) async {
    // The Profile screen tapes the print over the header + "About me" heading +
    // name row, and relies on it being no taller than that block so it can
    // never cover the born/height fields underneath. The block's budget is
    // 2 ruled lines (header) + 8 + 1 ruled line (heading) + 6 = 122pt, plus the
    // name row the print may overlap — a dense Caveat-20 field runs ~38pt, so
    // only bank a conservative 30pt of it.
    const budget = 3 * kNotebookLine + 14 + 30;
    await tester.pumpWidget(
      _host(PolaroidPhoto(semanticLabel: 'Profile photo', onTap: () {})),
    );
    final height = tester.getSize(find.byType(PolaroidPhoto)).height;
    expect(height, lessThan(budget));
  });

  testWidgets('on a light theme the stock stays warm photo-paper white',
      (tester) async {
    await tester.pumpWidget(
      _host(PolaroidPhoto(semanticLabel: 'Profile photo', onTap: () {})),
    );
    expect(_stockOf(tester), const Color(0xFFFCFAF3));
  });

  group('on the dark themes the stock is exposed for the room', () {
    // A white card on these grounds is a floodlight — near 0.96 luminance where
    // the page's own ink tops out around 0.53. The stock must dim to sit just
    // above that ink: still the lightest paper on the page, no longer glowing.
    for (final (id, palette) in [
      (ThemeId.blueprint, NotebookTheme.blueprint),
      (ThemeId.chalkboard, NotebookTheme.chalkboard),
      (ThemeId.lamp, NotebookTheme.lamp),
      (ThemeId.carbon, NotebookTheme.carbon),
    ]) {
      testWidgets(id.name, (tester) async {
        await tester.pumpWidget(
          _host(
            PolaroidPhoto(semanticLabel: 'Profile photo', onTap: () {}),
            theme: id,
          ),
        );
        final stock = _stockOf(tester);
        final inkLuminance = palette.ink.computeLuminance();

        expect(stock, isNot(const Color(0xFFFCFAF3)));
        // Brighter than the page's ink, so it still reads as paper…
        expect(stock.computeLuminance(), greaterThan(inkLuminance));
        // …but nowhere near the daylight white it replaces.
        expect(stock.computeLuminance(), lessThan(0.75));
        // Hue-matched to the page rather than an imported warm white: the
        // stock's channel spread tracks the theme's own ink.
        expect((stock.r - stock.b).sign, (palette.ink.r - palette.ink.b).sign);
      });
    }
  });

  testWidgets('the dark stock keeps the caption legible against it',
      (tester) async {
    await tester.pumpWidget(
      _host(
        PolaroidPhoto(
          caption: 'Eugene',
          semanticLabel: 'Profile photo',
          onTap: () {},
        ),
        theme: ThemeId.blueprint,
      ),
    );
    final caption = tester.widget<Text>(find.text('Eugene'));
    final stock = _stockOf(tester);
    final contrast =
        (stock.computeLuminance() - caption.style!.color!.computeLuminance()).abs();
    expect(contrast, greaterThan(0.4));
  });
}

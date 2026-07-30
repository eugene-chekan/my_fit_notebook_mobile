import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_fit_notebook_mobile/theme/notebook_theme.dart';
import 'package:my_fit_notebook_mobile/widgets/notebook_page.dart';

/// Every row in the app is a fixed-height box sized to the ruling, so the text
/// size and the ruled grid have to move together. These pin that relationship
/// down: scale the type alone and words overflow their line, scale the ruling
/// alone and the writing floats off it.
void main() {
  group('FontScale', () {
    test('normal leaves the device scale exactly as it was', () {
      final scaler = FontScale.normal.applyTo(TextScaler.noScaling);
      expect(scaler.scale(20), 20);
    });

    test('small and large move the type either side of normal', () {
      expect(
        FontScale.small.applyTo(TextScaler.noScaling).scale(20),
        lessThan(20),
      );
      expect(
        FontScale.large.applyTo(TextScaler.noScaling).scale(20),
        greaterThan(20),
      );
    });

    test('it multiplies the device scale rather than replacing it', () {
      // A reader who already turned the system font up keeps that; the app's
      // own preference nudges from there.
      final device = TextScaler.linear(1.2);
      expect(
        FontScale.large.applyTo(device).scale(20),
        greaterThan(device.scale(20)),
      );
      expect(
        FontScale.small.applyTo(device).scale(20),
        greaterThan(FontScale.small.applyTo(TextScaler.noScaling).scale(20)),
      );
    });

    test('the combined scale is capped so the fixed page furniture holds', () {
      final huge = FontScale.large.applyTo(TextScaler.linear(4));
      expect(huge.scale(20), 20 * kMaxTextScale);
    });

    test('a tiny device scale is floored the same way', () {
      final tiny = FontScale.small.applyTo(TextScaler.linear(0.2));
      expect(tiny.scale(20), 20 * kMinTextScale);
    });

    test('unknown persisted names fall back to normal', () {
      expect(FontScale.fromName('gigantic'), FontScale.normal);
      expect(FontScale.fromName(null), FontScale.normal);
      expect(FontScale.fromName('large'), FontScale.large);
    });
  });

  group('the ruled grid', () {
    /// Renders a page under [scaler] and reports the line pitch it laid out at.
    Future<double> lineUnder(WidgetTester tester, TextScaler scaler) async {
      late double line;
      await tester.pumpWidget(
        MaterialApp(
          theme: NotebookTheme.forId(ThemeId.paper),
          home: MediaQuery(
            data: MediaQueryData(textScaler: scaler),
            child: Builder(
              builder: (context) {
                line = notebookLine(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      return line;
    }

    testWidgets('sits at the base pitch when nothing is scaling',
        (tester) async {
      expect(await lineUnder(tester, TextScaler.noScaling), kNotebookLine);
    });

    testWidgets('grows and shrinks with the chosen text size', (tester) async {
      final small = await lineUnder(
        tester,
        FontScale.small.applyTo(TextScaler.noScaling),
      );
      final large = await lineUnder(
        tester,
        FontScale.large.applyTo(TextScaler.noScaling),
      );

      expect(small, lessThan(kNotebookLine));
      expect(large, greaterThan(kNotebookLine));
    });

    testWidgets('a heading row is exactly one ruled line tall at every size',
        (tester) async {
      for (final scale in FontScale.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: NotebookTheme.forId(ThemeId.paper),
            home: MediaQuery(
              data: MediaQueryData(
                textScaler: scale.applyTo(TextScaler.noScaling),
              ),
              // Centred so the row takes its natural height rather than
              // being stretched to fill the window.
              child: const Directionality(
                textDirection: TextDirection.ltr,
                child: Center(child: HeadingLine('Logged sessions')),
              ),
            ),
          ),
        );
        final box = tester.getSize(find.byType(HeadingLine));
        expect(
          box.height,
          kNotebookLine * scale.factor,
          reason: 'the ${scale.name} heading left the grid',
        );
      }
    });
  });
}

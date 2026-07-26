import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_fit_notebook_mobile/theme/notebook_theme.dart';
import 'package:my_fit_notebook_mobile/widgets/notebook_page.dart';
import 'package:my_fit_notebook_mobile/widgets/polaroid_photo.dart';

Widget _host(Widget child) => MaterialApp(
      theme: NotebookTheme.forId(ThemeId.paper),
      home: Scaffold(body: Center(child: child)),
    );

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
}

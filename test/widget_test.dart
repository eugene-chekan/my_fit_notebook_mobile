import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_fit_notebook_mobile/theme/notebook_theme.dart';
import 'package:my_fit_notebook_mobile/widgets/pen_button.dart';

void main() {
  testWidgets('PenButton renders its label and responds to taps', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: NotebookTheme.forId(ThemeId.paper),
        home: Scaffold(
          body: PenButton(label: 'Start workout', onPressed: () => tapped = true),
        ),
      ),
    );

    expect(find.text('Start workout'), findsOneWidget);

    await tester.tap(find.text('Start workout'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}

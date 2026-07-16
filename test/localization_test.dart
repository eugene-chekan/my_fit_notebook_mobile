import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_fit_notebook_mobile/l10n/app_localizations.dart';

Future<AppLocalizations> _load(WidgetTester tester, Locale locale) async {
  late AppLocalizations t;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          t = AppLocalizations.of(context);
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pump();
  return t;
}

void main() {
  testWidgets('English strings and plurals resolve', (tester) async {
    final t = await _load(tester, const Locale('en'));
    expect(t.navRoutines, 'Routines');
    expect(t.workoutsCount(1), '1 workout');
    expect(t.workoutsCount(3), '3 workouts');
    expect(t.ageYears(1), '(1 year)');
  });

  testWidgets('Russian strings resolve with one/few/many plural forms', (tester) async {
    final t = await _load(tester, const Locale('ru'));
    expect(t.navRoutines, 'Тренировки');
    // Russian plural categories: 1 → one, 2–4 → few, 5+ → many.
    expect(t.workoutsCount(1), '1 тренировка');
    expect(t.workoutsCount(2), '2 тренировки');
    expect(t.workoutsCount(5), '5 тренировок');
    expect(t.ageYears(5), '(5 лет)');
  });
}

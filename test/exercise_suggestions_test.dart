import 'package:flutter_test/flutter_test.dart';
import 'package:my_fit_notebook_mobile/utils/exercise_suggestions.dart';

void main() {
  const catalog = ['Bench Press', 'Barbell Row', 'Squat', 'Overhead Press'];

  test('empty query yields no suggestions', () {
    expect(
      filterExerciseSuggestions(query: '  ', catalog: catalog, existing: const []),
      isEmpty,
    );
  });

  test('case-insensitive substring match', () {
    expect(
      filterExerciseSuggestions(query: 'press', catalog: catalog, existing: const []),
      ['Bench Press', 'Overhead Press'],
    );
  });

  test('prefix matches come before mid-string matches', () {
    expect(
      filterExerciseSuggestions(query: 'ba', catalog: catalog, existing: const []),
      ['Barbell Row'],
    );
    // "b" is a prefix of Barbell/Bench and mid-string in nothing here.
    expect(
      filterExerciseSuggestions(query: 'b', catalog: catalog, existing: const []),
      ['Bench Press', 'Barbell Row'],
    );
  });

  test('excludes names already in the routine (case-insensitive)', () {
    expect(
      filterExerciseSuggestions(
        query: 'press',
        catalog: catalog,
        existing: const ['bench press'],
      ),
      ['Overhead Press'],
    );
  });

  test('does not suggest an exact full match of the query', () {
    expect(
      filterExerciseSuggestions(query: 'squat', catalog: catalog, existing: const []),
      isEmpty,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:my_fit_notebook_mobile/utils/recurrence.dart';

void main() {
  group('weeklyOccurrences', () {
    test('yields every matching weekday in range, in order', () {
      // 2026-07-20 is a Monday. Mon/Wed/Fri = {1,3,5}.
      final dates = weeklyOccurrences(
        weekdays: {1, 3, 5},
        from: DateTime(2026, 7, 20),
        to: DateTime(2026, 7, 26), // through Sunday
      );
      expect(dates, [
        DateTime(2026, 7, 20), // Mon
        DateTime(2026, 7, 22), // Wed
        DateTime(2026, 7, 24), // Fri
      ]);
    });

    test('spans multiple weeks', () {
      final dates = weeklyOccurrences(
        weekdays: {1}, // Mondays
        from: DateTime(2026, 7, 20),
        to: DateTime(2026, 8, 3),
      );
      expect(dates, [
        DateTime(2026, 7, 20),
        DateTime(2026, 7, 27),
        DateTime(2026, 8, 3),
      ]);
    });

    test('includes both bounds when they match', () {
      final dates = weeklyOccurrences(
        weekdays: {1, 2, 3, 4, 5, 6, 7},
        from: DateTime(2026, 7, 20),
        to: DateTime(2026, 7, 20),
      );
      expect(dates, [DateTime(2026, 7, 20)]);
    });

    test('ignores time-of-day on the bounds', () {
      final dates = weeklyOccurrences(
        weekdays: {5}, // Friday
        from: DateTime(2026, 7, 24, 23, 59),
        to: DateTime(2026, 7, 24, 0, 1),
      );
      expect(dates, [DateTime(2026, 7, 24)]);
    });

    test('empty weekdays yields nothing', () {
      expect(
        weeklyOccurrences(
          weekdays: {},
          from: DateTime(2026, 7, 20),
          to: DateTime(2026, 8, 20),
        ),
        isEmpty,
      );
    });

    test('inverted range yields nothing', () {
      expect(
        weeklyOccurrences(
          weekdays: {1, 2, 3},
          from: DateTime(2026, 7, 27),
          to: DateTime(2026, 7, 20),
        ),
        isEmpty,
      );
    });
  });

  group('startOfWeek', () {
    test('a Monday is its own week start', () {
      expect(startOfWeek(DateTime(2026, 7, 20)), DateTime(2026, 7, 20));
    });

    test('a Sunday rolls back to the Monday before it', () {
      expect(startOfWeek(DateTime(2026, 7, 26)), DateTime(2026, 7, 20));
    });

    test('rolls back across a month boundary', () {
      // 2026-08-02 is a Sunday; its week starts Mon 2026-07-27.
      expect(startOfWeek(DateTime(2026, 8, 2)), DateTime(2026, 7, 27));
    });

    test('ignores time of day', () {
      expect(startOfWeek(DateTime(2026, 7, 22, 23, 30)), DateTime(2026, 7, 20));
    });
  });

  group('weekOccurrences', () {
    test('books the chosen weekdays inside the anchor week only', () {
      final dates = weekOccurrences(
        anchor: DateTime(2026, 7, 22), // Wednesday
        weekdays: {1, 3, 6}, // Mon, Wed, Sat
      );
      expect(dates, [
        DateTime(2026, 7, 20),
        DateTime(2026, 7, 22),
        DateTime(2026, 7, 25),
      ]);
    });

    test('drops days that have already passed', () {
      final dates = weekOccurrences(
        anchor: DateTime(2026, 7, 22), // Wednesday
        weekdays: {1, 3, 6}, // Monday has gone by
        notBefore: DateTime(2026, 7, 22),
      );
      expect(dates, [DateTime(2026, 7, 22), DateTime(2026, 7, 25)]);
    });

    test('keeps the whole week when the anchor is a future one', () {
      final dates = weekOccurrences(
        anchor: DateTime(2026, 8, 5), // Wednesday, a fortnight out
        weekdays: {1, 7},
        notBefore: DateTime(2026, 7, 22),
      );
      expect(dates, [DateTime(2026, 8, 3), DateTime(2026, 8, 9)]);
    });

    test('an anchor week entirely in the past yields nothing', () {
      final dates = weekOccurrences(
        anchor: DateTime(2026, 7, 8),
        weekdays: {1, 2, 3, 4, 5, 6, 7},
        notBefore: DateTime(2026, 7, 22),
      );
      expect(dates, isEmpty);
    });

    test('no weekdays selected yields nothing', () {
      expect(
        weekOccurrences(anchor: DateTime(2026, 7, 22), weekdays: {}),
        isEmpty,
      );
    });
  });

  group('parse / encode weekdays', () {
    test('round-trips a set to CSV and back', () {
      expect(encodeWeekdays({5, 1, 3}), '1,3,5');
      expect(parseWeekdays('1,3,5'), {1, 3, 5});
    });

    test('encode sorts ascending and drops out-of-range', () {
      expect(encodeWeekdays({7, 1, 9, 0}), '1,7');
    });

    test('parse drops junk and out-of-range values', () {
      expect(parseWeekdays('1, x, 8, 3 '), {1, 3});
    });

    test('parse of an empty string is empty', () {
      expect(parseWeekdays(''), isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:my_fit_notebook_mobile/data/models/completion.dart';
import 'package:my_fit_notebook_mobile/data/models/profile.dart';
import 'package:my_fit_notebook_mobile/utils/stats_math.dart';

Completion _c(String date, {int? minutes}) =>
    Completion(id: 1, routineId: 1, completedOn: date, durationMinutes: minutes);

void main() {
  // 2026-07-14 is a Tuesday; the Monday of its week is 2026-07-13.
  final today = DateTime(2026, 7, 14);

  group('weeklyMinutes', () {
    test('buckets are Monday-anchored, oldest first, current week last', () {
      final buckets = weeklyMinutes([], weeks: 3, today: today);
      expect(buckets.map((b) => b.weekStart).toList(), [
        DateTime(2026, 6, 29),
        DateTime(2026, 7, 6),
        DateTime(2026, 7, 13),
      ]);
    });

    test('empty weeks stay zero; a week sums its workouts and minutes', () {
      final buckets = weeklyMinutes(
        [
          _c('2026-07-14T18:00', minutes: 30), // current week
          _c('2026-07-13', minutes: 20), // current week (Monday)
          _c('2026-07-06', minutes: 45), // middle week
          _c('2026-06-20', minutes: 99), // before the window — ignored
        ],
        weeks: 3,
        today: today,
      );
      expect(buckets[0].workouts, 0);
      expect(buckets[0].minutes, 0);
      expect(buckets[1].workouts, 1);
      expect(buckets[1].minutes, 45);
      expect(buckets[2].workouts, 2);
      expect(buckets[2].minutes, 50);
    });

    test('null duration counts as a workout with zero minutes', () {
      final buckets = weeklyMinutes([_c('2026-07-14')], weeks: 1, today: today);
      expect(buckets.single.workouts, 1);
      expect(buckets.single.minutes, 0);
    });
  });

  group('periodTotals', () {
    final data = [
      _c('2026-06-30', minutes: 10), // just before July
      _c('2026-07-01', minutes: 20),
      _c('2026-07-31T20:00', minutes: 30),
      _c('2026-08-01', minutes: 40), // just after July
    ];

    test('from is inclusive, toExclusive is exclusive', () {
      final july = periodTotals(data, DateTime(2026, 7, 1), DateTime(2026, 8, 1));
      expect(july.workouts, 2);
      expect(july.minutes, 50);
    });

    test('empty range yields zeroes', () {
      final none = periodTotals(data, DateTime(2026, 9, 1), DateTime(2026, 10, 1));
      expect(none.workouts, 0);
      expect(none.minutes, 0);
    });
  });

  group('averageMinutes', () {
    test('averages only completions that recorded a duration', () {
      expect(
        averageMinutes([_c('2026-07-01', minutes: 30), _c('2026-07-02'), _c('2026-07-03', minutes: 20)]),
        25,
      );
    });

    test('null when nothing has a duration', () {
      expect(averageMinutes([]), isNull);
      expect(averageMinutes([_c('2026-07-01'), _c('2026-07-02')]), isNull);
    });
  });

  _weightAverageTests();
}

/// A weight reading on [iso].
Measurement _w(String iso, double kg) =>
    Measurement(id: 0, metric: 'weight', value: kg, measuredOn: iso);

void _weightAverageTests() {
  // Wednesday. A 7-day window is 2026-07-16 … 2026-07-22.
  final today = DateTime(2026, 7, 22);

  group('weightAverage', () {
    test('averages the readings inside the window', () {
      final avg = weightAverage(
        [_w('2026-07-20', 86), _w('2026-07-21', 87), _w('2026-07-22', 88)],
        today: today,
      )!;
      expect(avg.mean, 87);
      expect(avg.days, 3);
      expect(avg.window, 7);
    });

    test('two readings on one day count as one day', () {
      // Morning and evening on the same date: the day contributes their mean,
      // not two separate samples pulling the average toward that day.
      final avg = weightAverage(
        [_w('2026-07-21', 80), _w('2026-07-21', 90), _w('2026-07-22', 100)],
        today: today,
      )!;
      expect(avg.days, 2);
      expect(avg.mean, 92.5); // (85 + 100) / 2, not (80+90+100)/3
    });

    test('ignores readings older than the window', () {
      final avg = weightAverage(
        [
          _w('2026-07-15', 50), // one day before the window opens
          _w('2026-07-16', 86),
          _w('2026-07-22', 88),
        ],
        today: today,
      )!;
      expect(avg.days, 2);
      expect(avg.mean, 87);
    });

    test('the window includes today and the six days before it', () {
      final avg = weightAverage(
        [_w('2026-07-16', 80), _w('2026-07-22', 90)],
        today: today,
      )!;
      expect(avg.days, 2);
    });

    test('null below the minimum number of days', () {
      expect(weightAverage([_w('2026-07-22', 88)], today: today), isNull);
      expect(weightAverage([], today: today), isNull);
    });

    test('compares against the window immediately before', () {
      final avg = weightAverage(
        [
          // Previous window: 2026-07-09 … 2026-07-15.
          _w('2026-07-10', 90), _w('2026-07-14', 90),
          // Current window.
          _w('2026-07-20', 88), _w('2026-07-22', 88),
        ],
        today: today,
      )!;
      expect(avg.previousMean, 90);
      expect(avg.delta, -2);
    });

    test('no delta when the previous window is too sparse', () {
      final avg = weightAverage(
        [_w('2026-07-14', 90), _w('2026-07-20', 88), _w('2026-07-22', 88)],
        today: today,
      )!;
      expect(avg.previousMean, isNull);
      expect(avg.delta, isNull);
    });

    test('a malformed date is skipped rather than throwing', () {
      final avg = weightAverage(
        [_w('not-a-date', 999), _w('2026-07-21', 86), _w('2026-07-22', 88)],
        today: today,
      )!;
      expect(avg.days, 2);
      expect(avg.mean, 87);
    });
  });

}

import 'package:flutter_test/flutter_test.dart';
import 'package:my_fit_notebook_mobile/data/models/completion.dart';
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

  group('bmi', () {
    test('computes a known value', () {
      expect(bmi(72, 180), closeTo(22.22, 0.01));
    });

    test('null when weight or height is missing or non-positive', () {
      expect(bmi(null, 180), isNull);
      expect(bmi(72, null), isNull);
      expect(bmi(0, 180), isNull);
      expect(bmi(72, 0), isNull);
    });
  });
}

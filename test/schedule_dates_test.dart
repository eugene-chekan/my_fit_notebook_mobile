import 'package:flutter_test/flutter_test.dart';
import 'package:my_fit_notebook_mobile/utils/schedule_dates.dart';

void main() {
  final today = DateTime(2026, 7, 17);

  group('scheduleDayKind', () {
    test('same date is today', () {
      expect(scheduleDayKind('2026-07-17', today), ScheduleDayKind.today);
    });

    test('next day is tomorrow', () {
      expect(scheduleDayKind('2026-07-18', today), ScheduleDayKind.tomorrow);
    });

    test('two-plus days out is later', () {
      expect(scheduleDayKind('2026-07-25', today), ScheduleDayKind.later);
    });

    test('a past date folds into today', () {
      expect(scheduleDayKind('2026-07-10', today), ScheduleDayKind.today);
    });

    test('time-of-day on today is ignored', () {
      expect(
        scheduleDayKind('2026-07-18', DateTime(2026, 7, 17, 23, 59)),
        ScheduleDayKind.tomorrow,
      );
    });

    test('a malformed date is treated as later', () {
      expect(scheduleDayKind('not-a-date', today), ScheduleDayKind.later);
    });
  });
}

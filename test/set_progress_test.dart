import 'package:flutter_test/flutter_test.dart';
import 'package:my_fit_notebook_mobile/data/models/exercise_set.dart';
import 'package:my_fit_notebook_mobile/utils/set_progress.dart';

ExerciseSet _set(int index, {bool done = false}) =>
    ExerciseSet(id: index, exerciseId: 1, setIndex: index, isDone: done);

void main() {
  group('prefillReps', () {
    test('single value uses reps_min', () {
      expect(prefillReps(10, null), 10);
    });

    test('range uses the top (reps_max)', () {
      expect(prefillReps(10, 12), 12);
    });

    test('null when no reps prescribed', () {
      expect(prefillReps(null, null), isNull);
    });
  });

  group('setProgress', () {
    test('counts done vs total', () {
      final sets = [_set(1, done: true), _set(2), _set(3, done: true)];
      final p = setProgress(sets);
      expect(p.done, 2);
      expect(p.total, 3);
    });

    test('empty list is 0/0', () {
      final p = setProgress(const []);
      expect(p.done, 0);
      expect(p.total, 0);
    });
  });

  group('allSetsDone', () {
    test('false when empty', () {
      expect(allSetsDone(const []), isFalse);
    });

    test('false when only some are done', () {
      expect(allSetsDone([_set(1, done: true), _set(2)]), isFalse);
    });

    test('true when every set is done', () {
      expect(allSetsDone([_set(1, done: true), _set(2, done: true)]), isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:my_fit_notebook_mobile/data/models/exercise.dart';
import 'package:my_fit_notebook_mobile/data/models/exercise_set.dart';
import 'package:my_fit_notebook_mobile/utils/set_progress.dart';

ExerciseSet _set(int index, {bool done = false}) =>
    ExerciseSet(id: index, exerciseId: 1, setIndex: index, isDone: done);

Exercise _exercise(int id, {bool done = false}) => Exercise(
  id: id,
  routineId: 1,
  name: 'ex$id',
  sortOrder: id,
  isDone: done,
);

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

  group('exerciseCompletion', () {
    test('empty routine is 0/0', () {
      final p = exerciseCompletion(const [], const {});
      expect(p.done, 0);
      expect(p.total, 0);
    });

    test('bare exercises count by their own checkbox', () {
      final exercises = [_exercise(1, done: true), _exercise(2)];
      final p = exerciseCompletion(exercises, const {});
      expect(p.done, 1);
      expect(p.total, 2);
    });

    test('a prescribed exercise is done only when all its sets are done', () {
      final exercises = [_exercise(1), _exercise(2)];
      final sets = {
        1: [_set(1, done: true), _set(2, done: true)], // fully done
        2: [_set(1, done: true), _set(2)], // partial
      };
      final p = exerciseCompletion(exercises, sets);
      expect(p.done, 1);
      expect(p.total, 2);
    });

    test('a prescribed exercise ignores the bare is_done flag', () {
      // isDone is true but not all sets are checked → not complete.
      final exercises = [_exercise(1, done: true)];
      final sets = {
        1: [_set(1, done: true), _set(2)],
      };
      final p = exerciseCompletion(exercises, sets);
      expect(p.done, 0);
      expect(p.total, 1);
    });
  });
}

import '../models/completion.dart';
import '../models/routine.dart';
import '../repositories/completion_repository.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/routine_repository.dart';

/// Workout lifecycle: start, pause, resume, finish — a Dart port of
/// services/workout_service.py, kept as pure functions plus a thin
/// orchestration layer so the timer math stays identical to the web app.
class WorkoutService {
  WorkoutService({
    RoutineRepository? routines,
    ExerciseRepository? exercises,
    CompletionRepository? completions,
  }) : _routines = routines ?? RoutineRepository(),
       _exercises = exercises ?? ExerciseRepository(),
       _completions = completions ?? CompletionRepository();

  final RoutineRepository _routines;
  final ExerciseRepository _exercises;
  final CompletionRepository _completions;

  /// Total paused seconds, including an in-progress pause.
  static int calculatePausedSeconds(Routine routine) {
    var paused = routine.pausedSeconds;
    final pausedAt = routine.pausedAt;
    if (pausedAt != null) {
      try {
        paused += DateTime.now().difference(DateTime.parse(pausedAt)).inSeconds;
      } catch (_) {
        // ignore malformed timestamp, mirrors the Python contextlib.suppress
      }
    }
    return paused;
  }

  /// Net active workout duration in minutes from start, end, and pause total.
  static int calculateDurationMinutes(
    String startedAt,
    DateTime completedOn,
    int pausedSeconds,
  ) {
    try {
      final start = DateTime.parse(startedAt);
      final totalSeconds = completedOn.difference(start).inSeconds;
      final net = totalSeconds - pausedSeconds;
      return (net < 0 ? 0 : net) ~/ 60;
    } catch (_) {
      return 0;
    }
  }

  /// Net active workout duration in seconds, as of now.
  static int calculateDurationSeconds(Routine routine) {
    final startedAt = routine.startedAt;
    if (startedAt == null) return 0;
    final paused = calculatePausedSeconds(routine);
    final minutes = calculateDurationMinutes(startedAt, DateTime.now(), paused);
    return minutes * 60;
  }

  /// Net workout duration in minutes, or null if not started.
  static int? calculateWorkoutDuration(Routine routine) {
    final startedAt = routine.startedAt;
    if (startedAt == null) return null;
    return calculateDurationMinutes(
      startedAt,
      DateTime.now(),
      calculatePausedSeconds(routine),
    );
  }

  /// Starts (or restarts) a workout: clears exercise checkmarks and stamps
  /// `started_at`. Mirrors `reset_workout` in the Python service — the name
  /// there refers to resetting exercise state, not the timer.
  Future<void> startWorkout(int routineId) async {
    await _exercises.resetExercises(routineId);
    await _routines.setStartedAt(routineId, DateTime.now());
  }

  Future<Routine?> pauseWorkout(int routineId) async {
    await _routines.pauseRoutine(routineId);
    return _routines.getRoutine(routineId);
  }

  Future<Routine?> resumeWorkout(int routineId) async {
    await _routines.resumeRoutine(routineId);
    return _routines.getRoutine(routineId);
  }

  /// Records completion, resets exercises, clears the timer, and returns
  /// session statistics.
  Future<WorkoutStatistics> finishWorkout(int routineId) async {
    final routine = await _routines.getRoutine(routineId);
    if (routine == null) {
      throw StateError('Routine $routineId not found');
    }
    // Already finished (e.g. from the notification, then again from a stale
    // screen): there's no live session, so don't log an empty completion.
    if (!routine.isStarted) {
      return const WorkoutStatistics(
        exercisesCompleted: 0,
        durationSeconds: 0,
        pausedSeconds: 0,
      );
    }
    final exercises = await _exercises.listExercises(routineId);
    final (setsCompleted, repsTotal) = await _exercises.doneSetStats(routineId);
    final stats = WorkoutStatistics(
      exercisesCompleted: exercises.where((e) => e.isDone).length,
      durationSeconds: calculateDurationSeconds(routine),
      pausedSeconds: calculatePausedSeconds(routine),
      setsCompleted: setsCompleted,
      repsTotal: repsTotal,
    );
    final finishedAt = DateTime.now();
    final pausedSeconds = calculatePausedSeconds(routine);
    final durationMinutes = calculateWorkoutDuration(routine);
    // Record the completion first so its id can anchor the per-set snapshot;
    // snapshot the done sets before resetting them.
    final completionId = await _completions.addCompletionReturningId(
      routineId,
      finishedAt,
      durationMinutes: durationMinutes,
      startedAt: routine.startedAt,
      pausedSeconds: routine.startedAt != null ? pausedSeconds : null,
      exercisesCompleted: stats.exercisesCompleted,
      setsCompleted: stats.setsCompleted,
      repsTotal: stats.repsTotal,
    );
    if (completionId != null) {
      await _exercises.snapshotDoneSets(routineId, completionId);
    }
    await _exercises.resetExercises(routineId);
    await _routines.clearStartedAt(routineId);
    return stats;
  }
}

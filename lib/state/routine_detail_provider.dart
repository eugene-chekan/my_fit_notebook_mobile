import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/completion.dart';
import '../data/models/exercise.dart';
import '../data/models/routine.dart';
import '../data/repositories/completion_repository.dart';
import '../data/repositories/exercise_repository.dart';
import '../data/repositories/routine_repository.dart';
import '../data/services/workout_service.dart';

/// Backs the routine / workout screen: the routine itself, its exercises,
/// its completion history, and a 1s ticker so the elapsed-time label keeps
/// moving while a workout is running (mirrors the pulsing dot in the web UI).
class RoutineDetailProvider extends ChangeNotifier {
  RoutineDetailProvider(
    this.routineId, {
    RoutineRepository? routineRepository,
    ExerciseRepository? exerciseRepository,
    CompletionRepository? completionRepository,
    WorkoutService? workoutService,
  }) : _routineRepository = routineRepository ?? RoutineRepository(),
       _exerciseRepository = exerciseRepository ?? ExerciseRepository(),
       _completionRepository = completionRepository ?? CompletionRepository(),
       _workoutService = workoutService ?? WorkoutService();

  final int routineId;
  final RoutineRepository _routineRepository;
  final ExerciseRepository _exerciseRepository;
  final CompletionRepository _completionRepository;
  final WorkoutService _workoutService;

  Routine? routine;
  List<Exercise> exercises = [];
  List<Completion> completions = [];
  bool loading = true;
  Timer? _ticker;

  Future<void> load() async {
    routine = await _routineRepository.getRoutine(routineId);
    exercises = await _exerciseRepository.listExercises(routineId);
    completions = await _completionRepository.listForRoutine(routineId);
    loading = false;
    _syncTicker();
    notifyListeners();
  }

  void _syncTicker() {
    final r = routine;
    final shouldTick = r != null && r.isStarted && !r.isPaused;
    if (shouldTick && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
    } else if (!shouldTick && _ticker != null) {
      _ticker!.cancel();
      _ticker = null;
    }
  }

  int get elapsedSeconds => routine == null ? 0 : WorkoutService.calculateDurationSeconds(routine!);
  int get pausedSeconds => routine == null ? 0 : WorkoutService.calculatePausedSeconds(routine!);

  Future<void> startWorkout() async {
    await _workoutService.startWorkout(routineId);
    await load();
  }

  Future<void> pauseWorkout() async {
    await _workoutService.pauseWorkout(routineId);
    await load();
  }

  Future<void> resumeWorkout() async {
    await _workoutService.resumeWorkout(routineId);
    await load();
  }

  Future<WorkoutStatistics> finishWorkout() async {
    final stats = await _workoutService.finishWorkout(routineId);
    await load();
    return stats;
  }

  Future<void> toggleExercise(int exerciseId) async {
    await _exerciseRepository.toggleDone(exerciseId, routineId);
    await load();
  }

  Future<void> addExercise(String name) async {
    await _exerciseRepository.addExercise(routineId, name);
    await load();
  }

  Future<void> renameExercise(int exerciseId, String name) async {
    await _exerciseRepository.updateName(exerciseId, routineId, name);
    await load();
  }

  Future<void> deleteExercise(int exerciseId) async {
    await _exerciseRepository.deleteExercise(exerciseId, routineId);
    await load();
  }

  Future<void> reorderExercises(List<int> orderedIds) async {
    await _exerciseRepository.reorderExercises(routineId, orderedIds);
    await load();
  }

  Future<void> updateDetails(String name, String description) async {
    await _routineRepository.updateDetails(routineId, name, description);
    await load();
  }

  Future<void> deleteRoutine() async {
    await _routineRepository.deleteRoutine(routineId);
  }

  Future<void> deleteCompletion(int completionId) async {
    await _completionRepository.deleteCompletion(completionId, routineId);
    await load();
  }

  Future<bool> updateCompletionDate(int completionId, DateTime newDate) async {
    final existing = completions.firstWhere((c) => c.id == completionId);
    int? durationMinutes;
    if (existing.startedAt != null) {
      durationMinutes = WorkoutService.calculateDurationMinutes(
        existing.startedAt!,
        newDate,
        existing.pausedSeconds ?? 0,
      );
    }
    final ok = await _completionRepository.updateCompletionDate(
      completionId,
      routineId,
      newDate,
      durationMinutes: durationMinutes,
    );
    if (ok) await load();
    return ok;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

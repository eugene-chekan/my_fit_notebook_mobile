import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/completion.dart';
import '../data/models/exercise.dart';
import '../data/models/exercise_catalog.dart';
import '../data/models/routine.dart';
import '../data/repositories/completion_repository.dart';
import '../data/repositories/exercise_catalog_repository.dart';
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
    ExerciseCatalogRepository? catalogRepository,
    WorkoutService? workoutService,
  }) : _routineRepository = routineRepository ?? RoutineRepository(),
       _exerciseRepository = exerciseRepository ?? ExerciseRepository(),
       _completionRepository = completionRepository ?? CompletionRepository(),
       _catalogRepository = catalogRepository ?? ExerciseCatalogRepository(),
       _workoutService = workoutService ?? WorkoutService();

  final int routineId;
  final RoutineRepository _routineRepository;
  final ExerciseRepository _exerciseRepository;
  final CompletionRepository _completionRepository;
  final ExerciseCatalogRepository _catalogRepository;
  final WorkoutService _workoutService;

  Routine? routine;
  List<Exercise> exercises = [];
  List<Completion> completions = [];
  /// Full catalog entries for the add-exercise autocomplete and to prefill
  /// the prescription form from an exercise's defaults; refreshed on load.
  List<CatalogEntry> catalogEntries = [];
  bool loading = true;
  Timer? _ticker;

  /// Just the names, for the autocomplete option pool.
  List<String> get catalogNames => catalogEntries.map((e) => e.name).toList();

  /// The catalog entry matching [name] (case-insensitive), or null.
  CatalogEntry? catalogEntryFor(String name) {
    final lower = name.trim().toLowerCase();
    for (final e in catalogEntries) {
      if (e.name.toLowerCase() == lower) return e;
    }
    return null;
  }

  Future<void> load() async {
    routine = await _routineRepository.getRoutine(routineId);
    exercises = await _exerciseRepository.listExercises(routineId);
    completions = await _completionRepository.listForRoutine(routineId);
    catalogEntries = await _catalogRepository.listAll();
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

  /// Net active seconds right now, for the live workout clock. Unlike
  /// [elapsedSeconds] (which mirrors the web app's minute-truncated math),
  /// this keeps second precision so the timer visibly ticks.
  int get liveElapsedSeconds {
    final r = routine;
    final startedAt = r?.startedAt;
    if (r == null || startedAt == null) return 0;
    try {
      final total = DateTime.now().difference(DateTime.parse(startedAt)).inSeconds;
      final net = total - WorkoutService.calculatePausedSeconds(r);
      return net < 0 ? 0 : net;
    } catch (_) {
      return 0;
    }
  }

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

  Future<void> addExercise(
    String name, {
    int? sets,
    int? repsMin,
    int? repsMax,
  }) async {
    await _exerciseRepository.addExercise(
      routineId,
      name,
      sets: sets,
      repsMin: repsMin,
      repsMax: repsMax,
    );
    await load();
  }

  Future<void> updatePrescription(
    int exerciseId, {
    int? sets,
    int? repsMin,
    int? repsMax,
  }) async {
    await _exerciseRepository.updatePrescription(
      exerciseId,
      routineId,
      sets: sets,
      repsMin: repsMin,
      repsMax: repsMax,
    );
    await load();
  }

  Future<void> renameExercise(int exerciseId, String name) async {
    await _exerciseRepository.updateName(exerciseId, routineId, name);
    await load();
  }

  /// Optimistically removes the row first so a swipe-dismissed Dismissible
  /// leaves the tree in the same frame, then persists and reloads.
  Future<void> deleteExercise(int exerciseId) async {
    exercises = exercises.where((e) => e.id != exerciseId).toList();
    notifyListeners();
    await _exerciseRepository.deleteExercise(exerciseId, routineId);
    await load();
  }

  Future<void> duplicateExercise(int exerciseId) async {
    await _exerciseRepository.duplicateExercise(exerciseId, routineId);
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

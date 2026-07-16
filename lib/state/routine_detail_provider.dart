import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/completion.dart';
import '../data/models/exercise.dart';
import '../data/models/exercise_catalog.dart';
import '../data/models/exercise_set.dart';
import '../data/models/rep_unit.dart';
import '../data/models/routine.dart';
import '../data/repositories/completion_repository.dart';
import '../data/repositories/exercise_catalog_repository.dart';
import '../data/repositories/exercise_repository.dart';
import '../data/repositories/routine_repository.dart';
import '../data/services/workout_service.dart';
import '../utils/set_progress.dart';

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
  /// Per-set working state, keyed by exercise id (prescribed exercises only).
  Map<int, List<ExerciseSet>> setsByExercise = {};
  /// Which exercises are currently expanded to show their sets. Kept here so
  /// it survives the frequent [load] reloads that follow each set toggle.
  final Set<int> expandedExercises = {};
  bool loading = true;
  Timer? _ticker;

  /// The set rows for an exercise (empty for a bare exercise).
  List<ExerciseSet> setsFor(int exerciseId) => setsByExercise[exerciseId] ?? const [];

  /// An exercise is "prescribed" (gets the per-set breakdown) when it has a
  /// positive sets count — which is exactly when it has seeded set rows.
  bool isPrescribed(Exercise exercise) => setsFor(exercise.id).isNotEmpty;

  bool isExpanded(int exerciseId) => expandedExercises.contains(exerciseId);

  /// (done, total) over the routine's exercises, for the live progress readout
  /// in the workout strip.
  ({int done, int total}) get exerciseProgress =>
      exerciseCompletion(exercises, setsByExercise);

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
    setsByExercise = await _exerciseRepository.listSetsForRoutine(routineId);
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

  /// Expand/collapse an exercise's set list. UI-only — no reload needed.
  void toggleExpanded(int exerciseId) {
    if (!expandedExercises.remove(exerciseId)) {
      expandedExercises.add(exerciseId);
    }
    notifyListeners();
  }

  Future<void> toggleSet(int setId, int exerciseId) async {
    await _exerciseRepository.toggleSet(setId, exerciseId);
    await load();
  }

  /// Checks or clears every set of an exercise at once (the header checkbox).
  Future<void> markAllSets(int exerciseId, bool done) async {
    await _exerciseRepository.markAllSets(exerciseId, done);
    await load();
  }

  Future<void> setSetReps(int setId, int? reps) async {
    await _exerciseRepository.setSetReps(setId, reps);
    await load();
  }

  Future<void> addExercise(
    String name, {
    int? sets,
    int? repsMin,
    int? repsMax,
    String unit = RepUnit.reps,
  }) async {
    await _exerciseRepository.addExercise(
      routineId,
      name,
      sets: sets,
      repsMin: repsMin,
      repsMax: repsMax,
      unit: unit,
    );
    await load();
  }

  Future<void> updatePrescription(
    int exerciseId, {
    int? sets,
    int? repsMin,
    int? repsMax,
    String unit = RepUnit.reps,
  }) async {
    await _exerciseRepository.updatePrescription(
      exerciseId,
      routineId,
      sets: sets,
      repsMin: repsMin,
      repsMax: repsMax,
      unit: unit,
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

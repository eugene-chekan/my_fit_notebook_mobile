import 'package:flutter/foundation.dart';

import '../data/models/routine.dart';
import '../data/repositories/routine_repository.dart';

/// Backs the dashboard: the full routine list plus create/delete.
class RoutinesProvider extends ChangeNotifier {
  RoutinesProvider({RoutineRepository? repository}) : _repository = repository ?? RoutineRepository();

  final RoutineRepository _repository;

  List<Routine> _routines = [];
  bool _loading = true;

  List<Routine> get routines => _routines;
  bool get loading => _loading;

  Future<void> load() async {
    _routines = await _repository.listRoutines();
    _loading = false;
    notifyListeners();
  }

  Future<void> addRoutine(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _repository.addRoutine(trimmed);
    await load();
  }

  /// Removes the row from the in-memory list synchronously before touching
  /// the database, so a swipe-dismissed row leaves the widget tree in the
  /// same frame (Dismissible requires this), then persists and reloads.
  Future<void> deleteRoutine(int routineId) async {
    _routines = _routines.where((r) => r.id != routineId).toList();
    notifyListeners();
    await _repository.deleteRoutine(routineId);
    await load();
  }

  Future<void> duplicateRoutine(int routineId) async {
    await _repository.duplicateRoutine(routineId);
    await load();
  }
}

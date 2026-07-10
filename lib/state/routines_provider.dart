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

  Future<void> deleteRoutine(int routineId) async {
    await _repository.deleteRoutine(routineId);
    await load();
  }
}

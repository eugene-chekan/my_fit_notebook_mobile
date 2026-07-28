import 'package:flutter/foundation.dart';

import '../data/models/program.dart';
import '../data/models/routine.dart';
import '../data/repositories/program_repository.dart';

/// Backs the programs library and the add-to-program picker.
class ProgramsProvider extends ChangeNotifier {
  ProgramsProvider({ProgramRepository? repository})
      : _repository = repository ?? ProgramRepository();

  final ProgramRepository _repository;

  List<Program> programs = [];
  bool loading = true;

  Future<void> load() async {
    programs = await _repository.listPrograms();
    loading = false;
    notifyListeners();
  }

  Future<int> addProgram(String name) async {
    final id = await _repository.createProgram(name);
    await load();
    return id;
  }

  Future<void> updateDetails(int id, String name, String description) async {
    await _repository.updateDetails(id, name, description);
    await load();
  }

  /// Optimistically drops the row so a swipe-dismissed row leaves the tree in
  /// the same frame, then persists and reloads.
  Future<void> deleteProgram(int id) async {
    programs = programs.where((p) => p.id != id).toList();
    notifyListeners();
    await _repository.deleteProgram(id);
    await load();
  }

  Future<void> duplicateProgram(int id) async {
    await _repository.duplicateProgram(id);
    await load();
  }

  Future<List<Routine>> routinesFor(int programId) =>
      _repository.routinesFor(programId);

  Future<Set<int>> programIdsFor(int routineId) =>
      _repository.programIdsFor(routineId);

  Future<bool> addRoutine(int programId, int routineId) async {
    final ok = await _repository.addRoutine(programId, routineId);
    if (ok) await load();
    return ok;
  }

  Future<void> removeRoutine(int programId, int routineId) async {
    await _repository.removeRoutine(programId, routineId);
    await load();
  }

  Future<void> reorderRoutines(int programId, List<int> orderedIds) =>
      _repository.reorderRoutines(programId, orderedIds);
}

import 'package:flutter/foundation.dart';

import '../data/models/exercise_catalog.dart';
import '../data/models/rep_unit.dart';
import '../data/repositories/exercise_catalog_repository.dart';

/// Backs the Exercises (catalog management) screen: the full library plus
/// create / update / delete. All local.
class ExerciseCatalogProvider extends ChangeNotifier {
  ExerciseCatalogProvider({ExerciseCatalogRepository? repository})
    : _repository = repository ?? ExerciseCatalogRepository();

  final ExerciseCatalogRepository _repository;

  List<CatalogEntry> entries = [];
  bool loading = true;

  Future<void> load() async {
    entries = await _repository.listAll();
    loading = false;
    notifyListeners();
  }

  /// Returns false on a duplicate name so the UI can report it.
  Future<bool> create({
    required String name,
    String description = '',
    int? defaultSets,
    int? defaultReps,
    int? defaultRepsMax,
    String defaultUnit = RepUnit.reps,
  }) async {
    final ok = await _repository.create(
      name: name,
      description: description,
      defaultSets: defaultSets,
      defaultReps: defaultReps,
      defaultRepsMax: defaultRepsMax,
      defaultUnit: defaultUnit,
    );
    if (ok) await load();
    return ok;
  }

  Future<bool> update(CatalogEntry entry) async {
    final ok = await _repository.update(entry);
    if (ok) await load();
    return ok;
  }

  Future<int> usageCount(int id) => _repository.usageCount(id);

  Future<void> delete(int id) async {
    entries = entries.where((e) => e.id != id).toList();
    notifyListeners();
    await _repository.delete(id);
    await load();
  }
}

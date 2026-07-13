import 'rep_unit.dart';

/// Mirrors the `Exercise` dataclass in the Flask app's models.py.
class Exercise {
  const Exercise({
    required this.id,
    required this.routineId,
    required this.name,
    required this.sortOrder,
    required this.isDone,
    this.catalogId,
    this.sets,
    this.repsMin,
    this.repsMax,
    this.unit = RepUnit.reps,
  });

  final int id;
  final int routineId;
  final String name;
  final int sortOrder;
  final bool isDone;
  /// Link to the canonical catalog entry, or null for legacy rows.
  final int? catalogId;
  /// Per-routine prescription (null when unset). [repsMax] > [repsMin]
  /// denotes a range (e.g. 10-12). [unit] is reps, seconds, or minutes.
  final int? sets;
  final int? repsMin;
  final int? repsMax;
  final String unit;

  Exercise copyWith({String? name, bool? isDone, int? sortOrder}) {
    return Exercise(
      id: id,
      routineId: routineId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isDone: isDone ?? this.isDone,
      catalogId: catalogId,
      sets: sets,
      repsMin: repsMin,
      repsMax: repsMax,
      unit: unit,
    );
  }

  factory Exercise.fromMap(Map<String, Object?> map) {
    return Exercise(
      id: map['id'] as int,
      routineId: map['routine_id'] as int,
      name: map['name'] as String,
      sortOrder: map['sort_order'] as int,
      isDone: (map['is_done'] as int) != 0,
      catalogId: map['catalog_id'] as int?,
      sets: map['sets'] as int?,
      repsMin: map['reps_min'] as int?,
      repsMax: map['reps_max'] as int?,
      unit: (map['unit'] as String?) ?? RepUnit.reps,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'routine_id': routineId,
    'name': name,
    'sort_order': sortOrder,
    'is_done': isDone ? 1 : 0,
    'catalog_id': catalogId,
    'sets': sets,
    'reps_min': repsMin,
    'reps_max': repsMax,
    'unit': unit,
  };
}

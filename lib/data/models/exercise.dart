/// Mirrors the `Exercise` dataclass in the Flask app's models.py.
class Exercise {
  const Exercise({
    required this.id,
    required this.routineId,
    required this.name,
    required this.sortOrder,
    required this.isDone,
  });

  final int id;
  final int routineId;
  final String name;
  final int sortOrder;
  final bool isDone;

  Exercise copyWith({String? name, bool? isDone, int? sortOrder}) {
    return Exercise(
      id: id,
      routineId: routineId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isDone: isDone ?? this.isDone,
    );
  }

  factory Exercise.fromMap(Map<String, Object?> map) {
    return Exercise(
      id: map['id'] as int,
      routineId: map['routine_id'] as int,
      name: map['name'] as String,
      sortOrder: map['sort_order'] as int,
      isDone: (map['is_done'] as int) != 0,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'routine_id': routineId,
    'name': name,
    'sort_order': sortOrder,
    'is_done': isDone ? 1 : 0,
  };
}

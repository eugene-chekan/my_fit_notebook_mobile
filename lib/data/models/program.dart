/// A named group of workouts — a training split like "Push / Pull / Legs"
/// gathered onto one page. Membership is many-to-many, so the same workout can
/// belong to several programs.
class Program {
  const Program({
    required this.id,
    required this.name,
    this.description = '',
    this.sortOrder = 0,
    this.workoutCount = 0,
  });

  final int id;
  final String name;
  final String description;
  final int sortOrder;

  /// How many workouts this program holds — joined for the list line, not
  /// stored on the row.
  final int workoutCount;

  factory Program.fromMap(Map<String, Object?> map) => Program(
        id: map['id'] as int,
        name: (map['name'] as String?) ?? '',
        description: (map['description'] as String?) ?? '',
        sortOrder: (map['sort_order'] as int?) ?? 0,
        workoutCount: (map['workout_count'] as int?) ?? 0,
      );
}

/// A canonical exercise in the local catalog. Carries metadata columns
/// (default sets/reps, notes) that back name suggestions today and leave
/// room for per-exercise features later. Strictly on-device.
class CatalogEntry {
  const CatalogEntry({
    required this.id,
    required this.name,
    this.defaultSets,
    this.defaultReps,
    this.notes = '',
  });

  final int id;
  final String name;
  final int? defaultSets;
  final int? defaultReps;
  final String notes;

  factory CatalogEntry.fromMap(Map<String, Object?> map) {
    return CatalogEntry(
      id: map['id'] as int,
      name: map['name'] as String,
      defaultSets: map['default_sets'] as int?,
      defaultReps: map['default_reps'] as int?,
      notes: (map['notes'] as String?) ?? '',
    );
  }
}

/// A canonical exercise in the local catalog. Holds the exercise's identity
/// (name, description) and default prescription (sets, reps, optional rep
/// range) that routine memberships prefill from. Strictly on-device.
class CatalogEntry {
  const CatalogEntry({
    required this.id,
    required this.name,
    this.description = '',
    this.defaultSets,
    this.defaultReps,
    this.defaultRepsMax,
  });

  final int id;
  final String name;
  final String description;
  final int? defaultSets;
  final int? defaultReps;
  final int? defaultRepsMax;

  CatalogEntry copyWith({
    String? name,
    String? description,
    Object? defaultSets = _unset,
    Object? defaultReps = _unset,
    Object? defaultRepsMax = _unset,
  }) {
    return CatalogEntry(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      defaultSets: identical(defaultSets, _unset) ? this.defaultSets : defaultSets as int?,
      defaultReps: identical(defaultReps, _unset) ? this.defaultReps : defaultReps as int?,
      defaultRepsMax:
          identical(defaultRepsMax, _unset) ? this.defaultRepsMax : defaultRepsMax as int?,
    );
  }

  static const _unset = Object();

  factory CatalogEntry.fromMap(Map<String, Object?> map) {
    return CatalogEntry(
      id: map['id'] as int,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      defaultSets: map['default_sets'] as int?,
      defaultReps: map['default_reps'] as int?,
      defaultRepsMax: map['default_reps_max'] as int?,
    );
  }
}

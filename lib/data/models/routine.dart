/// Mirrors the `Routine` dataclass in the Flask app's models.py.
class Routine {
  const Routine({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
    this.description = '',
    this.startedAt,
    this.pausedAt,
    this.pausedSeconds = 0,
  });

  final int id;
  final String name;
  final int sortOrder;
  final String createdAt;
  final String description;
  final String? startedAt;
  final String? pausedAt;
  final int pausedSeconds;

  bool get isStarted => startedAt != null;
  bool get isPaused => pausedAt != null;

  Routine copyWith({
    String? name,
    int? sortOrder,
    String? description,
    Object? startedAt = _unset,
    Object? pausedAt = _unset,
    int? pausedSeconds,
  }) {
    return Routine(
      id: id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      description: description ?? this.description,
      startedAt: identical(startedAt, _unset) ? this.startedAt : startedAt as String?,
      pausedAt: identical(pausedAt, _unset) ? this.pausedAt : pausedAt as String?,
      pausedSeconds: pausedSeconds ?? this.pausedSeconds,
    );
  }

  static const _unset = Object();

  factory Routine.fromMap(Map<String, Object?> map) {
    return Routine(
      id: map['id'] as int,
      name: map['name'] as String,
      sortOrder: map['sort_order'] as int,
      createdAt: map['created_at'] as String,
      description: (map['description'] as String?) ?? '',
      startedAt: map['started_at'] as String?,
      pausedAt: map['paused_at'] as String?,
      pausedSeconds: (map['paused_seconds'] as int?) ?? 0,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'sort_order': sortOrder,
    'created_at': createdAt,
    'description': description,
    'started_at': startedAt,
    'paused_at': pausedAt,
    'paused_seconds': pausedSeconds,
  };
}

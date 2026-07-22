import 'dart:convert';

/// Local-only user profile. Lives entirely in the on-device database —
/// nothing here is ever transmitted anywhere.
class Profile {
  const Profile({
    required this.name,
    this.birthDate,
    this.heightCm,
    this.units = Units.metric,
    this.language = AppLanguage.system,
    this.theme = AppTheme.paper,
    this.paperStyles = const {},
  });

  final String name;
  /// yyyy-MM-dd, or null if unset.
  final String? birthDate;
  final double? heightCm;
  /// [Units.metric] or [Units.imperial] — display preference only; all
  /// stored values are canonical metric.
  final String units;
  /// UI language preference: [AppLanguage.system] (follow device),
  /// [AppLanguage.en], or [AppLanguage.ru].
  final String language;
  /// Selected notebook theme id (see [AppTheme] / `ThemeId`). Defaults to the
  /// light [AppTheme.paper].
  final String theme;
  /// Per-theme paper-style overrides, keyed by `ThemeId` name →
  /// [PaperStyle.ruled] / [PaperStyle.grid]. A theme absent from the map uses
  /// its built-in default. Persisted as a JSON object string.
  final Map<String, String> paperStyles;

  factory Profile.fromMap(Map<String, Object?> map) {
    return Profile(
      name: (map['name'] as String?) ?? '',
      birthDate: map['birth_date'] as String?,
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      units: (map['units'] as String?) ?? Units.metric,
      language: (map['language'] as String?) ?? AppLanguage.system,
      theme: (map['theme'] as String?) ?? AppTheme.paper,
      paperStyles: decodePaperStyles(map['paper_styles'] as String?),
    );
  }

  /// Parse the stored JSON map of per-theme paper styles, tolerating null,
  /// empty, or malformed values (returns an empty map).
  static Map<String, String> decodePaperStyles(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return {
          for (final entry in decoded.entries)
            entry.key.toString(): entry.value.toString(),
        };
      }
    } catch (_) {
      // Malformed — fall back to no overrides.
    }
    return const {};
  }
}

abstract final class Units {
  static const metric = 'metric';
  static const imperial = 'imperial';
}

abstract final class AppLanguage {
  static const system = 'system';
  static const en = 'en';
  static const ru = 'ru';
}

/// Persisted notebook-theme ids, mirroring the `ThemeId` enum. Kept as plain
/// strings here so the data layer stays free of UI imports.
abstract final class AppTheme {
  static const paper = 'paper';
  static const blueprint = 'blueprint';
}

/// Persisted paper-style values for the per-theme ruled/grid override.
abstract final class PaperStyle {
  static const ruled = 'ruled';
  static const grid = 'grid';
}

/// One dated entry in a body-measurement history. [value] is canonical
/// metric (kg for weight, cm for lengths).
class Measurement {
  const Measurement({
    required this.id,
    required this.metric,
    required this.value,
    required this.measuredOn,
  });

  final int id;
  final String metric;
  final double value;
  /// yyyy-MM-dd
  final String measuredOn;

  factory Measurement.fromMap(Map<String, Object?> map) {
    return Measurement(
      id: map['id'] as int,
      metric: map['metric'] as String,
      value: (map['value'] as num).toDouble(),
      measuredOn: map['measured_on'] as String,
    );
  }
}

/// A body metric the profile tracks. [isWeight] picks kg/lb; everything
/// else is a length in cm/in.
class BodyMetric {
  const BodyMetric(this.key, this.label, {this.isWeight = false});

  final String key;
  final String label;
  final bool isWeight;
}

const kBodyMetrics = [
  BodyMetric('weight', 'weight', isWeight: true),
  BodyMetric('chest', 'chest'),
  BodyMetric('waist', 'waist'),
  BodyMetric('hips', 'hips'),
  BodyMetric('biceps', 'biceps'),
  BodyMetric('thigh', 'thigh'),
];

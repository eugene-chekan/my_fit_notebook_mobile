/// The unit a prescription's second number is counted in: bare reps, or a
/// hold/duration counted in seconds or minutes ("2x45sec", "1x2min").
abstract final class RepUnit {
  static const reps = 'reps';
  static const seconds = 'sec';
  static const minutes = 'min';

  static const all = [reps, seconds, minutes];

  /// Short label used in the display suffix — '' for reps (no suffix).
  static String suffix(String unit) => unit == reps ? '' : unit;
}

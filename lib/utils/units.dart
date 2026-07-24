/// Unit conversion + formatting for body measurements. Storage is always
/// canonical metric (kg / cm); these helpers convert at the display edge.
library;

import '../data/models/profile.dart';

const _kgPerLb = 0.45359237;
const _cmPerIn = 2.54;

/// Localized unit symbols (kg / cm / lb / in). Built from the active
/// [AppLocalizations] at the display edge so the pure conversion helpers stay
/// locale-agnostic. See `unitLabelsFor` in `metric_labels.dart`.
typedef UnitLabels = ({String kg, String cm, String lb, String inch});

/// Canonical metric → display units.
double toDisplay(double metricValue, BodyMetric metric, String units) {
  if (units == Units.imperial) {
    return metric.isWeight ? metricValue / _kgPerLb : metricValue / _cmPerIn;
  }
  return metricValue;
}

/// Display units → canonical metric.
double toCanonical(double displayValue, BodyMetric metric, String units) {
  if (units == Units.imperial) {
    return metric.isWeight ? displayValue * _kgPerLb : displayValue * _cmPerIn;
  }
  return displayValue;
}

String unitSuffix(BodyMetric metric, String units, UnitLabels labels) {
  if (units == Units.imperial) return metric.isWeight ? labels.lb : labels.inch;
  return metric.isWeight ? labels.kg : labels.cm;
}

String heightSuffix(String units, UnitLabels labels) =>
    units == Units.imperial ? labels.inch : labels.cm;

double heightToDisplay(double cm, String units) =>
    units == Units.imperial ? cm / _cmPerIn : cm;

double heightToCanonical(double display, String units) =>
    units == Units.imperial ? display * _cmPerIn : display;

/// "82.4" / "78" — one decimal, trimmed when whole.
String formatNumber(double v) {
  final rounded = (v * 10).round() / 10;
  if (rounded == rounded.roundToDouble()) return rounded.round().toString();
  return rounded.toStringAsFixed(1);
}

/// Formats a canonical value in display units with its suffix: "82.4 kg".
String formatMeasurement(
    double metricValue, BodyMetric metric, String units, UnitLabels labels) {
  return '${formatNumber(toDisplay(metricValue, metric, units))} '
      '${unitSuffix(metric, units, labels)}';
}

/// Parses user input ("82.4" or "82,4") as a display-units value; null when
/// not a positive number.
double? parseDisplayNumber(String input) {
  final v = double.tryParse(input.trim().replaceAll(',', '.'));
  if (v == null || v <= 0 || !v.isFinite) return null;
  return v;
}

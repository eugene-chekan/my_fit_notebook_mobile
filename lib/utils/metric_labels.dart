import 'package:flutter/widgets.dart';

import '../data/models/rep_unit.dart';
import '../l10n/app_localizations.dart';
import 'units.dart';

/// Localized unit symbols (кг/см/фнт/дюйм) for the active locale.
UnitLabels unitLabelsFor(AppLocalizations t) =>
    (kg: t.unitKg, cm: t.unitCm, lb: t.unitLb, inch: t.unitIn);

/// Localized word-label for a rep unit ('reps'/'sec'/'min').
String repUnitLabel(AppLocalizations t, String unit) {
  switch (unit) {
    case RepUnit.seconds:
      return t.repUnitSec;
    case RepUnit.minutes:
      return t.repUnitMin;
    default:
      return t.repUnitReps;
  }
}

/// Localized display label for a body-metric key. The keys stay English
/// (they're persisted to the DB `measurements.metric` / `targets.metric`
/// columns); only the shown label is translated.
String localizedMetric(BuildContext context, String key) {
  final t = AppLocalizations.of(context);
  switch (key) {
    case 'weight':
      return t.metricWeight;
    case 'chest':
      return t.metricChest;
    case 'waist':
      return t.metricWaist;
    case 'hips':
      return t.metricHips;
    case 'biceps':
      return t.metricBiceps;
    case 'thigh':
      return t.metricThigh;
    default:
      return key;
  }
}

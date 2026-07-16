import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

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

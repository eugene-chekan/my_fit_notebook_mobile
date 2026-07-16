import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/profile.dart';
import '../l10n/app_localizations.dart';
import '../route_observer.dart';
import '../state/stats_provider.dart';
import '../theme/notebook_theme.dart';
import '../utils/formatters.dart';
import '../utils/metric_labels.dart';
import '../utils/units.dart';
import '../widgets/glyph_button.dart';
import '../widgets/notebook_bar_chart.dart';
import '../widgets/notebook_drawer.dart';
import '../widgets/notebook_header.dart';
import '../widgets/notebook_line_chart.dart';
import '../widgets/notebook_page.dart';

/// Read-only analytics over the local log: training-time volume from the
/// completion history and body-measurement trends from the profile. Reached
/// from the side menu. Editing still lives on the Profile page.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with RouteAware {
  late final StatsProvider _provider;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _provider = StatsProvider()..load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appRouteObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _provider.dispose();
    super.dispose();
  }

  @override
  void didPopNext() => _provider.load();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const NotebookDrawer(),
        body: SafeArea(
          child: NotebookPage(
            marginChild: GlyphButton(
              glyph: '≡',
              size: 26,
              semanticLabel: t.menu,
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            child: Consumer<StatsProvider>(
              builder: (context, stats, _) {
                if (stats.loading) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [NotebookHeader(title: t.navStats, leading: const BackGlyph())],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NotebookHeader(title: t.navStats, leading: const BackGlyph()),
                    const SizedBox(height: 8),
                    HeadingLine(t.trainingTime),
                    ..._trainingTime(stats),
                    const SizedBox(height: 16),
                    HeadingLine(t.bodyTrends),
                    ..._bodyTrends(stats),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // --- Training time ---------------------------------------------------

  List<Widget> _trainingTime(StatsProvider s) {
    final t = AppLocalizations.of(context);
    if (!s.hasWorkouts) {
      return [MutedLine(t.finishWorkoutEmpty)];
    }
    final rows = <Widget>[
      _statRow(t.statThisMonth, _countAndTime(s.monthWorkouts, s.monthMinutes)),
    ];
    if (s.hasPrevMonthData) {
      rows.add(_statRow(t.statVsLastMonth, _monthDelta(s)));
    }
    if (s.avgMinutes != null) {
      rows.add(_statRow(t.statAvgSession, formatDurationMinutes(s.avgMinutes!.round())));
    }
    rows.add(_statRow(t.statAllTime, _countAndTime(s.allTimeWorkouts, s.allTimeMinutes)));

    final hasMinuteData = s.weekBuckets.any((w) => w.minutes > 0);
    rows.add(const SizedBox(height: 10));
    if (hasMinuteData) {
      rows.add(MutedLine(t.minutesPerWeek));
      rows.add(NotebookBarChart(weeks: s.weekBuckets));
    } else {
      rows.add(MutedLine(t.noTimedWorkouts));
    }
    return rows;
  }

  String _countAndTime(int workouts, int minutes) {
    final t = AppLocalizations.of(context);
    final time = minutes > 0 ? ' · ${formatDurationMinutes(minutes)}' : '';
    return '${t.workoutsCount(workouts)}$time';
  }

  String _monthDelta(StatsProvider s) {
    final t = AppLocalizations.of(context);
    final dWorkouts = s.monthWorkouts - s.prevMonthWorkouts;
    final dMinutes = s.monthMinutes - s.prevMonthMinutes;
    final workoutPart = '${_signed(dWorkouts)} ${t.workoutNoun(dWorkouts.abs())}';
    final minutePart = dMinutes != 0
        ? ' · ${dMinutes > 0 ? '+' : '-'}${formatDurationMinutes(dMinutes.abs())}'
        : '';
    return '$workoutPart$minutePart';
  }

  String _signed(int n) => n > 0 ? '+$n' : '$n'; // negatives already carry '-'

  // --- Body trends -----------------------------------------------------

  List<Widget> _bodyTrends(StatsProvider s) {
    final t = AppLocalizations.of(context);
    const weightMetric = BodyMetric('weight', 'weight', isWeight: true);
    final weightSeries = s.series['weight'] ?? const [];
    final hasAnyData = kBodyMetrics.any((m) => (s.series[m.key] ?? const []).isNotEmpty);
    if (!hasAnyData) {
      return [MutedLine(t.noMeasurements)];
    }

    final widgets = <Widget>[];

    // Weight is the marquee: latest + BMI, then the full trend line.
    final weightLatest = s.latest['weight'];
    if (weightLatest != null) {
      final bmiText = s.bmiValue != null ? ' · BMI ${s.bmiValue!.toStringAsFixed(1)}' : '';
      widgets.add(_statRow(
        localizedMetric(context, 'weight'),
        '${formatMeasurement(weightLatest.value, weightMetric, s.units)}$bmiText',
      ));
    }
    if (weightSeries.length >= 2) {
      final values = [
        for (final m in weightSeries) toDisplay(m.value, weightMetric, s.units),
      ];
      final weightTarget = s.targets['weight'];
      widgets.add(const SizedBox(height: 4));
      widgets.add(NotebookLineChart(
        values: values,
        target: weightTarget != null
            ? toDisplay(weightTarget, weightMetric, s.units)
            : null,
        goalLabel: weightTarget != null
            ? t.statsGoal(formatMeasurement(weightTarget, weightMetric, s.units))
            : null,
        height: 108,
      ));
    } else if (weightLatest != null) {
      widgets.add(MutedLine(t.logWeightAgain));
    }

    // Other metrics: compact rows with an inline sparkline when there's a trend.
    final others = [
      for (final metric in kBodyMetrics)
        if (!metric.isWeight && (s.series[metric.key] ?? const []).isNotEmpty) metric,
    ];
    if (others.isNotEmpty) widgets.add(const SizedBox(height: 10));
    for (final metric in others) {
      widgets.add(_metricRow(metric, s));
    }
    return widgets;
  }

  Widget _metricRow(BodyMetric metric, StatsProvider s) {
    final data = s.series[metric.key] ?? const [];
    final latest = s.latest[metric.key];
    return SizedBox(
      height: kNotebookLine,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 130,
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 20,
                  color: NotebookColors.ink,
                ),
                children: [
                  TextSpan(text: localizedMetric(context, metric.key)),
                  if (latest != null)
                    TextSpan(
                      text: '  ${formatMeasurement(latest.value, metric, s.units)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: data.length >= 2
                ? NotebookLineChart(
                    values: [
                      for (final m in data) toDisplay(m.value, metric, s.units),
                    ],
                    height: 26,
                    showDots: false,
                    strokeWidth: 1.8,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // --- shared -----------------------------------------------------------

  /// A ruled-line stat: an italic muted label followed by the value in ink.
  Widget _statRow(String label, String value) {
    return Container(
      height: kNotebookLine,
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.only(bottom: 3),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label   ',
              style: const TextStyle(
                fontFamily: 'Caveat',
                fontSize: 17,
                fontStyle: FontStyle.italic,
                color: NotebookColors.inkSoft,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontFamily: 'Caveat',
                fontSize: 20,
                color: NotebookColors.ink,
              ),
            ),
          ],
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

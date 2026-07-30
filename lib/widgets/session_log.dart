import 'package:flutter/material.dart';

import '../data/models/completion.dart';
import '../data/models/profile.dart';
import '../l10n/app_localizations.dart';
import '../theme/notebook_theme.dart';
import '../utils/formatters.dart';
import '../utils/metric_labels.dart';
import '../utils/units.dart';
import 'notebook_page.dart';
import 'swipe_actions.dart';

/// The body metric loads are logged against, for the kg/lb conversion and its
/// suffix — the same one the profile uses, so a lifted load and a bodyweight
/// entry always read in the same unit.
final _weightMetric = kBodyMetrics.firstWhere((m) => m.isWeight);

/// "3 exercises · 12 sets · 140 reps" from the totals snapshotted at finish
/// (DB v8). Empty for pre-v8 sessions that never captured them; sets and reps
/// drop out when zero (a bare-checkbox workout logs exercises only).
String completionSummary(AppLocalizations t, Completion completion) {
  final exercises = completion.exercisesCompleted;
  if (exercises == null) return '';
  final parts = <String>[t.sessionExercises(exercises)];
  final sets = completion.setsCompleted ?? 0;
  if (sets > 0) parts.add(t.sessionSets(sets));
  final reps = completion.repsTotal ?? 0;
  if (reps > 0) parts.add(t.sessionReps(reps));
  return parts.join(' · ');
}

/// One logged session as a notebook row: date and duration on the line, the
/// totals on the next. Shared by the workout screen's recent log and the
/// Training log, so a session reads the same wherever it's listed.
class CompletionRow extends StatelessWidget {
  const CompletionRow({
    super.key,
    required this.completion,
    required this.onTap,
    this.onDelete,
  });

  final Completion completion;

  /// Opens the session's full breakdown.
  final VoidCallback onTap;

  /// Shows the confirm dialog and deletes if confirmed; awaited by the swipe.
  /// Null leaves the row un-swipeable.
  final Future<void> Function()? onDelete;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final row = InkWell(
      onTap: onTap,
      child: _content(context, t, completionSummary(t, completion)),
    );
    if (onDelete == null) return row;
    return SwipeableRow(
      itemKey: ValueKey('completion-${completion.id}'),
      onDelete: () async {
        await onDelete!();
        return false; // deletion (with confirm) handled by the callback
      },
      child: row,
    );
  }

  Widget _content(BuildContext context, AppLocalizations t, String summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: notebookLine(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontFamily: 'Caveat',
                        fontSize: 18,
                        color: context.notebook.ink,
                      ),
                      children: [
                        TextSpan(text: formatCompletionDt(completion.completedOn)),
                        if (completion.durationMinutes != null &&
                            completion.durationMinutes! >= 0)
                          TextSpan(
                            text:
                                '  (${formatDurationMinutes(completion.durationMinutes!)})',
                            style: TextStyle(color: context.notebook.sec),
                          ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (summary.isNotEmpty)
          SizedBox(
            height: notebookLine(context),
            child: Container(
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.only(left: 2, bottom: 3),
              child: Text(
                summary,
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 16,
                  color: context.notebook.sec,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
}

/// Opens [CompletionDetailSheet] in the notebook's modal-sheet chrome.
///
/// [sets] is passed as a future rather than a loaded list so the sheet can
/// animate in immediately and fill the breakdown when the query lands.
Future<void> showCompletionDetail(
  BuildContext context, {
  required Completion completion,
  required Future<List<CompletionSet>> sets,
  required String units,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.notebook.bg,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: context.notebook.ink, width: 2),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
    ),
    builder: (_) => CompletionDetailSheet(
      completion: completion,
      sets: sets,
      units: units,
    ),
  );
}

/// Full breakdown of a logged session: start/end times, totals, and the reps
/// (and load) logged for each set of each exercise, from the `completion_sets`
/// snapshot.
class CompletionDetailSheet extends StatelessWidget {
  const CompletionDetailSheet({
    super.key,
    required this.completion,
    required this.sets,
    required this.units,
  });

  final Completion completion;
  final Future<List<CompletionSet>> sets;

  /// Display units ([Units.metric]/[Units.imperial]) for the logged loads.
  final String units;

  static String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final n = context.notebook;

    DateTime? start;
    try {
      if (completion.startedAt != null) {
        start = DateTime.parse(completion.startedAt!);
      }
    } catch (_) {}
    final elapsed =
        (completion.durationMinutes ?? 0) * 60 + (completion.pausedSeconds ?? 0);
    final end = start?.add(Duration(seconds: elapsed));
    final totals = completionSummary(t, completion);
    final paused = completion.pausedSeconds ?? 0;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                formatCompletionDt(completion.completedOn),
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: n.ink,
                ),
              ),
              const SizedBox(height: 6),
              if (start != null && end != null)
                _meta(
                  n,
                  '${t.startTimeLabel} ${_hm(start)}  ·  ${t.endTimeLabel} ${_hm(end)}',
                ),
              if (completion.durationMinutes != null)
                _meta(
                  n,
                  '${t.totalDurationLabel}: ${formatDurationMinutes(completion.durationMinutes!)}'
                  '${paused > 0 ? '  ·  ${t.timePausedLabel} ${formatDuration(paused)}' : ''}',
                ),
              if (totals.isNotEmpty) _meta(n, totals),
              const SizedBox(height: 10),
              FutureBuilder<List<CompletionSet>>(
                future: sets,
                builder: (context, snapshot) {
                  final loaded = snapshot.data;
                  if (loaded == null) return const SizedBox(height: 24);
                  if (loaded.isEmpty) return _meta(n, t.noSetDetails);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        t.breakdownHeading,
                        style: TextStyle(
                          fontFamily: 'Caveat',
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: n.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ..._breakdown(context, t, loaded),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(NotebookPalette n, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: TextStyle(fontFamily: 'Caveat', fontSize: 18, color: n.sec),
    ),
  );

  List<Widget> _breakdown(
    BuildContext context,
    AppLocalizations t,
    List<CompletionSet> loaded,
  ) {
    final n = context.notebook;
    final widgets = <Widget>[];
    String? current;
    for (final s in loaded) {
      if (s.exerciseName != current) {
        current = s.exerciseName;
        if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 6));
        widgets.add(
          Text(
            s.exerciseName,
            style: TextStyle(
              fontFamily: 'Caveat',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: n.ink,
            ),
          ),
        );
      }
      final reps = s.reps == null ? '—' : '${s.reps} ${repUnitLabel(t, s.unit)}';
      final load = s.weightKg == null
          ? ''
          : '  ×  ${formatMeasurement(s.weightKg!, _weightMetric, units, unitLabelsFor(t))}';
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 14, top: 1),
          child: Text(
            '${t.setLabel(s.setIndex)}  —  $reps$load',
            style: TextStyle(fontFamily: 'Caveat', fontSize: 18, color: n.sec),
          ),
        ),
      );
    }
    return widgets;
  }
}

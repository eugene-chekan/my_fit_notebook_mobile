import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/routine.dart';
import '../data/models/scheduled_workout.dart';
import '../data/repositories/routine_repository.dart';
import '../data/repositories/schedule_repository.dart';
import '../l10n/app_localizations.dart';
import '../state/schedule_provider.dart';
import '../theme/notebook_theme.dart';
import '../utils/formatters.dart';
import '../utils/recurrence.dart';
import '../utils/schedule_dates.dart';
import '../widgets/glyph_button.dart';
import '../widgets/notebook_drawer.dart';
import '../widgets/notebook_header.dart';
import '../widgets/notebook_page.dart';
import '../widgets/paper_dialog.dart';
import '../widgets/pen_button.dart';
import '../widgets/schedule_options_dialog.dart';
import '../widgets/swipe_actions.dart';
import 'routine_screen.dart';

/// The planned-workouts library, reached from the side menu: upcoming plans
/// grouped by how soon they are, a quiet "missed" list, and a pinned
/// "schedule a workout" action.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late final ScheduleProvider _provider;
  final _routineRepository = RoutineRepository();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _provider = ScheduleProvider()..load();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  String _dateLabel(AppLocalizations t, String iso) {
    switch (scheduleDayKind(iso, DateTime.now())) {
      case ScheduleDayKind.today:
        return t.todayLabel;
      case ScheduleDayKind.tomorrow:
        return t.tomorrowLabel;
      case ScheduleDayKind.later:
        return formatCompletionDt(iso);
    }
  }

  Future<void> _startRoutine(int routineId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoutineScreen(routineId: routineId)),
    );
    _provider.load();
  }

  Future<DateTime?> _pickDate({DateTime? initial}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return showDatePicker(
      context: context,
      initialDate: initial ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
  }

  Future<void> _addFlow() async {
    final routines = await _routineRepository.listRoutines();
    if (!mounted) return;
    final routine = await _pickRoutine(routines);
    if (routine == null || !mounted) return;

    // One dialog settles once-vs-weekly, the days and the time; backing out of
    // it schedules nothing. From here the anchor week is the current one.
    final options = await showScheduleOptions(context, anchor: DateTime.now());
    if (options == null || !mounted) return;

    if (options.weekly) {
      await _provider.addSeries(
        routine.id,
        options.weekdays,
        time: options.time,
      );
    } else {
      await _provider.addMany(
        routine.id,
        weekOccurrences(
          anchor: DateTime.now(),
          weekdays: options.weekdays,
          notBefore: DateTime.now(),
        ),
        time: options.time,
      );
    }
  }

  Future<Routine?> _pickRoutine(List<Routine> routines) {
    final t = AppLocalizations.of(context);
    return showPaperDialog<Routine>(
      context: context,
      builder: (dialogContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.pickRoutine,
            style: TextStyle(
              fontFamily: 'Caveat',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: context.notebook.ink,
            ),
          ),
          const SizedBox(height: 8),
          if (routines.isEmpty)
            Text(
              t.startRoutineEmpty,
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 19,
                color: context.notebook.sec,
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final routine in routines)
                    InkWell(
                      onTap: () => Navigator.pop(dialogContext, routine),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          routine.name,
                          style: TextStyle(
                            fontFamily: 'Caveat',
                            fontSize: 21,
                            color: context.notebook.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _reschedule(ScheduledWorkout plan) async {
    final initial = DateTime.tryParse(plan.scheduledDate);
    final date = await _pickDate(initial: initial);
    if (date == null) return;
    await _provider.reschedule(plan.id, date);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        key: _scaffoldKey,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: NotebookPage(
                  marginChild: GlyphButton(
                    glyph: '≡',
                    size: 26,
                    semanticLabel: t.menu,
                    onTap: () => openMarginMenu(context),
                  ),
                  padding: const EdgeInsets.fromLTRB(64, 4, 18, 92),
                  child: Consumer<ScheduleProvider>(
                    builder: (context, provider, _) {
                      if (provider.loading) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          NotebookHeader(
                            title: t.navSchedule,
                            leading: const BackGlyph(),
                          ),
                          const SizedBox(height: 4),
                          if (provider.upcoming.isEmpty && provider.missed.isEmpty)
                            MutedLine(t.noUpcoming)
                          else ...[
                            if (provider.upcoming.isNotEmpty) ...[
                              HeadingLine(t.upcomingHeading),
                              for (final plan in provider.upcoming)
                                _planRow(t, plan, missed: false),
                            ],
                            if (provider.missed.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              HeadingLine(t.missedHeading),
                              for (final plan in provider.missed)
                                _planRow(t, plan, missed: true),
                            ],
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Center(
                  child: PenButtonFilled(
                    label: t.scheduleWorkout,
                    onPressed: _addFlow,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _planRow(AppLocalizations t, ScheduledWorkout plan, {required bool missed}) {
    final color = missed ? context.notebook.sec : context.notebook.ink;
    return SwipeableRow(
      itemKey: ValueKey('plan-${plan.id}'),
      onDelete: () async {
        if (plan.isRecurring) {
          final choice = await _askSeriesDelete();
          if (choice == _DeleteChoice.one) {
            await _provider.remove(plan.id);
          } else if (choice == _DeleteChoice.series) {
            // End the series from the tapped occurrence (or today, whichever is
            // earlier) forward, so this row and every later one clear out while
            // completed/missed history stays put.
            final today = ScheduleRepository.isoDate(DateTime.now());
            final from = plan.scheduledDate.compareTo(today) < 0
                ? plan.scheduledDate
                : today;
            await _provider.removeSeriesFuture(plan.ruleId!, from);
          }
          return false;
        }
        await _provider.remove(plan.id);
        return false; // provider reload rebuilds the list authoritatively
      },
      child: SizedBox(
        height: kNotebookLine,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _startRoutine(plan.routineId),
                child: Container(
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(fontFamily: 'Caveat', fontSize: 20, color: color),
                      children: [
                        TextSpan(
                          text: plan.scheduledTime == null
                              ? '${_dateLabel(t, plan.scheduledDate)}  '
                              : '${_dateLabel(t, plan.scheduledDate)} ${plan.scheduledTime}  ',
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: context.notebook.sec,
                          ),
                        ),
                        TextSpan(text: plan.routineName),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            if (plan.isRecurring)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 4),
                child: Tooltip(
                  message: t.recurringSemantic,
                  child: Icon(Icons.repeat, size: 16, color: context.notebook.sec),
                ),
              ),
            GlyphButton(
              glyph: '↻',
              size: 20,
              semanticLabel: t.rescheduleSemantic,
              onTap: () => _reschedule(plan),
            ),
          ],
        ),
      ),
    );
  }

  /// Asks whether to delete a single recurring occurrence or the whole series.
  /// Returns null if the user backs out.
  Future<_DeleteChoice?> _askSeriesDelete() {
    final t = AppLocalizations.of(context);
    return showPaperDialog<_DeleteChoice>(
      context: context,
      builder: (dialogContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.deleteSeriesTitle,
            style: TextStyle(
              fontFamily: 'Caveat',
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: dialogContext.notebook.ink,
            ),
          ),
          const SizedBox(height: 14),
          PenButton(
            label: t.deleteThisOccurrence,
            onPressed: () => Navigator.pop(dialogContext, _DeleteChoice.one),
          ),
          const SizedBox(height: 8),
          PenButton(
            label: t.deleteWholeSeries,
            danger: true,
            onPressed: () => Navigator.pop(dialogContext, _DeleteChoice.series),
          ),
        ],
      ),
    );
  }
}

/// Which part of a repeating series a swipe-delete should remove.
enum _DeleteChoice { one, series }

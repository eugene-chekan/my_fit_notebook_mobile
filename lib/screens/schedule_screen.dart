import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/routine.dart';
import '../data/models/scheduled_workout.dart';
import '../data/repositories/routine_repository.dart';
import '../l10n/app_localizations.dart';
import '../state/schedule_provider.dart';
import '../theme/notebook_theme.dart';
import '../utils/formatters.dart';
import '../utils/schedule_dates.dart';
import '../widgets/glyph_button.dart';
import '../widgets/notebook_drawer.dart';
import '../widgets/notebook_header.dart';
import '../widgets/notebook_page.dart';
import '../widgets/paper_dialog.dart';
import '../widgets/pen_button.dart';
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
    final date = await _pickDate();
    if (date == null || !mounted) return;
    final routines = await _routineRepository.listRoutines();
    if (!mounted) return;
    final routine = await _pickRoutine(routines);
    if (routine == null || !mounted) return;
    // Optional time — dismissing the picker leaves the plan date-only (no
    // reminder).
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    await _provider.add(routine.id, date, time: _hm(time));
  }

  /// TimeOfDay → "HH:mm", or null when no time was picked.
  static String? _hm(TimeOfDay? t) => t == null
      ? null
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

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
        drawer: const NotebookDrawer(),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: NotebookPage(
                  marginChild: GlyphButton(
                    glyph: '≡',
                    size: 26,
                    semanticLabel: t.menu,
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
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
    return SizedBox(
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
          GlyphButton(
            glyph: '↻',
            size: 20,
            semanticLabel: t.rescheduleSemantic,
            onTap: () => _reschedule(plan),
          ),
          GlyphButton(
            glyph: '×',
            size: 22,
            semanticLabel: t.remove,
            onTap: () => _provider.remove(plan.id),
          ),
        ],
      ),
    );
  }
}

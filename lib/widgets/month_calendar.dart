import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models/routine.dart';
import '../data/models/scheduled_workout.dart';
import '../data/repositories/schedule_repository.dart';
import '../l10n/app_localizations.dart';
import '../services/reminder_service.dart';
import '../state/calendar_provider.dart';
import '../state/routines_provider.dart';
import '../theme/notebook_theme.dart';
import '../utils/formatters.dart';
import 'glyph_button.dart';
import 'notebook_page.dart';

/// The month grid with ← month → navigation. A trained day shows a filled ink
/// dot and opens that day's history; a future/today day with a plan shows a
/// pencilled-in ring, and tapping any today/future day schedules a workout.
/// Lives on the dashboard; driven by a [CalendarProvider]. [onChanged] fires
/// after a plan is added/removed so the dashboard can refresh.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({super.key, required this.provider, this.onChanged});

  final CalendarProvider provider;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDow = DateTime(provider.year, provider.month, 1).weekday; // 1=Mon..7=Sun
    final startOffset = firstDow - 1;
    final daysInMonth = DateTime(provider.year, provider.month + 1, 0).day;
    final monthLabel =
        DateFormat.yMMMM(localeName).format(DateTime(provider.year, provider.month));
    // 2024-01-01 is a Monday, so days 1..7 give localized Mon..Sun labels.
    final dayNames = [
      for (var i = 0; i < 7; i++)
        DateFormat.E(localeName).format(DateTime(2024, 1, 1 + i)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: kNotebookLine,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GlyphButton(
                glyph: '←',
                size: 22,
                semanticLabel: t.previousMonth,
                onTap: provider.previousMonth,
              ),
              Expanded(
                child: Container(
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    monthLabel,
                    style: const TextStyle(
                      fontFamily: 'Caveat',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: NotebookColors.ink,
                    ),
                  ),
                ),
              ),
              GlyphButton(
                glyph: '→',
                size: 22,
                semanticLabel: t.nextMonth,
                onTap: provider.nextMonth,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: dayNames
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontFamily: 'Caveat',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: NotebookColors.inkSoft,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        if (!provider.loading)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startOffset) return const SizedBox.shrink();
              final day = index - startOffset + 1;
              final date = DateTime(provider.year, provider.month, day);
              final iso =
                  '${date.year.toString().padLeft(4, '0')}-'
                  '${date.month.toString().padLeft(2, '0')}-'
                  '${date.day.toString().padLeft(2, '0')}';
              final names = provider.routinesByDate[iso];
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isPast = date.isBefore(today);
              final trained = names != null;
              // A pencilled-in plan only shows on today/future days; a past
              // planned day is "missed" and isn't marked here.
              final planned = !trained && !isPast && provider.plannedByDate[iso] != null;
              VoidCallback? onTap;
              if (trained) {
                onTap = () => _showRoutines(context, iso, names);
              } else if (!isPast) {
                onTap = () => _openDaySheet(context, iso);
              }
              return _DayCell(
                day: day,
                isToday: isToday,
                trained: trained,
                planned: planned,
                onTap: onTap,
              );
            },
          ),
      ],
    );
  }

  void _showRoutines(BuildContext context, String iso, List<String> names) {
    final unique = names.toSet().toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: NotebookColors.paper,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: NotebookColors.ink, width: 2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatCompletionDt(iso),
              style: const TextStyle(
                fontFamily: 'Caveat',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: NotebookColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            for (final name in unique)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Caveat',
                    fontSize: 20,
                    color: NotebookColors.ink,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The schedule sheet for a today/future day: existing plans (removable) and
  /// a routine picker to add one.
  void _openDaySheet(BuildContext context, String iso) {
    final routines = context.read<RoutinesProvider>().routines;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NotebookColors.paper,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: NotebookColors.ink, width: 2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: _DayScheduleSheet(
          iso: iso,
          routines: routines,
          onChanged: () {
            provider.load();
            onChanged?.call();
          },
        ),
      ),
    );
  }
}

/// Bottom sheet to manage a single day's plans: lists the routines already
/// pencilled in (tap × to drop) and offers the routine list to add one.
class _DayScheduleSheet extends StatefulWidget {
  const _DayScheduleSheet({
    required this.iso,
    required this.routines,
    required this.onChanged,
  });

  final String iso;
  final List<Routine> routines;
  final VoidCallback onChanged;

  @override
  State<_DayScheduleSheet> createState() => _DayScheduleSheetState();
}

class _DayScheduleSheetState extends State<_DayScheduleSheet> {
  final _repository = ScheduleRepository();
  List<ScheduledWorkout> _plans = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final plans = await _repository.listForDate(widget.iso);
    if (mounted) setState(() => _plans = plans);
  }

  Future<void> _add(int routineId) async {
    // Optional time — dismissing the picker leaves the plan date-only.
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    await _repository.addSchedule(routineId, widget.iso, time: _hm(time));
    await ReminderService.instance.resync();
    widget.onChanged();
    await _reload();
  }

  Future<void> _remove(int id) async {
    await _repository.deleteSchedule(id);
    await ReminderService.instance.resync();
    widget.onChanged();
    await _reload();
  }

  /// TimeOfDay → "HH:mm", or null when no time was picked.
  static String? _hm(TimeOfDay? t) => t == null
      ? null
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final plannedRoutineIds = _plans.map((p) => p.routineId).toSet();
    final addable =
        widget.routines.where((r) => !plannedRoutineIds.contains(r.id)).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatCompletionDt(widget.iso),
            style: const TextStyle(
              fontFamily: 'Caveat',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: NotebookColors.ink,
            ),
          ),
          if (_plans.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final plan in _plans)
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Caveat',
                          fontSize: 20,
                          color: NotebookColors.ink,
                        ),
                        children: [
                          if (plan.scheduledTime != null)
                            TextSpan(
                              text: '${plan.scheduledTime}  ',
                              style: const TextStyle(color: NotebookColors.inkSoft),
                            ),
                          TextSpan(text: plan.routineName),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GlyphButton(
                    glyph: '×',
                    size: 22,
                    semanticLabel: t.remove,
                    onTap: () => _remove(plan.id),
                  ),
                ],
              ),
          ],
          const SizedBox(height: 10),
          Text(
            t.scheduleWorkout,
            style: const TextStyle(
              fontFamily: 'Caveat',
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: NotebookColors.inkSoft,
            ),
          ),
          const SizedBox(height: 4),
          if (widget.routines.isEmpty)
            Text(
              t.startRoutineEmpty,
              style: const TextStyle(
                fontFamily: 'Caveat',
                fontSize: 18,
                color: NotebookColors.inkSoft,
              ),
            )
          else if (addable.isEmpty)
            Text(
              t.allRoutinesPlanned,
              style: const TextStyle(
                fontFamily: 'Caveat',
                fontSize: 18,
                color: NotebookColors.inkSoft,
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final routine in addable)
                    InkWell(
                      onTap: () => _add(routine.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Text(
                              '+ ',
                              style: TextStyle(
                                fontFamily: 'Caveat',
                                fontSize: 20,
                                color: NotebookColors.inkSoft,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                routine.name,
                                style: const TextStyle(
                                  fontFamily: 'Caveat',
                                  fontSize: 20,
                                  color: NotebookColors.ink,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.trained,
    required this.planned,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool trained;
  final bool planned;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: trained ? NotebookColors.trainedFill : Colors.white.withValues(alpha: 0.12),
          border: Border.all(
            color: isToday ? NotebookColors.inkSoft : NotebookColors.ink,
            width: isToday ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 16,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                color: NotebookColors.ink,
              ),
            ),
            // A trained day gets a filled ink dot; a planned (future) day gets a
            // hollow "pencilled-in" ring.
            if (trained)
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: CircleAvatar(radius: 2.5, backgroundColor: NotebookColors.ink),
              )
            else if (planned)
              Container(
                margin: const EdgeInsets.only(top: 1),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: NotebookColors.inkSoft, width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

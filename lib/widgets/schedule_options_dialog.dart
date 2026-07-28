import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/notebook_theme.dart';
import '../utils/recurrence.dart';
import 'paper_dialog.dart';
import 'pen_button.dart';

/// What the user chose in [showScheduleOptions].
class ScheduleOptions {
  const ScheduleOptions({
    required this.weekdays,
    required this.weekly,
    this.time,
  });

  /// ISO weekday ints (1 = Mon … 7 = Sun) to book.
  final Set<int> weekdays;

  /// True for a repeating rule; false to book [weekdays] in the anchor's week
  /// only.
  final bool weekly;

  /// HH:mm, or null for a plan with no reminder.
  final String? time;
}

/// One dialog for every "when?" question in the app: once-or-weekly, which
/// weekdays, and an optional reminder time — settled together and committed by
/// a single Save, so dismissing it schedules nothing.
///
/// [anchor] is the week the choice hangs off: the tapped day on the calendar,
/// or today from the Schedule screen. Its own weekday starts out selected.
/// Returns null when the user backs out.
Future<ScheduleOptions?> showScheduleOptions(
  BuildContext context, {
  required DateTime anchor,
  String? title,
}) {
  return showPaperDialog<ScheduleOptions>(
    context: context,
    builder: (dialogContext) => _ScheduleOptionsDialog(anchor: anchor, title: title),
  );
}

class _ScheduleOptionsDialog extends StatefulWidget {
  const _ScheduleOptionsDialog({required this.anchor, this.title});

  final DateTime anchor;
  final String? title;

  @override
  State<_ScheduleOptionsDialog> createState() => _ScheduleOptionsDialogState();
}

class _ScheduleOptionsDialogState extends State<_ScheduleOptionsDialog> {
  late final Set<int> _weekdays = {widget.anchor.weekday};
  bool _weekly = false;
  TimeOfDay? _time;

  static const _isoWeekdays = [1, 2, 3, 4, 5, 6, 7];

  /// In "once" mode a weekday that has already gone by in the anchor's week
  /// can't be booked, so it is offered disabled rather than silently dropped.
  bool _isPast(int weekday) {
    if (_weekly) return false;
    return weekOccurrences(
      anchor: widget.anchor,
      weekdays: {weekday},
      notBefore: DateTime.now(),
    ).isEmpty;
  }

  /// Whether the current choice would actually book anything: a weekly rule
  /// just needs a weekday, while "once" needs one that hasn't passed yet.
  bool get _canSave => _weekly
      ? _weekdays.isNotEmpty
      : weekOccurrences(
          anchor: widget.anchor,
          weekdays: _weekdays,
          notBefore: DateTime.now(),
        ).isNotEmpty;

  String _weekdayLabel(AppLocalizations t, int iso) => switch (iso) {
        1 => t.weekdayMon,
        2 => t.weekdayTue,
        3 => t.weekdayWed,
        4 => t.weekdayThu,
        5 => t.weekdayFri,
        6 => t.weekdaySat,
        _ => t.weekdaySun,
      };

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    // Cancelling the picker leaves the current choice alone — it never
    // commits the plan on its own.
    if (picked != null) setState(() => _time = picked);
  }

  static String _hm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final n = context.notebook;
    final canSave = _canSave;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title ?? t.scheduleWorkout,
          style: TextStyle(
            fontFamily: 'Caveat',
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: n.ink,
          ),
        ),
        const SizedBox(height: 12),
        _ModeSlider(
          weekly: _weekly,
          onceLabel: t.repeatJustOnce,
          weeklyLabel: t.repeatWeekly,
          onChanged: (weekly) => setState(() => _weekly = weekly),
        ),
        const SizedBox(height: 4),
        Text(
          _weekly ? t.repeatWeeklyHint : t.repeatOnceHint,
          style: TextStyle(
            fontFamily: 'Caveat',
            fontSize: 15,
            fontStyle: FontStyle.italic,
            color: n.sec,
          ),
        ),
        const SizedBox(height: 12),
        _label(t.pickDaysLabel, n),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final d in _isoWeekdays)
              _WeekdayChip(
                label: _weekdayLabel(t, d),
                selected: _weekdays.contains(d),
                enabled: !_isPast(d),
                onTap: () => setState(() {
                  if (!_weekdays.remove(d)) _weekdays.add(d);
                }),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _label(t.timeLabel, n),
            const SizedBox(width: 8),
            InkWell(
              onTap: _pickTime,
              child: Text(
                _time == null ? t.noTimeSet : _hm(_time!),
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 20,
                  fontWeight: _time == null ? FontWeight.w500 : FontWeight.w700,
                  color: _time == null ? n.sec : n.ink,
                ),
              ),
            ),
            if (_time != null)
              IconButton(
                onPressed: () => setState(() => _time = null),
                icon: Icon(Icons.close, size: 16, color: n.sec),
                tooltip: t.clearTimeSemantic,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.only(left: 6),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PenButton(
              label: t.cancel,
              small: true,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            PenButton(
              label: t.save,
              small: true,
              onPressed: canSave
                  ? () => Navigator.pop(
                        context,
                        ScheduleOptions(
                          weekdays: {..._weekdays},
                          weekly: _weekly,
                          time: _time == null ? null : _hm(_time!),
                        ),
                      )
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _label(String text, NotebookPalette n) => Text(
        text,
        style: TextStyle(
          fontFamily: 'Caveat',
          fontSize: 17,
          fontStyle: FontStyle.italic,
          color: n.sec,
        ),
      );
}

/// A two-position slider: once ⇄ weekly. The ink thumb slides between the
/// halves, so the choice reads as one switch rather than two buttons.
class _ModeSlider extends StatelessWidget {
  const _ModeSlider({
    required this.weekly,
    required this.onceLabel,
    required this.weeklyLabel,
    required this.onChanged,
  });

  final bool weekly;
  final String onceLabel;
  final String weeklyLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final n = context.notebook;
    return LayoutBuilder(
      builder: (context, constraints) {
        final half = constraints.maxWidth / 2;
        return SizedBox(
          height: 38,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: n.ink, width: 2),
                    borderRadius: BorderRadius.circular(19),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                left: weekly ? half : 0,
                top: 0,
                bottom: 0,
                width: half,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: n.ink,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              Row(
                children: [
                  _half(context, onceLabel, active: !weekly, onTap: () => onChanged(false)),
                  _half(context, weeklyLabel, active: weekly, onTap: () => onChanged(true)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _half(
    BuildContext context,
    String label, {
    required bool active,
    required VoidCallback onTap,
  }) {
    final n = context.notebook;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Caveat',
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: active ? n.bg : n.sec,
            ),
          ),
        ),
      ),
    );
  }
}

/// A tappable weekday toggle: ink outline, filling with the accent when
/// selected, and faded out when the day can no longer be booked.
class _WeekdayChip extends StatelessWidget {
  const _WeekdayChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = context.notebook;
    final on = selected && enabled;
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: on ? n.accent : Colors.transparent,
            border: Border.all(color: on ? n.accent : n.ink, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Caveat',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: on ? n.bg : n.ink,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../state/calendar_provider.dart';
import '../theme/notebook_theme.dart';
import '../utils/formatters.dart';
import 'glyph_button.dart';
import 'notebook_page.dart';

/// The trained-days month grid with ← month → navigation. Tapping a
/// trained day opens a paper sheet listing that day's routines. Lives on
/// the dashboard page; driven by a [CalendarProvider].
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({super.key, required this.provider});

  final CalendarProvider provider;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final localeName = Localizations.localeOf(context).toString();
    final today = DateTime.now();
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
              return _DayCell(
                day: day,
                isToday: isToday,
                trained: names != null,
                onTap: names == null ? null : () => _showRoutines(context, iso, names),
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
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.trained,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool trained;
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
            if (trained)
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: CircleAvatar(radius: 2.5, backgroundColor: NotebookColors.ink),
              ),
          ],
        ),
      ),
    );
  }
}

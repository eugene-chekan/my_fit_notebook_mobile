import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/calendar_provider.dart';
import '../theme/notebook_theme.dart';
import '../utils/formatters.dart';
import '../widgets/glyph_button.dart';
import '../widgets/notebook_header.dart';
import '../widgets/notebook_page.dart';

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final CalendarProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = CalendarProvider()..load();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        body: SafeArea(
          child: NotebookPage(
            child: Consumer<CalendarProvider>(
              builder: (context, provider, _) {
                final today = DateTime.now();
                final firstDow = DateTime(provider.year, provider.month, 1).weekday; // 1=Mon..7=Sun
                final startOffset = firstDow - 1;
                final daysInMonth = DateTime(provider.year, provider.month + 1, 0).day;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BackLine(label: '← back to notebook'),
                    const NotebookHeader(title: 'Calendar'),
                    SizedBox(
                      height: kNotebookLine + 8,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GlyphButton(
                            glyph: '←',
                            size: 22,
                            semanticLabel: 'Previous month',
                            onTap: provider.previousMonth,
                          ),
                          Expanded(
                            child: Container(
                              alignment: Alignment.bottomCenter,
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                '${_monthNames[provider.month - 1]} ${provider.year}',
                                style: const TextStyle(
                                  fontFamily: 'Caveat',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: NotebookColors.ink,
                                ),
                              ),
                            ),
                          ),
                          GlyphButton(
                            glyph: '→',
                            size: 22,
                            semanticLabel: 'Next month',
                            onTap: provider.nextMonth,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: _dayNames
                          .map(
                            (d) => Expanded(
                              child: Center(
                                child: Text(
                                  d,
                                  style: const TextStyle(
                                    fontFamily: 'Caveat',
                                    fontSize: 16,
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
              },
            ),
          ),
        ),
      ),
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
                fontSize: 17,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                color: NotebookColors.ink,
              ),
            ),
            if (trained)
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: CircleAvatar(radius: 3, backgroundColor: NotebookColors.ink),
              ),
          ],
        ),
      ),
    );
  }
}

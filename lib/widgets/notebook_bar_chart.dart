import 'package:flutter/material.dart';

import '../theme/notebook_theme.dart';
import '../utils/stats_math.dart';

/// Weekly training minutes as a row of ink bars standing on a baseline rule,
/// oldest week on the left. Bars are grid-aligned [Container]s (same idiom as
/// the month calendar), each scaled against the tallest week. Empty weeks
/// leave a gap, keeping the cadence visible.
class NotebookBarChart extends StatelessWidget {
  const NotebookBarChart({super.key, required this.weeks, this.height = 118});

  final List<WeekBucket> weeks;
  final double height;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _weekLabel(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  @override
  Widget build(BuildContext context) {
    final maxMinutes = weeks.fold<int>(1, (m, w) => w.minutes > m ? w.minutes : m);
    const muted = TextStyle(
      fontFamily: 'Caveat',
      fontSize: 14,
      color: NotebookColors.inkSoft,
    );
    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final week in weeks)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: FractionallySizedBox(
                        alignment: Alignment.bottomCenter,
                        heightFactor: (week.minutes / maxMinutes).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: NotebookColors.trainedFill,
                            border: Border.all(color: NotebookColors.ink, width: 1.5),
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(2)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(height: 2, color: NotebookColors.marginLine),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_weekLabel(weeks.first.weekStart), style: muted),
              const Text('this week', style: muted),
            ],
          ),
        ],
      ),
    );
  }
}

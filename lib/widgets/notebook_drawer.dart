import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/exercises_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/routines_screen.dart';
import '../screens/schedule_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/stats_screen.dart';
import '../theme/notebook_theme.dart';
import 'notebook_page.dart';

/// The side menu, reachable from every screen. Self-contained — no
/// callbacks to wire up per screen. Each item pops the navigation stack
/// back to the dashboard (the app's single root route), then pushes the
/// chosen section, so the sidebar always jumps to a top-level destination
/// rather than stacking on top of wherever the user happened to be.
class NotebookDrawer extends StatelessWidget {
  const NotebookDrawer({super.key});

  void _go(BuildContext context, WidgetBuilder? builder) {
    final navigator = Navigator.of(context);
    Scaffold.of(context).closeDrawer();
    navigator.popUntil((route) => route.isFirst);
    if (builder != null) {
      navigator.push(MaterialPageRoute(builder: builder));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final palette = context.notebook;
    return Drawer(
      backgroundColor: palette.bg,
      // No outline — the brick double margin rule painted at the panel's right
      // edge is the sidebar's boundary, as if it were the page's left margin.
      shape: const RoundedRectangleBorder(),
      child: CustomPaint(
        painter: RuledPaperPainter(palette, marginOnRight: true),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 4, 34, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => _go(context, null),
                  child: Container(
                    height: 2 * kNotebookLine,
                    alignment: Alignment.bottomLeft,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: palette.ink, width: 2),
                      ),
                    ),
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      t.appName,
                      style: TextStyle(
                        fontFamily: 'Caveat',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                  ),
                ),
                _line(context, t.navRoutines, (_) => const RoutinesScreen()),
                _line(context, t.navSchedule, (_) => const ScheduleScreen()),
                _line(context, t.navExercises, (_) => const ExercisesScreen()),
                _line(context, t.navStats, (_) => const StatsScreen()),
                _line(context, t.navProfile, (_) => const ProfileScreen()),
                _line(context, t.navSettings, (_) => const SettingsScreen()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String label, WidgetBuilder builder) {
    return SizedBox(
      height: kNotebookLine,
      child: InkWell(
        onTap: () => _go(context, builder),
        child: Container(
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Caveat',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: context.notebook.ink,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../screens/exercises_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/routines_screen.dart';
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
    return Drawer(
      backgroundColor: NotebookColors.paper,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: NotebookColors.ink, width: 2),
      ),
      child: CustomPaint(
        painter: const RuledPaperPainter(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(64, 4, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => _go(context, null),
                  child: Container(
                    height: 2 * kNotebookLine,
                    alignment: Alignment.bottomLeft,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: NotebookColors.ink, width: 2),
                      ),
                    ),
                    padding: const EdgeInsets.only(bottom: 2),
                    child: const Text(
                      'My fit notebook',
                      style: TextStyle(
                        fontFamily: 'Caveat',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: NotebookColors.ink,
                      ),
                    ),
                  ),
                ),
                _line(context, 'Routines', (_) => const RoutinesScreen()),
                _line(context, 'Exercises', (_) => const ExercisesScreen()),
                _line(context, 'Profile', (_) => const ProfileScreen()),
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
            style: const TextStyle(
              fontFamily: 'Caveat',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: NotebookColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

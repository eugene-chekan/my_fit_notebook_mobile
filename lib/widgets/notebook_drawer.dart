import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

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

/// Open the side menu. Instead of sliding a panel in from the screen edge, the
/// menu *grows out of the page's red margin rule*: it starts at the margin's
/// width (so its red edge sits where the page's margin line is) and expands
/// rightward, as if the reader grabbed the margin and pulled it open.
Future<void> openMarginMenu(BuildContext context) {
  return Navigator.of(context).push(_MarginMenuRoute());
}

/// The width the menu opens to — a notebook-margin-ish panel, capped so it
/// never swallows the whole screen.
double _menuWidth(BuildContext context) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  return math.min(320.0, screenWidth * 0.82);
}

/// The panel's closed width: just wide enough that its right edge lands on the
/// page's margin rule at [kMarginRuleX], so the open animation appears to
/// continue that very line.
const double _menuStartWidth = kMarginRuleX + 6;

class _MarginMenuRoute extends PopupRoute<void> {
  @override
  Color get barrierColor => const Color(0x8C000000); // black ~55%

  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => 'Dismiss menu';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 230);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final palette = context.notebook;
    final fullWidth = _menuWidth(context);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, child) {
          final width = lerpDouble(_menuStartWidth, fullWidth, curved.value)!;
          return Container(
            width: width,
            height: double.infinity,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 14,
                  offset: const Offset(3, 0),
                ),
              ],
            ),
            child: Stack(
              children: [
                // The menu content is always laid out at the full open width and
                // revealed left-first, so nothing reflows as the panel widens.
                Positioned.fill(
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.centerLeft,
                      minWidth: fullWidth,
                      maxWidth: fullWidth,
                      child: SizedBox(
                        width: fullWidth,
                        child: child,
                      ),
                    ),
                  ),
                ),
                // The brick double margin rule, painted at the panel's *live*
                // right edge so it travels with the expansion. IgnorePointer so
                // this top layer never swallows taps meant for the menu items.
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _EdgeMarginPainter(palette.marginRule)),
                  ),
                ),
              ],
            ),
          );
        },
        child: const NotebookMenuPanel(),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

/// Two brick strokes at the container's right edge — the moving counterpart of
/// the page's margin rule.
class _EdgeMarginPainter extends CustomPainter {
  const _EdgeMarginPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    for (final dx in const [-2.0, 2.0]) {
      final x = size.width - 6 + dx;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgeMarginPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// The menu content: the ruled/graph ground (its own margin rule suppressed —
/// the route draws the moving one), the masthead, and the nav lines. Each item
/// pops back to the dashboard (the single root route) then pushes its section.
class NotebookMenuPanel extends StatelessWidget {
  const NotebookMenuPanel({super.key});

  void _go(BuildContext context, WidgetBuilder? builder) {
    final navigator = Navigator.of(context);
    navigator.pop(); // close the menu overlay
    navigator.popUntil((route) => route.isFirst);
    if (builder != null) {
      navigator.push(MaterialPageRoute(builder: builder));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final palette = context.notebook;
    return Material(
      color: palette.bg,
      child: CustomPaint(
        painter: RuledPaperPainter(palette, marginOnRight: true, showMargin: false),
        child: SizedBox.expand(
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
                        softWrap: false,
                        overflow: TextOverflow.clip,
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
            softWrap: false,
            overflow: TextOverflow.clip,
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

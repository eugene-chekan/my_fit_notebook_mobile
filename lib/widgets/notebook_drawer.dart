import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../app_navigator.dart';
import '../l10n/app_localizations.dart';
import '../screens/exercises_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/routines_screen.dart';
import '../screens/schedule_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/stats_screen.dart';
import '../theme/notebook_theme.dart';
import 'notebook_page.dart';

/// Open the side menu (used by the ≡ glyph). Finds the app-level
/// [MarginMenuHost] and flings it open; the drag gestures live in the host so
/// the panel can also be pulled open/closed by hand.
void openMarginMenu(BuildContext context) => _MarginMenuScope.of(context)?.open();

/// The width the menu opens to — a notebook-margin-ish panel, capped so it
/// never swallows the whole screen.
double _menuWidth(BuildContext context) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  return math.min(320.0, screenWidth * 0.82);
}

/// The panel's closed-but-visible width: its red edge lands on the page's
/// margin rule ([kMarginRuleX]), so opening looks like that line being pulled.
const double _menuStartWidth = kMarginRuleX + 6;

/// Hosts the interactive margin menu above the whole app (installed via
/// `MaterialApp.builder`). An [AnimationController] holds the open fraction
/// (0 = closed, 1 = open); a left-edge drag — or a drag on the panel — moves it
/// 1:1 with the finger, and a release flings it to settle, exactly like the
/// native drawer, but the panel *expands from the margin* instead of sliding.
class MarginMenuHost extends StatefulWidget {
  const MarginMenuHost({super.key, required this.child});

  final Widget child;

  @override
  State<MarginMenuHost> createState() => MarginMenuHostState();

  static MarginMenuHostState? of(BuildContext context) => _MarginMenuScope.of(context);
}

class MarginMenuHostState extends State<MarginMenuHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  )..addListener(_onTick);

  double _openWidth = 300;
  bool _visible = false;

  void _onTick() {
    final visible = _controller.value > 0;
    if (visible != _visible) setState(() => _visible = visible);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void open() => _controller.fling(velocity: 2.0);
  void close() => _controller.fling(velocity: -2.0);

  void _dragUpdate(DragUpdateDetails details) {
    _controller.value += (details.primaryDelta ?? 0) / _openWidth;
  }

  void _dragEnd(DragEndDetails details) {
    final vx = details.velocity.pixelsPerSecond.dx;
    if (vx.abs() >= 365) {
      _controller.fling(velocity: vx.sign * 2.0);
    } else {
      _controller.fling(velocity: _controller.value >= 0.5 ? 2.0 : -2.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.notebook;
    _openWidth = _menuWidth(context);
    return _MarginMenuScope(
      state: this,
      child: PopScope(
        // While the menu is open, the back button closes it instead of popping.
        canPop: !_visible,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) close();
        },
        child: Stack(
          children: [
            widget.child,
            // Left-edge strip: a rightward drag here pulls the menu open. Only
            // reachable when closed (the scrim covers it once open).
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 24,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: _dragUpdate,
                onHorizontalDragEnd: _dragEnd,
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final v = _controller.value;
                if (v == 0) return const SizedBox.shrink();
                final width = lerpDouble(_menuStartWidth, _openWidth, v)!;
                return Stack(
                  children: [
                    // Scrim — dims and dismisses on tap, opacity tracks the drag.
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: close,
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.5 * v),
                        ),
                      ),
                    ),
                    // The panel — draggable (left to close), taps hit the items.
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: width,
                      child: GestureDetector(
                        onHorizontalDragUpdate: _dragUpdate,
                        onHorizontalDragEnd: _dragEnd,
                        child: _MarginMenuBody(
                          width: width,
                          openWidth: _openWidth,
                          palette: palette,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MarginMenuScope extends InheritedWidget {
  const _MarginMenuScope({required this.state, required super.child});

  final MarginMenuHostState state;

  static MarginMenuHostState? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MarginMenuScope>()?.state;

  @override
  bool updateShouldNotify(_MarginMenuScope oldWidget) => false;
}

/// The panel at its current [width]: menu content laid out at the full
/// [openWidth] and revealed left-first (no reflow), with the brick margin rule
/// riding the live right edge.
class _MarginMenuBody extends StatelessWidget {
  const _MarginMenuBody({
    required this.width,
    required this.openWidth,
    required this.palette,
  });

  final double width;
  final double openWidth;
  final NotebookPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: palette.shadow, blurRadius: 14, offset: const Offset(3, 0)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: openWidth,
                maxWidth: openWidth,
                child: SizedBox(width: openWidth, child: const NotebookMenuPanel()),
              ),
            ),
          ),
          // Purely decorative — IgnorePointer so it never eats item taps.
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _EdgeMarginPainter(palette.marginRule)),
            ),
          ),
        ],
      ),
    );
  }
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
/// the host draws the moving one), the masthead, and the nav lines. Each item
/// closes the menu, pops back to the dashboard (the single root route), then
/// pushes its section.
class NotebookMenuPanel extends StatelessWidget {
  const NotebookMenuPanel({super.key});

  void _go(BuildContext context, WidgetBuilder? builder) {
    MarginMenuHost.of(context)?.close();
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/models/routine.dart';
import '../data/services/workout_service.dart';
import '../state/calendar_provider.dart';
import '../state/dashboard_provider.dart';
import '../state/routines_provider.dart';
import '../theme/notebook_theme.dart';
import '../utils/formatters.dart';
import '../widgets/glyph_button.dart';
import '../widgets/month_calendar.dart';
import '../widgets/notebook_header.dart';
import '../widgets/notebook_page.dart';
import '../widgets/paper_dialog.dart';
import '../widgets/pen_button.dart';
import 'profile_screen.dart';
import 'routine_screen.dart';
import 'routines_screen.dart';

/// The main screen: a single dashboard page — Start routine CTA, week
/// stats + streak, and the trained-days month calendar. The routine
/// library and profile live behind the margin's ≡ menu.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final RoutinesProvider _routinesProvider;
  late final DashboardProvider _dashboardProvider;
  late final CalendarProvider _calendarProvider;
  final _workoutService = WorkoutService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _routinesProvider = RoutinesProvider()..load();
    _dashboardProvider = DashboardProvider()..load();
    _calendarProvider = CalendarProvider()..load();
  }

  @override
  void dispose() {
    _routinesProvider.dispose();
    _dashboardProvider.dispose();
    _calendarProvider.dispose();
    super.dispose();
  }

  void _reloadAll() {
    _routinesProvider.load();
    _dashboardProvider.load();
    _calendarProvider.load();
  }

  Future<void> _openRoutines() async {
    _scaffoldKey.currentState?.closeDrawer();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RoutinesScreen()),
    );
    _reloadAll();
  }

  Future<void> _openProfile() async {
    _scaffoldKey.currentState?.closeDrawer();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  /// The Start routine popup: a paper note listing the routines; tapping
  /// one starts it (unless already running — then it just opens) and jumps
  /// straight to the workout screen.
  Future<void> _showStartRoutine() async {
    await _routinesProvider.load();
    if (!mounted) return;
    final routines = _routinesProvider.routines;
    final selected = await showPaperDialog<Routine>(
      context: context,
      builder: (dialogContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Start routine',
            style: TextStyle(
              fontFamily: 'Caveat',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: NotebookColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          if (routines.isEmpty)
            const Text(
              'Nothing here yet — open Routines from the menu and write one down.',
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 19,
                color: NotebookColors.inkSoft,
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
                        child: Row(
                          children: [
                            if (routine.isStarted)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.fiber_manual_record,
                                  size: 9,
                                  color: NotebookColors.ink,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                routine.name,
                                style: const TextStyle(
                                  fontFamily: 'Caveat',
                                  fontSize: 21,
                                  color: NotebookColors.ink,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Text(
                              '▸',
                              style: TextStyle(
                                fontSize: 16,
                                color: NotebookColors.inkSoft,
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
    if (selected == null || !mounted) return;
    if (!selected.isStarted) {
      HapticFeedback.mediumImpact();
      await _workoutService.startWorkout(selected.id);
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoutineScreen(routineId: selected.id)),
    );
    _reloadAll();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _routinesProvider),
        ChangeNotifierProvider.value(value: _dashboardProvider),
        ChangeNotifierProvider.value(value: _calendarProvider),
      ],
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _NotebookDrawer(onRoutines: _openRoutines, onProfile: _openProfile),
        body: SafeArea(
          child: NotebookPage(
            marginChild: GlyphButton(
              glyph: '≡',
              size: 26,
              semanticLabel: 'Menu',
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const NotebookHeader(title: 'My fit notebook'),
                Container(
                  height: kNotebookLine,
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    notebookDateLabel(DateTime.now()),
                    style: const TextStyle(
                      fontFamily: 'Caveat',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: NotebookColors.inkSoft,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: PenButtonFilled(
                      label: 'Start routine',
                      onPressed: _showStartRoutine,
                    ),
                  ),
                ),
                const HeadingLine('This week'),
                Consumer<DashboardProvider>(
                  builder: (context, stats, _) {
                    if (stats.loading) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _statLine(
                          stats.weekWorkouts == 0
                              ? 'nothing logged yet — the page is blank'
                              : '${stats.weekWorkouts} '
                                  '${stats.weekWorkouts == 1 ? 'workout' : 'workouts'}'
                                  '${stats.weekMinutes > 0 ? ' · ${formatDurationMinutes(stats.weekMinutes)}' : ''}',
                          muted: stats.weekWorkouts == 0,
                        ),
                        if (stats.streakDays > 0)
                          _statLine('${stats.streakDays}-day streak — keep the ink flowing'),
                      ],
                    );
                  },
                ),
                const HeadingLine('Training days'),
                Consumer<CalendarProvider>(
                  builder: (context, calendar, _) => MonthCalendar(provider: calendar),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statLine(String text, {bool muted = false}) {
    return Container(
      height: kNotebookLine,
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Caveat',
          fontSize: 20,
          color: muted ? NotebookColors.inkSoft : NotebookColors.ink,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// The side menu, styled as a narrower sheet of the same ruled paper.
class _NotebookDrawer extends StatelessWidget {
  const _NotebookDrawer({required this.onRoutines, required this.onProfile});

  final VoidCallback onRoutines;
  final VoidCallback onProfile;

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
                Container(
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
                _drawerLine('Routines', onRoutines),
                _drawerLine('Profile', onProfile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawerLine(String label, VoidCallback onTap) {
    return SizedBox(
      height: kNotebookLine,
      child: InkWell(
        onTap: onTap,
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

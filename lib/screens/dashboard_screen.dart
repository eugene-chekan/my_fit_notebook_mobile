import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/models/routine.dart';
import '../data/services/workout_service.dart';
import '../l10n/app_localizations.dart';
import '../route_observer.dart';
import '../state/calendar_provider.dart';
import '../state/dashboard_provider.dart';
import '../state/routines_provider.dart';
import '../theme/notebook_theme.dart';
import '../utils/formatters.dart';
import '../widgets/glyph_button.dart';
import '../widgets/month_calendar.dart';
import '../widgets/notebook_drawer.dart';
import '../widgets/notebook_header.dart';
import '../widgets/notebook_page.dart';
import '../widgets/paper_dialog.dart';
import '../widgets/pen_button.dart';
import 'routine_screen.dart';

/// The main screen: a single dashboard page — Start routine CTA, week
/// stats + streak, and the trained-days month calendar. The routine
/// library and profile live behind the margin's ≡ menu.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    appRouteObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _routinesProvider.dispose();
    _dashboardProvider.dispose();
    _calendarProvider.dispose();
    super.dispose();
  }

  /// Fires whenever a route above this one is popped — including a
  /// several-routes-at-once pop from the sidebar's cross-navigation — so
  /// the dashboard's stats/calendar are always fresh when it reappears,
  /// regardless of how the user navigated away from it.
  @override
  void didPopNext() => _reloadAll();

  void _reloadAll() {
    _routinesProvider.load();
    _dashboardProvider.load();
    _calendarProvider.load();
  }

  /// The Start routine popup: a paper note listing the routines; tapping
  /// one starts it (unless already running — then it just opens) and jumps
  /// straight to the workout screen.
  Future<void> _showStartRoutine() async {
    await _routinesProvider.load();
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    final routines = _routinesProvider.routines;
    final selected = await showPaperDialog<Routine>(
      context: context,
      builder: (dialogContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.startRoutine,
            style: const TextStyle(
              fontFamily: 'Caveat',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: NotebookColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          if (routines.isEmpty)
            Text(
              t.startRoutineEmpty,
              style: const TextStyle(
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
    // No explicit reload after this push: didPopNext (RouteAware) already
    // refreshes the dashboard whenever it becomes visible again.
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoutineScreen(routineId: selected.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _routinesProvider),
        ChangeNotifierProvider.value(value: _dashboardProvider),
        ChangeNotifierProvider.value(value: _calendarProvider),
      ],
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const NotebookDrawer(),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: NotebookPage(
                  marginChild: GlyphButton(
                    glyph: '≡',
                    size: 26,
                    semanticLabel: t.menu,
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  // Reserve room at the bottom for the pinned Start button.
                  padding: const EdgeInsets.fromLTRB(64, 4, 18, 92),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      NotebookHeader(title: t.appName),
                      Container(
                        height: kNotebookLine,
                        alignment: Alignment.bottomRight,
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          notebookDateLabel(
                            DateTime.now(),
                            Localizations.localeOf(context).languageCode,
                          ),
                          style: const TextStyle(
                            fontFamily: 'Caveat',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: NotebookColors.inkSoft,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      HeadingLine(t.thisWeek),
                      Consumer<DashboardProvider>(
                        builder: (context, stats, _) {
                          if (stats.loading) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _statLine(
                                stats.weekWorkouts == 0
                                    ? t.nothingLoggedWeek
                                    : '${t.workoutsCount(stats.weekWorkouts)}'
                                          '${stats.weekMinutes > 0 ? ' · ${formatDurationMinutes(stats.weekMinutes)}' : ''}',
                                muted: stats.weekWorkouts == 0,
                              ),
                              if (stats.streakDays > 0)
                                _statLine(t.streakLine(stats.streakDays)),
                            ],
                          );
                        },
                      ),
                      HeadingLine(t.trainingDays),
                      Consumer<CalendarProvider>(
                        builder: (context, calendar, _) =>
                            MonthCalendar(provider: calendar),
                      ),
                    ],
                  ),
                ),
              ),
              // Pinned in the bottom thumb zone, over the page.
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Center(
                  child: PenButtonFilled(
                    label: t.startRoutine,
                    onPressed: _showStartRoutine,
                  ),
                ),
              ),
            ],
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/models/routine.dart';
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
import '../widgets/swipe_actions.dart';
import 'manage_routine_screen.dart';
import 'profile_screen.dart';
import 'routine_screen.dart';

/// The main screen: two side-by-side notebook pages you swipe between —
/// page 1 is the dashboard (week stats, streak, month calendar), page 2 is
/// the routine list.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final RoutinesProvider _routinesProvider;
  late final DashboardProvider _dashboardProvider;
  late final CalendarProvider _calendarProvider;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _pageController = PageController();
  final _nameController = TextEditingController();
  bool _adding = false;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _routinesProvider = RoutinesProvider()..load();
    _dashboardProvider = DashboardProvider()..load();
    _calendarProvider = CalendarProvider()..load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _routinesProvider.dispose();
    _dashboardProvider.dispose();
    _calendarProvider.dispose();
    super.dispose();
  }

  /// Everything on both pages derives from the completion log and routine
  /// tables, so any return from a subscreen reloads all three providers.
  void _reloadAll() {
    _routinesProvider.load();
    _dashboardProvider.load();
    _calendarProvider.load();
  }

  Future<void> _openRoutine(Routine routine) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoutineScreen(routineId: routine.id)),
    );
    _reloadAll();
  }

  Future<void> _openManage(Routine routine) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ManageRoutineScreen(routineId: routine.id)),
    );
    _reloadAll();
  }

  Future<void> _openProfile() async {
    _scaffoldKey.currentState?.closeDrawer();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  Widget _menuButton() {
    return GlyphButton(
      glyph: '≡',
      size: 26,
      semanticLabel: 'Menu',
      onTap: () => _scaffoldKey.currentState?.openDrawer(),
    );
  }

  Future<bool> _confirmDelete(Routine routine) {
    return showPaperConfirm(
      context,
      title: 'Delete "${routine.name}"?',
      message: 'This removes the routine, its exercises, and its session log.',
    );
  }

  Future<void> _submitNewRoutine() async {
    final name = _nameController.text;
    if (name.trim().isEmpty) {
      setState(() => _adding = false);
      return;
    }
    await _routinesProvider.addRoutine(name);
    _nameController.clear();
    if (mounted) {
      setState(() => _adding = false);
      FocusScope.of(context).unfocus();
    }
  }

  void _cancelNewRoutine() {
    _nameController.clear();
    setState(() => _adding = false);
    FocusScope.of(context).unfocus();
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
        drawer: _NotebookDrawer(onProfile: _openProfile),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _page = page),
                  children: [
                    _dashboardPage(),
                    _routinesPage(),
                  ],
                ),
              ),
              _pageDots(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Page 1: dashboard ──

  Widget _dashboardPage() {
    return NotebookPage(
      marginChild: _menuButton(),
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
                    _statLine(
                      '${stats.streakDays}-day streak — keep the ink flowing',
                    ),
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

  // ── Page 2: routines ──

  Widget _routinesPage() {
    return NotebookPage(
      marginChild: _menuButton(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NotebookHeader(title: 'Routines'),
          Consumer<RoutinesProvider>(
            builder: (context, provider, _) {
              if (provider.loading) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  for (final routine in provider.routines) _routineRow(routine),
                  _newRoutineRow(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Swipe right to duplicate, swipe left to delete (after confirmation).
  /// The copy swipe performs its work in confirmDismiss and returns false so
  /// the row snaps back instead of dismissing.
  Widget _routineRow(Routine routine) {
    return Dismissible(
      key: ValueKey('routine-${routine.id}'),
      background: const SwipeCopyBackground(),
      secondaryBackground: const SwipeDeleteBackground(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.lightImpact();
          await _routinesProvider.duplicateRoutine(routine.id);
          return false;
        }
        return _confirmDelete(routine);
      },
      onDismissed: (_) {
        HapticFeedback.lightImpact();
        _routinesProvider.deleteRoutine(routine.id);
        _dashboardProvider.load();
        _calendarProvider.load();
      },
      child: SizedBox(
        height: kNotebookLine,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _openRoutine(routine),
                child: Container(
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (routine.isStarted)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.fiber_manual_record, size: 9, color: NotebookColors.ink),
                        ),
                      Flexible(
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
                    ],
                  ),
                ),
              ),
            ),
            GlyphButton(
              glyph: '✐',
              semanticLabel: 'Manage ${routine.name}',
              onTap: () => _openManage(routine),
            ),
          ],
        ),
      ),
    );
  }

  Widget _newRoutineRow() {
    if (!_adding) {
      return SizedBox(
        height: kNotebookLine,
        child: InkWell(
          onTap: () => setState(() => _adding = true),
          child: Container(
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.only(bottom: 3),
            child: const Text(
              '+ new routine…',
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 20,
                color: NotebookColors.inkSoft,
              ),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: kNotebookLine,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: TextField(
                controller: _nameController,
                autofocus: true,
                maxLength: 200,
                cursorColor: NotebookColors.ink,
                style: const TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 20,
                  color: NotebookColors.ink,
                ),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  counterText: '',
                  hintText: 'name…',
                  hintStyle: TextStyle(
                    fontFamily: 'Caveat',
                    fontSize: 20,
                    color: NotebookColors.inkSoft,
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _submitNewRoutine(),
              ),
            ),
          ),
          GlyphButton(
            glyph: '✓',
            color: NotebookColors.ink,
            semanticLabel: 'Create routine',
            onTap: _submitNewRoutine,
          ),
          GlyphButton(
            glyph: '×',
            size: 24,
            semanticLabel: 'Cancel',
            onTap: _cancelNewRoutine,
          ),
        ],
      ),
    );
  }

  // ── Page indicator ──

  Widget _pageDots() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 2; i++)
            GestureDetector(
              onTap: () => _pageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
              ),
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _page
                      ? NotebookColors.ink
                      : NotebookColors.ink.withValues(alpha: 0.25),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The side menu, styled as a narrower sheet of the same ruled paper.
/// Currently just Profile; future secondary screens slot in as more lines.
class _NotebookDrawer extends StatelessWidget {
  const _NotebookDrawer({required this.onProfile});

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
                SizedBox(
                  height: kNotebookLine,
                  child: InkWell(
                    onTap: onProfile,
                    child: Container(
                      alignment: Alignment.bottomLeft,
                      padding: const EdgeInsets.only(bottom: 3),
                      child: const Text(
                        'Profile',
                        style: TextStyle(
                          fontFamily: 'Caveat',
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: NotebookColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

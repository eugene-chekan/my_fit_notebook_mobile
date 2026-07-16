import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/models/routine.dart';
import '../l10n/app_localizations.dart';
import '../state/routines_provider.dart';
import '../theme/notebook_theme.dart';
import '../widgets/glyph_button.dart';
import '../widgets/notebook_drawer.dart';
import '../widgets/notebook_header.dart';
import '../widgets/notebook_page.dart';
import '../widgets/paper_dialog.dart';
import '../widgets/swipe_actions.dart';
import 'manage_routine_screen.dart';
import 'routine_screen.dart';

/// The routine library, reached from the side menu: swipeable rows
/// (right = duplicate, left = delete) and the "+ new routine…" line.
class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  late final RoutinesProvider _provider;
  final _nameController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _provider = RoutinesProvider()..load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _provider.dispose();
    super.dispose();
  }

  Future<void> _openRoutine(Routine routine) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoutineScreen(routineId: routine.id)),
    );
    _provider.load();
  }

  Future<void> _openManage(Routine routine) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ManageRoutineScreen(routineId: routine.id)),
    );
    _provider.load();
  }

  Future<void> _submitNewRoutine() async {
    final name = _nameController.text;
    if (name.trim().isEmpty) {
      setState(() => _adding = false);
      return;
    }
    await _provider.addRoutine(name);
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
    final t = AppLocalizations.of(context);
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const NotebookDrawer(),
        body: SafeArea(
          child: NotebookPage(
            marginChild: GlyphButton(
              glyph: '≡',
              size: 26,
              semanticLabel: t.menu,
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NotebookHeader(title: t.navRoutines, leading: const BackGlyph()),
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
          ),
        ),
      ),
    );
  }

  /// Swipe right to duplicate, swipe left to delete (after confirmation).
  Widget _routineRow(Routine routine) {
    final t = AppLocalizations.of(context);
    return Dismissible(
      key: ValueKey('routine-${routine.id}'),
      background: const SwipeCopyBackground(),
      secondaryBackground: const SwipeDeleteBackground(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.lightImpact();
          await _provider.duplicateRoutine(routine.id);
          return false;
        }
        return showPaperConfirm(
          context,
          title: t.deleteRoutineTitle(routine.name),
          message: t.deleteRoutineMessage,
        );
      },
      onDismissed: (_) {
        HapticFeedback.lightImpact();
        _provider.deleteRoutine(routine.id);
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
              semanticLabel: t.manageNamed(routine.name),
              onTap: () => _openManage(routine),
            ),
          ],
        ),
      ),
    );
  }

  Widget _newRoutineRow() {
    final t = AppLocalizations.of(context);
    if (!_adding) {
      return SizedBox(
        height: kNotebookLine,
        child: InkWell(
          onTap: () => setState(() => _adding = true),
          child: Container(
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              t.newRoutine,
              style: const TextStyle(
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
                decoration: InputDecoration(
                  isCollapsed: true,
                  counterText: '',
                  hintText: t.routineNameHint,
                  hintStyle: const TextStyle(
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
            semanticLabel: t.createRoutineSemantic,
            onTap: _submitNewRoutine,
          ),
          GlyphButton(
            glyph: '×',
            size: 24,
            semanticLabel: t.cancel,
            onTap: _cancelNewRoutine,
          ),
        ],
      ),
    );
  }
}

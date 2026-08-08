import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/routine.dart';
import '../l10n/app_localizations.dart';
import '../state/programs_provider.dart';
import '../state/routines_provider.dart';
import '../theme/notebook_theme.dart';
import '../widgets/glyph_button.dart';
import '../widgets/notebook_drawer.dart';
import '../widgets/notebook_header.dart';
import '../widgets/notebook_page.dart';
import '../widgets/paper_dialog.dart';
import '../widgets/pen_button.dart';
import '../widgets/pick_target_sheet.dart';
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
  final _programs = ProgramsProvider();
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
    _programs.dispose();
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

  /// Long-press a workout to file it into a program, creating one on the spot
  /// if none fits. Programs it already belongs to are ticked.
  Future<void> _addToProgram(Routine routine) async {
    final t = AppLocalizations.of(context);
    await _programs.load();
    final member = await _programs.programIdsFor(routine.id);
    if (!mounted) return;

    final choice = await showPickTarget(
      context,
      title: t.addToProgramTitle,
      createLabel: t.newProgram,
      options: [
        for (final program in _programs.programs)
          PickOption(
            id: program.id,
            label: program.name,
            detail: t.programWorkoutsCount(program.workoutCount),
            alreadyHas: member.contains(program.id),
          ),
      ],
    );
    if (choice == null || !mounted) return;

    var programId = choice;
    if (choice == newTargetId) {
      final name = await _promptProgramName();
      if (name == null || !mounted) return;
      programId = await _programs.addProgram(name);
      if (programId < 0) return;
    }

    final program = _programs.programs.where((p) => p.id == programId).firstOrNull;
    final added = await _programs.addRoutine(programId, routine.id);
    if (!mounted || program == null) return;
    showPaperSnack(
      context,
      added ? t.addedToProgram(program.name) : t.alreadyInProgram(program.name),
    );
  }

  Future<String?> _promptProgramName() {
    final t = AppLocalizations.of(context);
    final controller = TextEditingController();
    return showPaperDialog<String>(
      context: context,
      builder: (dialogContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.newProgram,
            style: TextStyle(
              fontFamily: 'Caveat',
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: dialogContext.notebook.ink,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            autofocus: true,
            maxLength: 200,
            cursorColor: dialogContext.notebook.ink,
            style: TextStyle(
              fontFamily: 'Caveat',
              fontSize: 21,
              color: dialogContext.notebook.ink,
            ),
            decoration: InputDecoration(
              isDense: true,
              counterText: '',
              hintText: t.programNameHint,
              hintStyle: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 20,
                color: dialogContext.notebook.sec,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: dialogContext.notebook.ink),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: dialogContext.notebook.ink, width: 2),
              ),
            ),
            onSubmitted: (v) => Navigator.pop(dialogContext, v),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PenButton(
                label: t.cancel,
                small: true,
                onPressed: () => Navigator.pop(dialogContext),
              ),
              const SizedBox(width: 8),
              PenButton(
                label: t.save,
                small: true,
                onPressed: () => Navigator.pop(dialogContext, controller.text),
              ),
            ],
          ),
        ],
      ),
    );
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
        body: SafeArea(
          child: NotebookPage(
            marginChild: GlyphButton(
              glyph: '≡',
              size: 26,
              semanticLabel: t.menu,
              onTap: () => openMarginMenu(context),
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
                        for (final routine in provider.routines) ...[
                          _routineRow(routine),
                          // A rule's worth of air under the freestyle row (it
                          // sorts first) so it reads as the page's standing
                          // option rather than as one of your workouts.
                          if (routine.isAdhoc) const SizedBox(height: 8),
                        ],
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
    if (routine.isAdhoc) return _adhocRow(routine);
    return SwipeableRow(
      itemKey: ValueKey('routine-${routine.id}'),
      onCopy: () => _provider.duplicateRoutine(routine.id),
      onDelete: () async {
        final confirmed = await showPaperConfirm(
          context,
          title: t.deleteRoutineTitle(routine.name),
          message: t.deleteRoutineMessage,
        );
        // The provider drops the row before it awaits the delete, so the
        // dismissal can safely play out.
        if (confirmed) await _provider.deleteRoutine(routine.id);
        return confirmed;
      },
      child: SizedBox(
        height: notebookLine(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _openRoutine(routine),
                onLongPress: () => _addToProgram(routine),
                child: Container(
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (routine.isStarted)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(Icons.fiber_manual_record, size: 9, color: context.notebook.ink),
                        ),
                      Flexible(
                        child: Text(
                          routine.name,
                          style: TextStyle(
                            fontFamily: 'Caveat',
                            fontSize: 21,
                            color: context.notebook.ink,
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

  /// The built-in freestyle workout, pinned at the top of the page.
  ///
  /// Deliberately plainer than the rows below it: no swipes (it cannot be
  /// deleted or copied), no ✐ (there is nothing to manage), and no long-press
  /// filing — a program is a plan, and this row is the opposite of one. What
  /// it gets instead is a second line saying what it is for, since "Freestyle"
  /// alone does not explain itself the first time you see it.
  Widget _adhocRow(Routine routine) {
    final t = AppLocalizations.of(context);
    return InkWell(
      onTap: () => _openRoutine(routine),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: notebookLine(context),
            child: Container(
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (routine.isStarted)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.fiber_manual_record,
                        size: 9,
                        color: context.notebook.ink,
                      ),
                    ),
                  Flexible(
                    child: Text(
                      t.adhocWorkout,
                      style: TextStyle(
                        fontFamily: 'Caveat',
                        fontSize: 21,
                        color: context.notebook.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: notebookLine(context),
            child: Container(
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.only(left: 2, bottom: 3),
              child: Text(
                t.adhocSubtitle,
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: context.notebook.sec,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _newRoutineRow() {
    final t = AppLocalizations.of(context);
    if (!_adding) {
      return SizedBox(
        height: notebookLine(context),
        child: InkWell(
          onTap: () => setState(() => _adding = true),
          child: Container(
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              t.newRoutine,
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 20,
                color: context.notebook.sec,
              ),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: notebookLine(context),
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
                cursorColor: context.notebook.ink,
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 20,
                  color: context.notebook.ink,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  counterText: '',
                  hintText: t.routineNameHint,
                  hintStyle: TextStyle(
                    fontFamily: 'Caveat',
                    fontSize: 20,
                    color: context.notebook.sec,
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _submitNewRoutine(),
              ),
            ),
          ),
          GlyphButton(
            glyph: '✓',
            color: context.notebook.ink,
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

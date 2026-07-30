import 'package:flutter/material.dart';

import '../data/models/program.dart';
import '../data/models/routine.dart';
import '../l10n/app_localizations.dart';
import '../state/programs_provider.dart';
import '../theme/notebook_theme.dart';
import '../widgets/glyph_button.dart';
import '../widgets/notebook_drawer.dart';
import '../widgets/notebook_header.dart';
import '../widgets/notebook_page.dart';
import '../widgets/paper_dialog.dart';
import '../widgets/swipe_actions.dart';
import 'routine_screen.dart';

/// One program's page: the workouts filed under it, in order. Tap to open a
/// workout; swipe left to take it out of the program (the workout itself stays
/// in the library).
class ProgramDetailScreen extends StatefulWidget {
  const ProgramDetailScreen({super.key, required this.programId});

  final int programId;

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  final _provider = ProgramsProvider();
  Program? _program;
  List<Routine> _routines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _provider.load();
    final program = _provider.programs
        .where((p) => p.id == widget.programId)
        .cast<Program?>()
        .firstWhere((p) => true, orElse: () => null);
    final routines = await _provider.routinesFor(widget.programId);
    if (!mounted) return;
    setState(() {
      _program = program;
      _routines = routines;
      _loading = false;
    });
  }

  Future<void> _openRoutine(Routine routine) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoutineScreen(routineId: routine.id)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: NotebookPage(
          marginChild: GlyphButton(
            glyph: '≡',
            size: 26,
            semanticLabel: t.menu,
            onTap: () => openMarginMenu(context),
          ),
          child: _loading
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NotebookHeader(
                      title: _program?.name ?? t.navPrograms,
                      leading: const BackGlyph(),
                    ),
                    const SizedBox(height: 4),
                    if (_routines.isEmpty)
                      MutedLine(t.emptyProgram)
                    else
                      for (final routine in _routines) _routineRow(t, routine),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _routineRow(AppLocalizations t, Routine routine) {
    return SwipeableRow(
      itemKey: ValueKey('program-routine-${routine.id}'),
      onDelete: () async {
        final confirmed = await showPaperConfirm(
          context,
          title: t.removeFromProgramTitle(routine.name),
          message: t.removeFromProgramMessage,
        );
        if (confirmed) {
          await _provider.removeRoutine(widget.programId, routine.id);
          await _load();
        }
        return false; // the reload above is what rebuilds the list
      },
      child: SizedBox(
        height: notebookLine(context),
        child: InkWell(
          onTap: () => _openRoutine(routine),
          child: Container(
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
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
    );
  }
}

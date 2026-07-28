import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/program.dart';
import '../l10n/app_localizations.dart';
import '../state/programs_provider.dart';
import '../theme/notebook_theme.dart';
import '../widgets/glyph_button.dart';
import '../widgets/notebook_drawer.dart';
import '../widgets/notebook_header.dart';
import '../widgets/notebook_page.dart';
import '../widgets/paper_dialog.dart';
import '../widgets/swipe_actions.dart';
import 'program_detail_screen.dart';

/// The programs library: named groups of workouts (a training split on one
/// page). Rows swipe right to copy and left to delete, like every other list.
class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  late final ProgramsProvider _provider;
  final _nameController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _provider = ProgramsProvider()..load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _provider.dispose();
    super.dispose();
  }

  Future<void> _open(Program program) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProgramDetailScreen(programId: program.id)),
    );
    _provider.load();
  }

  Future<void> _submitNew() async {
    final name = _nameController.text;
    if (name.trim().isEmpty) {
      setState(() => _adding = false);
      return;
    }
    await _provider.addProgram(name);
    _nameController.clear();
    if (mounted) {
      setState(() => _adding = false);
      FocusScope.of(context).unfocus();
    }
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
                NotebookHeader(title: t.navPrograms, leading: const BackGlyph()),
                Consumer<ProgramsProvider>(
                  builder: (context, provider, _) {
                    if (provider.loading) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 4),
                        if (provider.programs.isEmpty) MutedLine(t.noPrograms),
                        for (final program in provider.programs) _programRow(program),
                        _newProgramRow(),
                        const SizedBox(height: 8),
                        MutedLine(t.programsHint),
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

  Widget _programRow(Program program) {
    final t = AppLocalizations.of(context);
    return SwipeableRow(
      itemKey: ValueKey('program-${program.id}'),
      onCopy: () => _provider.duplicateProgram(program.id),
      onDelete: () async {
        final confirmed = await showPaperConfirm(
          context,
          title: t.deleteProgramTitle(program.name),
          message: t.deleteProgramMessage,
        );
        if (confirmed) await _provider.deleteProgram(program.id);
        return confirmed;
      },
      child: SizedBox(
        height: kNotebookLine,
        child: InkWell(
          onTap: () => _open(program),
          child: Container(
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.only(bottom: 3),
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 21,
                  color: context.notebook.ink,
                ),
                children: [
                  TextSpan(text: program.name),
                  TextSpan(
                    text: '   ${t.programWorkoutsCount(program.workoutCount)}',
                    style: TextStyle(fontSize: 17, color: context.notebook.sec),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _newProgramRow() {
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
              t.newProgram,
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
                cursorColor: context.notebook.ink,
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 20,
                  color: context.notebook.ink,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  counterText: '',
                  hintText: t.programNameHint,
                  hintStyle: TextStyle(
                    fontFamily: 'Caveat',
                    fontSize: 20,
                    color: context.notebook.sec,
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _submitNew(),
              ),
            ),
          ),
          GlyphButton(
            glyph: '✓',
            semanticLabel: t.createProgramSemantic,
            onTap: _submitNew,
          ),
        ],
      ),
    );
  }
}

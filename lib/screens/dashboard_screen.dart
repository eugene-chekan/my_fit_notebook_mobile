import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/routine.dart';
import '../state/routines_provider.dart';
import '../theme/notebook_theme.dart';
import '../utils/formatters.dart';
import '../widgets/glyph_button.dart';
import '../widgets/notebook_header.dart';
import '../widgets/notebook_page.dart';
import '../widgets/paper_dialog.dart';
import 'calendar_screen.dart';
import 'manage_routine_screen.dart';
import 'routine_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final RoutinesProvider _provider;
  final _nameController = TextEditingController();
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

  Future<void> _openManage(Routine routine) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ManageRoutineScreen(routineId: routine.id)),
    );
    _provider.load();
  }

  Future<void> _confirmDelete(Routine routine) async {
    final confirmed = await showPaperConfirm(
      context,
      title: 'Delete "${routine.name}"?',
      message: 'This removes the routine, its exercises, and its session log.',
    );
    if (confirmed) await _provider.deleteRoutine(routine.id);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        body: SafeArea(
          child: NotebookPage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const NotebookHeader(title: 'My fit notebook'),
                _dateRow(context),
                const HeadingLine('Routines'),
                Consumer<RoutinesProvider>(
                  builder: (context, provider, _) {
                    if (provider.loading) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final routine in provider.routines)
                          _routineRow(routine),
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

  /// Handwritten date under the title — tapping it opens the calendar,
  /// like the web header's date button.
  Widget _dateRow(BuildContext context) {
    return Container(
      height: kNotebookLine,
      alignment: Alignment.bottomRight,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CalendarScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 3, left: 12),
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
      ),
    );
  }

  Widget _routineRow(Routine routine) {
    return SizedBox(
      height: kNotebookLine,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => RoutineScreen(routineId: routine.id)),
              ),
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
          GlyphButton(
            glyph: '×',
            size: 24,
            semanticLabel: 'Delete ${routine.name}',
            onTap: () => _confirmDelete(routine),
          ),
        ],
      ),
    );
  }

  /// A faint "+ new routine…" line at the end of the list; tapping it turns
  /// the line into an input, like starting a new entry on the page.
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
}

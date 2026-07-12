import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/models/exercise.dart';
import '../state/routine_detail_provider.dart';
import '../theme/notebook_theme.dart';
import '../widgets/glyph_button.dart';
import '../widgets/notebook_header.dart';
import '../widgets/notebook_page.dart';
import '../utils/exercise_suggestions.dart';
import '../widgets/paper_dialog.dart';
import '../widgets/pen_button.dart';
import '../widgets/swipe_actions.dart';

class ManageRoutineScreen extends StatefulWidget {
  const ManageRoutineScreen({super.key, required this.routineId});

  final int routineId;

  @override
  State<ManageRoutineScreen> createState() => _ManageRoutineScreenState();
}

class _ManageRoutineScreenState extends State<ManageRoutineScreen> {
  late final RoutineDetailProvider _provider;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _newExerciseController = TextEditingController();
  final _newExerciseFocus = FocusNode();
  bool _initializedFields = false;

  @override
  void initState() {
    super.initState();
    _provider = RoutineDetailProvider(widget.routineId)..load();
    _provider.addListener(_syncFieldsOnce);
  }

  void _syncFieldsOnce() {
    if (_initializedFields || _provider.routine == null) return;
    _nameController.text = _provider.routine!.name;
    _descriptionController.text = _provider.routine!.description;
    _initializedFields = true;
  }

  @override
  void dispose() {
    _provider.removeListener(_syncFieldsOnce);
    _nameController.dispose();
    _descriptionController.dispose();
    _newExerciseController.dispose();
    _newExerciseFocus.dispose();
    _provider.dispose();
    super.dispose();
  }

  Future<void> _saveDetails() async {
    await _provider.updateDetails(_nameController.text, _descriptionController.text);
    if (mounted) FocusScope.of(context).unfocus();
  }

  /// Adds whatever is typed in the field (Enter or the ✓ button).
  Future<void> _addExercise() async {
    await _addNamed(_newExerciseController.text);
  }

  /// Adds [name] (used both by typed submit and by tapping a suggestion),
  /// clearing the field afterward and keeping focus for a quick next entry.
  Future<void> _addNamed(String name) async {
    if (name.trim().isEmpty) return;
    await _provider.addExercise(name);
    if (!mounted) return;
    _newExerciseController.clear();
    _newExerciseFocus.requestFocus();
  }

  Future<void> _confirmDeleteRoutine() async {
    final confirmed = await showPaperConfirm(
      context,
      title: 'Delete this routine?',
      message: 'This removes the routine, its exercises, and its session log.',
    );
    if (confirmed) {
      await _provider.deleteRoutine();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<bool> _confirmDeleteExercise(Exercise exercise) {
    return showPaperConfirm(
      context,
      title: 'Remove "${exercise.name}"?',
      message: 'Remove this exercise from the routine?',
      confirmLabel: 'Remove',
    );
  }

  Future<void> _renameExercise(Exercise exercise) async {
    final controller = TextEditingController(text: exercise.name);
    final name = await showPaperDialog<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Rename exercise',
            style: TextStyle(
              fontFamily: 'Caveat',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: NotebookColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            autofocus: true,
            maxLength: 200,
            cursorColor: NotebookColors.ink,
            style: const TextStyle(
              fontFamily: 'Caveat',
              fontSize: 20,
              color: NotebookColors.ink,
            ),
            decoration: const InputDecoration(
              isDense: true,
              counterText: '',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: NotebookColors.ink),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: NotebookColors.ink, width: 2),
              ),
            ),
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PenButton(
                label: 'Cancel',
                small: true,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              PenButton(
                label: 'Save',
                small: true,
                onPressed: () => Navigator.pop(context, controller.text),
              ),
            ],
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await _provider.renameExercise(exercise.id, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        body: SafeArea(
          child: NotebookPage(
            child: Consumer<RoutineDetailProvider>(
              builder: (context, provider, _) {
                if (provider.routine == null) return const SizedBox.shrink();
                _syncFieldsOnce();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BackLine(),
                    const NotebookHeader(title: 'Manage routine'),
                    const SizedBox(height: 8),
                    const HeadingLine('Routine details'),
                    _fieldLabel('Name'),
                    TextField(
                      controller: _nameController,
                      maxLength: 200,
                      cursorColor: NotebookColors.ink,
                      style: const TextStyle(fontFamily: 'Caveat', fontSize: 20),
                      decoration: _underlineDecoration(),
                    ),
                    const SizedBox(height: 10),
                    _fieldLabel('Description'),
                    TextField(
                      controller: _descriptionController,
                      maxLength: 1000,
                      maxLines: 3,
                      cursorColor: NotebookColors.ink,
                      style: const TextStyle(fontFamily: 'Caveat', fontSize: 18),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: "What's this routine for?",
                        hintStyle: const TextStyle(
                          fontFamily: 'Caveat',
                          color: NotebookColors.inkSoft,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: NotebookColors.inkSoft, width: 1.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: NotebookColors.ink, width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: PenButton(label: 'Save details', onPressed: _saveDetails),
                    ),
                    const SizedBox(height: 16),
                    const HeadingLine('Exercises'),
                    _addExerciseRow(),
                    if (provider.exercises.isEmpty)
                      const MutedLine('No exercises yet — add one above.')
                    else
                      _ReorderableExerciseList(
                        exercises: provider.exercises,
                        onReorder: (ids) => provider.reorderExercises(ids),
                        onRename: _renameExercise,
                        onConfirmDelete: _confirmDeleteExercise,
                        onDelete: (ex) {
                          HapticFeedback.lightImpact();
                          provider.deleteExercise(ex.id);
                        },
                        onDuplicate: (ex) {
                          HapticFeedback.lightImpact();
                          provider.duplicateExercise(ex.id);
                        },
                      ),
                    const SizedBox(height: 28),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: PenButton(
                        label: 'Delete routine',
                        danger: true,
                        onPressed: _confirmDeleteRoutine,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Caveat',
          fontSize: 17,
          fontStyle: FontStyle.italic,
          color: NotebookColors.inkSoft,
        ),
      ),
    );
  }

  InputDecoration _underlineDecoration() {
    return const InputDecoration(
      isDense: true,
      counterText: '',
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: NotebookColors.ink),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: NotebookColors.ink, width: 2),
      ),
    );
  }

  Widget _addExerciseRow() {
    return SizedBox(
      height: kNotebookLine,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => RawAutocomplete<String>(
                textEditingController: _newExerciseController,
                focusNode: _newExerciseFocus,
                optionsBuilder: (value) => filterExerciseSuggestions(
                  query: value.text,
                  catalog: _provider.catalogNames,
                  existing: _provider.exercises.map((e) => e.name),
                ),
                onSelected: _addNamed,
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLength: 200,
                      cursorColor: NotebookColors.ink,
                      style: const TextStyle(
                        fontFamily: 'Caveat',
                        fontSize: 19,
                        color: NotebookColors.ink,
                      ),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        counterText: '',
                        hintText: '+ add an exercise…',
                        hintStyle: TextStyle(
                          fontFamily: 'Caveat',
                          fontSize: 19,
                          color: NotebookColors.inkSoft,
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _addExercise(),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) =>
                    _SuggestionsOverlay(
                      onSelected: onSelected,
                      options: options.toList(),
                      width: constraints.maxWidth,
                    ),
              ),
            ),
          ),
          GlyphButton(
            glyph: '✓',
            color: NotebookColors.ink,
            semanticLabel: 'Add exercise',
            onTap: _addExercise,
          ),
        ],
      ),
    );
  }
}

/// The floating suggestion list under the add-exercise field, styled as a
/// small paper note (paper fill, 2px ink border, slightly uneven corners).
class _SuggestionsOverlay extends StatelessWidget {
  const _SuggestionsOverlay({
    required this.onSelected,
    required this.options,
    required this.width,
  });

  final void Function(String) onSelected;
  final List<String> options;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: width,
          constraints: const BoxConstraints(maxHeight: 216),
          decoration: BoxDecoration(
            color: NotebookColors.paper,
            border: Border.all(color: NotebookColors.ink, width: 2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(6),
              bottomRight: Radius.circular(5),
              bottomLeft: Radius.circular(4),
            ),
            boxShadow: const [
              BoxShadow(color: NotebookColors.shadow, blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final name = options[index];
              return InkWell(
                onTap: () => onSelected(name),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Caveat',
                      fontSize: 19,
                      color: NotebookColors.ink,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReorderableExerciseList extends StatelessWidget {
  const _ReorderableExerciseList({
    required this.exercises,
    required this.onReorder,
    required this.onRename,
    required this.onConfirmDelete,
    required this.onDelete,
    required this.onDuplicate,
  });

  final List<Exercise> exercises;
  final void Function(List<int> orderedIds) onReorder;
  final void Function(Exercise exercise) onRename;
  final Future<bool> Function(Exercise exercise) onConfirmDelete;
  final void Function(Exercise exercise) onDelete;
  final void Function(Exercise exercise) onDuplicate;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exercises.length,
      onReorderItem: (oldIndex, newIndex) {
        final ids = exercises.map((e) => e.id).toList();
        final moved = ids.removeAt(oldIndex);
        ids.insert(newIndex, moved);
        onReorder(ids);
      },
      itemBuilder: (context, index) {
        final ex = exercises[index];
        // Swipe right duplicates (row snaps back), swipe left deletes after
        // the paper confirm. Long-press still drags to reorder.
        return Dismissible(
          key: ValueKey(ex.id),
          background: const SwipeCopyBackground(),
          secondaryBackground: const SwipeDeleteBackground(),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              onDuplicate(ex);
              return false;
            }
            return onConfirmDelete(ex);
          },
          onDismissed: (_) => onDelete(ex),
          child: SizedBox(
            height: kNotebookLine,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 5, right: 8),
                  child: Text(
                    '≡',
                    style: TextStyle(fontSize: 18, height: 1, color: NotebookColors.inkSoft),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      ex.name,
                      style: const TextStyle(
                        fontFamily: 'Caveat',
                        fontSize: 20,
                        color: NotebookColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                GlyphButton(
                  glyph: '✐',
                  semanticLabel: 'Rename ${ex.name}',
                  onTap: () => onRename(ex),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

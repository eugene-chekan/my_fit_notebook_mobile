import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/models/exercise.dart';
import '../data/models/rep_unit.dart';
import '../l10n/app_localizations.dart';
import '../state/routine_detail_provider.dart';
import '../theme/notebook_theme.dart';
import '../utils/exercise_suggestions.dart';
import '../utils/formatters.dart';
import '../widgets/glyph_button.dart';
import '../widgets/notebook_drawer.dart';
import '../widgets/notebook_header.dart';
import '../widgets/notebook_page.dart';
import '../widgets/paper_dialog.dart';
import '../widgets/pen_button.dart';
import '../widgets/sets_reps_dialog.dart';
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
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

  /// Adds [name] (typed submit or a tapped suggestion): opens the sets/reps
  /// form prefilled from the exercise's catalog defaults, then adds it to
  /// this routine with that per-routine prescription.
  Future<void> _addNamed(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final defaults = _provider.catalogEntryFor(trimmed);
    final rx = await showSetsRepsDialog(
      context,
      title: AppLocalizations.of(context).addNamedTitle(trimmed),
      sets: defaults?.defaultSets,
      repsMin: defaults?.defaultReps,
      repsMax: defaults?.defaultRepsMax,
      unit: defaults?.defaultUnit ?? RepUnit.reps,
    );
    if (rx == null) return; // cancelled
    await _provider.addExercise(
      trimmed,
      sets: rx.sets,
      repsMin: rx.repsMin,
      repsMax: rx.repsMax,
      unit: rx.unit,
    );
    if (!mounted) return;
    _newExerciseController.clear();
    _newExerciseFocus.requestFocus();
  }

  /// Edits the per-routine sets/reps for an existing exercise (the ✐ glyph).
  Future<void> _editPrescription(Exercise ex) async {
    final rx = await showSetsRepsDialog(
      context,
      title: ex.name,
      sets: ex.sets,
      repsMin: ex.repsMin,
      repsMax: ex.repsMax,
      unit: ex.unit,
    );
    if (rx == null) return;
    await _provider.updatePrescription(
      ex.id,
      sets: rx.sets,
      repsMin: rx.repsMin,
      repsMax: rx.repsMax,
      unit: rx.unit,
    );
  }

  Future<void> _confirmDeleteRoutine() async {
    final t = AppLocalizations.of(context);
    final confirmed = await showPaperConfirm(
      context,
      title: t.deleteRoutineConfirmTitle,
      message: t.deleteRoutineMessage,
    );
    if (confirmed) {
      await _provider.deleteRoutine();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<bool> _confirmDeleteExercise(Exercise exercise) {
    final t = AppLocalizations.of(context);
    return showPaperConfirm(
      context,
      title: t.removeExerciseTitle(exercise.name),
      message: t.removeExerciseMessage,
      confirmLabel: t.remove,
    );
  }


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        key: _scaffoldKey,
        body: SafeArea(
          child: NotebookPage(
            marginChild: GlyphButton(
              glyph: '≡',
              size: 26,
              semanticLabel: AppLocalizations.of(context).menu,
              onTap: () => openMarginMenu(context),
            ),
            child: Consumer<RoutineDetailProvider>(
              builder: (context, provider, _) {
                if (provider.routine == null) return const SizedBox.shrink();
                _syncFieldsOnce();
                final t = AppLocalizations.of(context);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NotebookHeader(title: t.manageRoutineTitle, leading: const BackGlyph()),
                    const SizedBox(height: 8),
                    HeadingLine(t.routineDetails),
                    _fieldLabel(t.fieldName),
                    TextField(
                      controller: _nameController,
                      maxLength: 200,
                      cursorColor: context.notebook.ink,
                      style: const TextStyle(fontFamily: 'Caveat', fontSize: 20),
                      decoration: _underlineDecoration(),
                    ),
                    const SizedBox(height: 10),
                    _fieldLabel(t.fieldDescription),
                    TextField(
                      controller: _descriptionController,
                      maxLength: 1000,
                      maxLines: 3,
                      cursorColor: context.notebook.ink,
                      style: const TextStyle(fontFamily: 'Caveat', fontSize: 18),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: t.routineDescHint,
                        hintStyle: TextStyle(
                          fontFamily: 'Caveat',
                          color: context.notebook.sec,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: context.notebook.sec, width: 1.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: context.notebook.ink, width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: PenButton(label: t.saveDetails, onPressed: _saveDetails),
                    ),
                    const SizedBox(height: 16),
                    HeadingLine(t.navExercises),
                    _addExerciseRow(),
                    if (provider.exercises.isEmpty)
                      MutedLine(t.noExercisesManage)
                    else
                      _ReorderableExerciseList(
                        exercises: provider.exercises,
                        onReorder: (ids) => provider.reorderExercises(ids),
                        onEditPrescription: _editPrescription,
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
                        label: t.deleteRoutineButton,
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
        style: TextStyle(
          fontFamily: 'Caveat',
          fontSize: 17,
          fontStyle: FontStyle.italic,
          color: context.notebook.sec,
        ),
      ),
    );
  }

  InputDecoration _underlineDecoration() {
    return InputDecoration(
      isDense: true,
      counterText: '',
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: context.notebook.ink),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: context.notebook.ink, width: 2),
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
                      cursorColor: context.notebook.ink,
                      style: TextStyle(
                        fontFamily: 'Caveat',
                        fontSize: 19,
                        color: context.notebook.ink,
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        counterText: '',
                        hintText: AppLocalizations.of(context).addExerciseHint,
                        hintStyle: TextStyle(
                          fontFamily: 'Caveat',
                          fontSize: 19,
                          color: context.notebook.sec,
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
            color: context.notebook.ink,
            semanticLabel: AppLocalizations.of(context).addExerciseSemantic,
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
            color: context.notebook.bg,
            border: Border.all(color: context.notebook.ink, width: 2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(6),
              bottomRight: Radius.circular(5),
              bottomLeft: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(color: context.notebook.shadow, blurRadius: 10, offset: const Offset(0, 3)),
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
                    style: TextStyle(
                      fontFamily: 'Caveat',
                      fontSize: 19,
                      color: context.notebook.ink,
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
    required this.onEditPrescription,
    required this.onConfirmDelete,
    required this.onDelete,
    required this.onDuplicate,
  });

  final List<Exercise> exercises;
  final void Function(List<int> orderedIds) onReorder;
  final void Function(Exercise exercise) onEditPrescription;
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 5, right: 8),
                  child: Text(
                    '≡',
                    style: TextStyle(fontSize: 18, height: 1, color: context.notebook.sec),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => onEditPrescription(ex),
                    child: Container(
                      alignment: Alignment.bottomLeft,
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontFamily: 'Caveat',
                            fontSize: 20,
                            color: context.notebook.ink,
                          ),
                          children: [
                            TextSpan(text: ex.name),
                            if (formatPrescription(ex.sets, ex.repsMin, ex.repsMax, ex.unit)
                                .isNotEmpty)
                              TextSpan(
                                text:
                                    '  ${formatPrescription(ex.sets, ex.repsMin, ex.repsMax, ex.unit)}',
                                style: TextStyle(color: context.notebook.sec),
                              ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                GlyphButton(
                  glyph: '✐',
                  semanticLabel:
                      AppLocalizations.of(context).editPrescriptionSemantic(ex.name),
                  onTap: () => onEditPrescription(ex),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

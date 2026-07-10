import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/exercise.dart';
import '../state/routine_detail_provider.dart';
import '../theme/notebook_theme.dart';
import '../widgets/notebook_header.dart';
import '../widgets/notebook_page.dart';
import '../widgets/pen_button.dart';

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
    super.dispose();
  }

  Future<void> _saveDetails() async {
    await _provider.updateDetails(_nameController.text, _descriptionController.text);
    if (mounted) FocusScope.of(context).unfocus();
  }

  Future<void> _addExercise() async {
    final name = _newExerciseController.text;
    if (name.trim().isEmpty) return;
    await _provider.addExercise(name);
    _newExerciseController.clear();
    if (mounted) FocusScope.of(context).unfocus();
  }

  Future<void> _confirmDeleteRoutine() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this routine?'),
        content: const Text('This removes the routine, its exercises, and its session logs.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await _provider.deleteRoutine();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _renameExercise(Exercise exercise) async {
    final controller = TextEditingController(text: exercise.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename exercise'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
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
                if (provider.loading || provider.routine == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                _syncFieldsOnce();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NotebookHeader(
                      title: 'Manage routine',
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back, color: NotebookColors.inkSoft),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          const SizedBox(height: 12),
                          const _SectionTitle('Routine details'),
                          const SizedBox(height: 6),
                          const Text(
                            'Name',
                            style: TextStyle(fontFamily: 'Caveat', fontSize: 18, fontStyle: FontStyle.italic, color: NotebookColors.inkSoft),
                          ),
                          TextField(
                            controller: _nameController,
                            maxLength: 200,
                            style: const TextStyle(fontFamily: 'Caveat', fontSize: 20),
                            decoration: const InputDecoration(
                              counterText: '',
                              border: UnderlineInputBorder(borderSide: BorderSide(color: NotebookColors.ink)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Description',
                            style: TextStyle(fontFamily: 'Caveat', fontSize: 18, fontStyle: FontStyle.italic, color: NotebookColors.inkSoft),
                          ),
                          TextField(
                            controller: _descriptionController,
                            maxLength: 1000,
                            maxLines: 3,
                            style: const TextStyle(fontFamily: 'Caveat', fontSize: 18),
                            decoration: const InputDecoration(
                              hintText: "What's this routine for?",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: PenButton(label: 'Save details', onPressed: _saveDetails),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              const Expanded(child: _SectionTitle('Exercises')),
                              const Icon(Icons.drag_indicator, size: 16, color: NotebookColors.inkSoft),
                              const SizedBox(width: 2),
                              const Text(
                                'drag to reorder',
                                style: TextStyle(fontFamily: 'Caveat', fontSize: 15, color: NotebookColors.inkSoft),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newExerciseController,
                                  maxLength: 200,
                                  style: const TextStyle(fontFamily: 'Caveat', fontSize: 19),
                                  decoration: const InputDecoration(
                                    hintText: 'Name…',
                                    isDense: true,
                                    counterText: '',
                                    border: UnderlineInputBorder(borderSide: BorderSide(color: NotebookColors.ink)),
                                  ),
                                  onSubmitted: (_) => _addExercise(),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check, color: NotebookColors.ink),
                                tooltip: 'Add',
                                onPressed: _addExercise,
                              ),
                            ],
                          ),
                          if (provider.exercises.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                'No exercises yet — add one above.',
                                style: TextStyle(fontFamily: 'Caveat', fontSize: 19, color: NotebookColors.inkSoft),
                              ),
                            )
                          else
                            _ReorderableExerciseList(
                              exercises: provider.exercises,
                              onReorder: (ids) => provider.reorderExercises(ids),
                              onRename: _renameExercise,
                              onDelete: (id) => provider.deleteExercise(id),
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
                          const SizedBox(height: 16),
                        ],
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
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Caveat',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: NotebookColors.ink,
      ),
    );
  }
}

class _ReorderableExerciseList extends StatelessWidget {
  const _ReorderableExerciseList({
    required this.exercises,
    required this.onReorder,
    required this.onRename,
    required this.onDelete,
  });

  final List<Exercise> exercises;
  final void Function(List<int> orderedIds) onReorder;
  final void Function(Exercise exercise) onRename;
  final void Function(int exerciseId) onDelete;

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
        return Padding(
          key: ValueKey(ex.id),
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            children: [
              const Icon(Icons.drag_handle, size: 18, color: NotebookColors.inkSoft),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  ex.name,
                  style: const TextStyle(fontFamily: 'Caveat', fontSize: 20, color: NotebookColors.ink),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: NotebookColors.inkSoft),
                onPressed: () => onRename(ex),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: NotebookColors.inkSoft),
                onPressed: () => onDelete(ex.id),
              ),
            ],
          ),
        );
      },
    );
  }
}

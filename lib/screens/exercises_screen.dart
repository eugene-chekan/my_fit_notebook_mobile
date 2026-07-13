import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/models/exercise_catalog.dart';
import '../data/models/rep_unit.dart';
import '../state/exercise_catalog_provider.dart';
import '../theme/notebook_theme.dart';
import '../utils/formatters.dart';
import '../widgets/notebook_header.dart';
import '../widgets/notebook_page.dart';
import '../widgets/paper_dialog.dart';
import '../widgets/pen_button.dart';
import '../widgets/swipe_actions.dart';

/// The exercise library: create / edit / delete catalog exercises with a
/// name, description, and default sets/reps. Reached from the sidebar.
class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  late final ExerciseCatalogProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ExerciseCatalogProvider()..load();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final result = await showPaperDialog<_ExerciseFormResult>(
      context: context,
      builder: (context) => const _ExerciseForm(title: 'New exercise'),
    );
    if (result == null) return;
    final ok = await _provider.create(
      name: result.name,
      description: result.description,
      defaultSets: result.sets,
      defaultReps: result.repsMin,
      defaultRepsMax: result.repsMax,
      defaultUnit: result.unit,
    );
    if (!ok && mounted) {
      _snack('“${result.name}” already exists.');
    }
  }

  Future<void> _edit(CatalogEntry entry) async {
    final result = await showPaperDialog<_ExerciseFormResult>(
      context: context,
      builder: (context) => _ExerciseForm(title: 'Edit exercise', entry: entry),
    );
    if (result == null) return;
    final ok = await _provider.update(
      entry.copyWith(
        name: result.name,
        description: result.description,
        defaultSets: result.sets,
        defaultReps: result.repsMin,
        defaultRepsMax: result.repsMax,
        defaultUnit: result.unit,
      ),
    );
    if (!ok && mounted) {
      _snack('Another exercise is already called “${result.name}”.');
    }
  }

  Future<void> _delete(CatalogEntry entry) async {
    final uses = await _provider.usageCount(entry.id);
    if (!mounted) return;
    final message = uses == 0
        ? 'Remove “${entry.name}” from the library?'
        : 'Remove “${entry.name}” from the library? '
            'It stays in the $uses routine${uses == 1 ? '' : 's'} already using it.';
    final confirmed = await showPaperConfirm(
      context,
      title: 'Delete exercise?',
      message: message,
      confirmLabel: 'Delete',
    );
    if (confirmed) await _provider.delete(entry.id);
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: NotebookColors.ink,
        content: Text(
          text,
          style: const TextStyle(fontFamily: 'Caveat', fontSize: 18, color: NotebookColors.paper),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        body: SafeArea(
          child: NotebookPage(
            child: Consumer<ExerciseCatalogProvider>(
              builder: (context, provider, _) {
                if (provider.loading) {
                  return const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BackLine(label: '← back to notebook'),
                      NotebookHeader(title: 'Exercises'),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BackLine(label: '← back to notebook'),
                    const NotebookHeader(title: 'Exercises'),
                    const SizedBox(height: 6),
                    if (provider.entries.isEmpty)
                      const MutedLine('No exercises yet — add one below.')
                    else
                      for (final entry in provider.entries) _entryRow(entry),
                    _newRow(),
                    const SizedBox(height: 8),
                    const MutedLine('swipe left to delete · tap to edit'),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _entryRow(CatalogEntry entry) {
    final suffix = formatPrescription(
      entry.defaultSets,
      entry.defaultReps,
      entry.defaultRepsMax,
      entry.defaultUnit,
    );
    return Dismissible(
      key: ValueKey('catalog-${entry.id}'),
      direction: DismissDirection.endToStart,
      background: const SwipeDeleteBackground(),
      secondaryBackground: const SwipeDeleteBackground(),
      confirmDismiss: (_) async {
        await _delete(entry);
        return false; // deletion handled explicitly; keep list authoritative
      },
      child: SizedBox(
        height: kNotebookLine,
        child: InkWell(
          onTap: () => _edit(entry),
          child: Container(
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.only(bottom: 3),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 20,
                  color: NotebookColors.ink,
                ),
                children: [
                  TextSpan(text: entry.name),
                  if (suffix.isNotEmpty)
                    TextSpan(
                      text: '  $suffix',
                      style: const TextStyle(color: NotebookColors.inkSoft),
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

  Widget _newRow() {
    return SizedBox(
      height: kNotebookLine,
      child: InkWell(
        onTap: _create,
        child: Container(
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.only(bottom: 3),
          child: const Text(
            '+ new exercise…',
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
}

/// Shared create/edit form: name, description, default sets/reps/max, and
/// the reps/sec/min unit toggle. Stateful so the unit toggle can rebuild.
class _ExerciseForm extends StatefulWidget {
  const _ExerciseForm({required this.title, this.entry});

  final String title;
  final CatalogEntry? entry;

  @override
  State<_ExerciseForm> createState() => _ExerciseFormState();
}

class _ExerciseFormState extends State<_ExerciseForm> {
  late final _nameCtrl = TextEditingController(text: widget.entry?.name ?? '');
  late final _descCtrl = TextEditingController(text: widget.entry?.description ?? '');
  late final _setsCtrl = TextEditingController(
    text: widget.entry?.defaultSets?.toString() ?? '',
  );
  late final _repsCtrl = TextEditingController(
    text: widget.entry?.defaultReps?.toString() ?? '',
  );
  late final _maxCtrl = TextEditingController(
    text: widget.entry?.defaultRepsMax?.toString() ?? '',
  );
  late String _unit = widget.entry?.defaultUnit ?? RepUnit.reps;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  int? _parseInt(TextEditingController c) {
    final v = int.tryParse(c.text.trim());
    return (v != null && v > 0) ? v : null;
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    var mx = _parseInt(_maxCtrl);
    final reps = _parseInt(_repsCtrl);
    if (mx != null && reps != null && mx <= reps) mx = null;
    Navigator.pop(
      context,
      _ExerciseFormResult(
        name: name,
        description: _descCtrl.text.trim(),
        sets: _parseInt(_setsCtrl),
        repsMin: reps,
        repsMax: mx,
        unit: _unit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final secondHint = _unit == RepUnit.reps ? 'reps' : _unit;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'Caveat',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: NotebookColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        _formLabel('Name'),
        _formField(_nameCtrl, autofocus: widget.entry == null),
        const SizedBox(height: 8),
        _formLabel('Description'),
        _formField(_descCtrl, maxLines: 2, hint: 'form cues, notes…'),
        const SizedBox(height: 10),
        _formLabel('Default sets × reps'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _smallNum(_setsCtrl, 'sets'),
            _glyphText('×'),
            _smallNum(_repsCtrl, secondHint),
            _glyphText('to'),
            _smallNum(_maxCtrl, secondHint),
          ],
        ),
        const SizedBox(height: 8),
        _unitToggle(),
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
            PenButton(label: 'Save', small: true, onPressed: _save),
          ],
        ),
      ],
    );
  }

  /// "reps · sec · min" toggle — matches the Profile screen's units line.
  Widget _unitToggle() {
    Widget option(String value, String label) {
      final active = _unit == value;
      return InkWell(
        onTap: active
            ? null
            : () {
                HapticFeedback.selectionClick();
                setState(() => _unit = value);
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Caveat',
              fontSize: 19,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? NotebookColors.ink : NotebookColors.inkSoft,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        const Text(
          'unit:  ',
          style: TextStyle(
            fontFamily: 'Caveat',
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: NotebookColors.inkSoft,
          ),
        ),
        option(RepUnit.reps, 'reps'),
        const Text(
          '·',
          style: TextStyle(fontFamily: 'Caveat', fontSize: 18, color: NotebookColors.inkSoft),
        ),
        option(RepUnit.seconds, 'sec'),
        const Text(
          '·',
          style: TextStyle(fontFamily: 'Caveat', fontSize: 18, color: NotebookColors.inkSoft),
        ),
        option(RepUnit.minutes, 'min'),
      ],
    );
  }

  Widget _formLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: 'Caveat',
        fontSize: 16,
        fontStyle: FontStyle.italic,
        color: NotebookColors.inkSoft,
      ),
    ),
  );

  Widget _formField(
    TextEditingController controller, {
    bool autofocus = false,
    int maxLines = 1,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      cursorColor: NotebookColors.ink,
      style: const TextStyle(fontFamily: 'Caveat', fontSize: 20, color: NotebookColors.ink),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Caveat',
          fontSize: 18,
          color: NotebookColors.inkSoft,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: NotebookColors.ink),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: NotebookColors.ink, width: 2),
        ),
      ),
    );
  }

  Widget _smallNum(TextEditingController controller, String hint) {
    return SizedBox(
      width: 48,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        cursorColor: NotebookColors.ink,
        textAlign: TextAlign.center,
        style: const TextStyle(fontFamily: 'Caveat', fontSize: 21, color: NotebookColors.ink),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Caveat',
            fontSize: 15,
            color: NotebookColors.inkSoft,
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: NotebookColors.ink),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: NotebookColors.ink, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _glyphText(String s) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    child: Text(
      s,
      style: const TextStyle(fontFamily: 'Caveat', fontSize: 20, color: NotebookColors.inkSoft),
    ),
  );
}

class _ExerciseFormResult {
  const _ExerciseFormResult({
    required this.name,
    required this.description,
    this.sets,
    this.repsMin,
    this.repsMax,
    required this.unit,
  });

  final String name;
  final String description;
  final int? sets;
  final int? repsMin;
  final int? repsMax;
  final String unit;
}

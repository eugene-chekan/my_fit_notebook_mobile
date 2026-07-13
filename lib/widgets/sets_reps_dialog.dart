import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models/rep_unit.dart';
import '../theme/notebook_theme.dart';
import 'paper_dialog.dart';
import 'pen_button.dart';

/// A per-routine prescription captured from the dialog. Any numeric field
/// may be null (no prescription / no range).
typedef Prescription = ({int? sets, int? repsMin, int? repsMax, String unit});

/// Paper dialog to enter/edit sets × reps, with a unit toggle (reps / sec /
/// min) so a hold or timed exercise reads "2x45sec" or "1x2min" instead of
/// a plain rep count. Returns null if cancelled. A max ≤ the first number
/// is treated as "no range".
Future<Prescription?> showSetsRepsDialog(
  BuildContext context, {
  required String title,
  int? sets,
  int? repsMin,
  int? repsMax,
  String unit = RepUnit.reps,
}) {
  return showPaperDialog<Prescription>(
    context: context,
    builder: (context) => _SetsRepsForm(
      title: title,
      initialSets: sets,
      initialRepsMin: repsMin,
      initialRepsMax: repsMax,
      initialUnit: unit,
    ),
  );
}

class _SetsRepsForm extends StatefulWidget {
  const _SetsRepsForm({
    required this.title,
    this.initialSets,
    this.initialRepsMin,
    this.initialRepsMax,
    required this.initialUnit,
  });

  final String title;
  final int? initialSets;
  final int? initialRepsMin;
  final int? initialRepsMax;
  final String initialUnit;

  @override
  State<_SetsRepsForm> createState() => _SetsRepsFormState();
}

class _SetsRepsFormState extends State<_SetsRepsForm> {
  late final _setsCtrl = TextEditingController(text: widget.initialSets?.toString() ?? '');
  late final _repsCtrl = TextEditingController(text: widget.initialRepsMin?.toString() ?? '');
  late final _maxCtrl = TextEditingController(text: widget.initialRepsMax?.toString() ?? '');
  late String _unit = widget.initialUnit;

  @override
  void dispose() {
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  int? _parse(TextEditingController c) {
    final v = int.tryParse(c.text.trim());
    return (v != null && v > 0) ? v : null;
  }

  void _save() {
    final s = _parse(_setsCtrl);
    final r = _parse(_repsCtrl);
    var mx = _parse(_maxCtrl);
    if (mx != null && r != null && mx <= r) mx = null;
    Navigator.pop(context, (sets: s, repsMin: r, repsMax: mx, unit: _unit));
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
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _numField(_setsCtrl, 'sets'),
            const _Glyph('×'),
            _numField(_repsCtrl, secondHint),
            const _Glyph('to'),
            _numField(_maxCtrl, secondHint),
          ],
        ),
        const SizedBox(height: 10),
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

  /// "reps · sec · min" — tap to switch, matching the Profile screen's
  /// units toggle (active choice bold ink, others muted).
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

  Widget _numField(TextEditingController controller, String hint) {
    return SizedBox(
      width: 52,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        cursorColor: NotebookColors.ink,
        textAlign: TextAlign.center,
        style: const TextStyle(fontFamily: 'Caveat', fontSize: 22, color: NotebookColors.ink),
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
}

class _Glyph extends StatelessWidget {
  const _Glyph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'Caveat', fontSize: 20, color: NotebookColors.inkSoft),
      ),
    );
  }
}

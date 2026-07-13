import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/notebook_theme.dart';
import 'paper_dialog.dart';
import 'pen_button.dart';

/// A per-routine prescription captured from the dialog. Any field may be
/// null (no prescription / no range).
typedef Prescription = ({int? sets, int? repsMin, int? repsMax});

/// Paper dialog to enter/edit sets × reps with an optional upper rep.
/// Returns null if cancelled. Empty sets/reps clear the prescription;
/// a max ≤ reps is treated as "no range".
Future<Prescription?> showSetsRepsDialog(
  BuildContext context, {
  required String title,
  int? sets,
  int? repsMin,
  int? repsMax,
}) {
  final setsCtrl = TextEditingController(text: sets?.toString() ?? '');
  final repsCtrl = TextEditingController(text: repsMin?.toString() ?? '');
  final maxCtrl = TextEditingController(text: repsMax?.toString() ?? '');

  int? parse(TextEditingController c) {
    final v = int.tryParse(c.text.trim());
    return (v != null && v > 0) ? v : null;
  }

  return showPaperDialog<Prescription>(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
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
            _numField(setsCtrl, 'sets'),
            const _Times(),
            _numField(repsCtrl, 'reps'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Text(
                'to',
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 18,
                  color: NotebookColors.inkSoft,
                ),
              ),
            ),
            _numField(maxCtrl, 'max'),
          ],
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
              onPressed: () {
                final s = parse(setsCtrl);
                final r = parse(repsCtrl);
                var mx = parse(maxCtrl);
                if (mx != null && r != null && mx <= r) mx = null;
                Navigator.pop(context, (sets: s, repsMin: r, repsMax: mx));
              },
            ),
          ],
        ),
      ],
    ),
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
          fontSize: 16,
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

class _Times extends StatelessWidget {
  const _Times();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        '×',
        style: TextStyle(fontFamily: 'Caveat', fontSize: 22, color: NotebookColors.ink),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/notebook_theme.dart';
import 'glyph_button.dart';
import 'pen_button.dart';

/// A small pen "?" that opens the page's tip as a slip of paper torn from a
/// pad. Replaces the muted hint lines that used to sit permanently under a
/// list: the advice is there when wanted and costs nothing when it isn't.
class TipNoteButton extends StatelessWidget {
  const TipNoteButton({super.key, required this.text, this.size = 20});

  /// The helper text shown on the torn slip.
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GlyphButton(
      glyph: '?',
      size: size,
      color: context.notebook.sec,
      semanticLabel: AppLocalizations.of(context).tipSemantic,
      onTap: () => showTipNote(context, text),
    );
  }
}

/// Shows [text] on a torn-off slip of notebook paper.
Future<void> showTipNote(BuildContext context, String text) {
  final palette = context.notebook;
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (dialogContext) {
      final t = AppLocalizations.of(dialogContext);
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Material(
            color: Colors.transparent,
            child: Transform.rotate(
              angle: -0.012, // torn off in a hurry, not squared to the screen
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: CustomPaint(
                  painter: _TornSlipPainter(palette),
                  child: Padding(
                    // Extra room at the foot so the text clears the tear.
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          text,
                          style: TextStyle(
                            fontFamily: 'Caveat',
                            fontSize: 20,
                            height: 1.25,
                            color: palette.ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: PenButton(
                            label: t.gotIt,
                            small: true,
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Paints the slip: paper ground, a ruled line or two showing through, an ink
/// edge on the three cut sides, and a ragged tear along the bottom.
class _TornSlipPainter extends CustomPainter {
  _TornSlipPainter(this.palette);

  final NotebookPalette palette;

  /// Fixed jitter for the tear, so the slip looks hand-torn but doesn't
  /// reshuffle itself on every repaint.
  static const _jitter = <double>[
    0.35, 0.9, 0.2, 0.75, 0.45, 1.0, 0.3, 0.65, 0.15, 0.85, 0.4, 0.7, 0.25,
    0.95, 0.5, 0.8, 0.3, 0.6, 0.2, 0.9,
  ];

  static const _tearDepth = 9.0;

  /// The slip's outline: square on three sides, ragged along the bottom.
  Path _outline(Size size) {
    final bottom = size.height - _tearDepth;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, bottom);
    // Walk right-to-left along the foot, stepping up and down through the
    // jitter table to leave a torn fibre edge.
    final steps = _jitter.length;
    for (var i = 0; i < steps; i++) {
      final x = size.width * (1 - (i + 1) / steps);
      final y = bottom + _jitter[i] * _tearDepth;
      path.lineTo(x, y);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outline = _outline(size);

    canvas.drawShadow(outline, palette.shadow, 6, false);
    canvas.drawPath(outline, Paint()..color = palette.bg);

    // A couple of ruled lines, so the slip reads as notebook stock.
    canvas.save();
    canvas.clipPath(outline);
    final rule = Paint()
      ..color = palette.ruleTint
      ..strokeWidth = 1;
    for (var y = 30.0; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rule);
    }
    canvas.restore();

    // Ink edge on the cut sides only — a tear has no drawn line.
    final edge = Paint()
      ..color = palette.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final bottom = size.height - _tearDepth;
    canvas.drawPath(
      Path()
        ..moveTo(0, math.min(bottom, size.height))
        ..lineTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, bottom),
      edge,
    );
  }

  @override
  bool shouldRepaint(covariant _TornSlipPainter old) => old.palette != palette;
}

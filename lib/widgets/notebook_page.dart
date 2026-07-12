import 'package:flutter/material.dart';

import '../theme/notebook_theme.dart';

/// Vertical rhythm of the ruled paper. Content that should sit "on the
/// lines" (list rows, headings) sizes itself to a multiple of this.
const double kNotebookLine = 36.0;

/// X position of the vertical margin rule. Page content starts right of
/// it; the margin column itself can host controls (see
/// [NotebookPage.marginChild]) — the mobile counterpart of the web app's
/// sidebar rail living in the page margin.
const double kMarginRuleX = 52.0;

class RuledPaperPainter extends CustomPainter {
  const RuledPaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = NotebookColors.paper);

    final linePaint = Paint()
      ..color = NotebookColors.paperLine
      ..strokeWidth = 1;
    for (double y = kNotebookLine; y < size.height; y += kNotebookLine) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final marginPaint = Paint()
      ..color = NotebookColors.marginLine
      ..strokeWidth = 2;
    canvas.drawLine(
      const Offset(kMarginRuleX, 0),
      Offset(kMarginRuleX, size.height),
      marginPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RuledPaperPainter oldDelegate) => false;
}

/// A full-bleed page of ruled notebook paper with a left margin rule — no
/// frame or border, so the device screen *is* the page. The ruling is
/// painted behind the scrolled *content* rather than the viewport, so
/// lines move with the "writing" when you scroll, matching the CSS
/// background on the web app's `.page`.
class NotebookPage extends StatelessWidget {
  const NotebookPage({super.key, required this.child, this.padding, this.marginChild});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Optional control rendered inside the margin column, near the top —
  /// e.g. the ≡ menu glyph. It scrolls with the page like a margin note.
  final Widget? marginChild;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: CustomPaint(
            painter: const RuledPaperPainter(),
            child: Stack(
              children: [
                Padding(
                  padding: padding ?? const EdgeInsets.fromLTRB(64, 4, 18, 28),
                  child: child,
                ),
                if (marginChild != null)
                  Positioned(
                    left: 0,
                    top: kNotebookLine + 2,
                    width: kMarginRuleX,
                    child: Center(child: marginChild),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A section heading occupying exactly one ruled line, text resting on it.
class HeadingLine extends StatelessWidget {
  const HeadingLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kNotebookLine,
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Caveat',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: NotebookColors.ink,
        ),
      ),
    );
  }
}

/// A muted single-line note (empty states), resting on a ruled line.
class MutedLine extends StatelessWidget {
  const MutedLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kNotebookLine,
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Caveat',
          fontSize: 18,
          color: NotebookColors.inkSoft,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

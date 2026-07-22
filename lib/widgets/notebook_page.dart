import 'package:flutter/material.dart';

import '../theme/notebook_theme.dart';

/// Vertical rhythm of the ruled paper. Content that should sit "on the
/// lines" (list rows, headings) sizes itself to a multiple of this.
const double kNotebookLine = 36.0;

/// Grid pitch for the Carbon theme's engineering graph paper (both axes).
const double kGraphGrid = 28.0;

/// X position of the vertical margin rule. Page content starts right of
/// it; the margin column itself can host controls (see
/// [NotebookPage.marginChild]) — the mobile counterpart of the web app's
/// sidebar rail living in the page margin.
const double kMarginRuleX = 52.0;

class RuledPaperPainter extends CustomPainter {
  const RuledPaperPainter(this.palette);

  final NotebookPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = palette.bg);

    final linePaint = Paint()
      ..color = palette.ruleTint
      ..strokeWidth = 1;
    if (palette.graphGrid) {
      // Carbon: an even engineering-graph grid on both axes instead of rules.
      for (double y = kGraphGrid; y < size.height; y += kGraphGrid) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      }
      for (double x = kGraphGrid; x < size.width; x += kGraphGrid) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
      }
    } else {
      for (double y = kNotebookLine; y < size.height; y += kNotebookLine) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      }
    }

    // The margin rule reads as a brick "double line" — two thin strokes a few
    // pixels apart, like a ruled notebook's red margin.
    final marginPaint = Paint()
      ..color = palette.marginRule
      ..strokeWidth = 2;
    for (final dx in const [-2.0, 2.0]) {
      canvas.drawLine(
        Offset(kMarginRuleX + dx, 0),
        Offset(kMarginRuleX + dx, size.height),
        marginPaint,
      );
    }

    // A soft radial vignette so the page edges recede — a warm dab on light
    // paper, a darkening on dark grounds.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.9,
          colors: [const Color(0x00000000), palette.vignette],
          stops: const [0.6, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant RuledPaperPainter oldDelegate) =>
      oldDelegate.palette != palette;
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
            painter: RuledPaperPainter(context.notebook),
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
        style: TextStyle(
          fontFamily: 'Caveat',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: context.notebook.ink,
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
        style: TextStyle(
          fontFamily: 'Caveat',
          fontSize: 18,
          color: context.notebook.sec,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/notebook_theme.dart';

/// Hand-drawn pen glyphs for the side menu's utility row.
///
/// Drawn rather than shipped as icons so they inherit the theme's ink and sit
/// in the same hand as the rest of the notebook: open strokes, round caps, and
/// deliberately imperfect geometry (nothing is quite centred or closed, the way
/// a pen drawing isn't).
enum InkGlyph { profile, stats, settings }

/// A tappable pen glyph, sized to a comfortable touch target while the drawing
/// itself stays small.
class InkGlyphButton extends StatelessWidget {
  const InkGlyphButton({
    super.key,
    required this.glyph,
    required this.label,
    required this.onTap,
    this.size = 30,
  });

  final InkGlyph glyph;

  /// These are icon-only, so this is the only text a screen reader has to work
  /// with. It is deliberately not a [Tooltip]: the menu panel is mounted above
  /// the Navigator rather than inside it, so there is no Overlay for a tooltip
  /// to float in and one would assert the moment the glyph is built.
  final String label;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ink = context.notebook.ink;
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: size,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(painter: _InkGlyphPainter(glyph, ink)),
          ),
        ),
      ),
    );
  }
}

class _InkGlyphPainter extends CustomPainter {
  const _InkGlyphPainter(this.glyph, this.ink);

  final InkGlyph glyph;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (glyph) {
      case InkGlyph.profile:
        _profile(canvas, size, pen);
      case InkGlyph.stats:
        _stats(canvas, size, pen);
      case InkGlyph.settings:
        _settings(canvas, size, pen);
    }
  }

  /// Head and shoulders — the same bust that stands in for a missing profile
  /// photo, so the menu and the Profile page speak with one drawing.
  void _profile(Canvas canvas, Size size, Paint pen) {
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(Offset(w * 0.5, h * 0.32), w * 0.19, pen);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.16, h * 0.92)
        ..cubicTo(w * 0.2, h * 0.62, w * 0.35, h * 0.55, w * 0.5, h * 0.55)
        ..cubicTo(w * 0.65, h * 0.55, w * 0.8, h * 0.62, w * 0.84, h * 0.92),
      pen,
    );
  }

  /// Three bars climbing off a baseline — a chart sketched in the margin.
  void _stats(Canvas canvas, Size size, Paint pen) {
    final w = size.width;
    final h = size.height;
    // Baseline, overshooting slightly at both ends like a ruled pen stroke.
    canvas.drawLine(Offset(w * 0.1, h * 0.88), Offset(w * 0.93, h * 0.88), pen);
    for (final (x, top) in [(0.26, 0.55), (0.5, 0.3), (0.74, 0.44)]) {
      canvas.drawLine(Offset(w * x, h * 0.86), Offset(w * x, h * top), pen);
    }
  }

  /// Two sliders with their knobs pushed to different places. A cog would read
  /// as a sun at this stroke weight; sliders stay legible when drawn by hand.
  void _settings(Canvas canvas, Size size, Paint pen) {
    final w = size.width;
    final h = size.height;
    final knob = Paint()
      ..color = ink
      ..style = PaintingStyle.fill;

    for (final (y, knobX) in [(0.34, 0.66), (0.68, 0.38)]) {
      canvas.drawLine(Offset(w * 0.12, h * y), Offset(w * 0.9, h * y), pen);
      canvas.drawCircle(Offset(w * knobX, h * y), w * 0.11, knob);
    }
  }

  @override
  bool shouldRepaint(covariant _InkGlyphPainter old) =>
      old.glyph != glyph || old.ink != ink;
}

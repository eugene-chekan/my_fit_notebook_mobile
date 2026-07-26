import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/notebook_theme.dart';

/// A profile photo dressed as a Polaroid print taped to the notebook page:
/// a warm white card with the classic wide chin, tilted a touch, lifted off
/// the page by a soft shadow, and held down by a strip of translucent masking
/// tape. When [photo] is null it shows a hand-drawn ink bust — the "default
/// picture" — so the frame always reads as a portrait.
///
/// The print itself stays light in every theme (a Polaroid is white whatever
/// desk it sits on), so its own inks are fixed rather than palette-driven; only
/// the drop shadow follows the theme.
class PolaroidPhoto extends StatelessWidget {
  const PolaroidPhoto({
    super.key,
    this.photo,
    this.caption,
    required this.onTap,
    required this.semanticLabel,
    this.width = 108,
  });

  /// The photo file, or null to show the ink placeholder bust.
  final File? photo;

  /// Handwritten caption on the chin (the person's name), or null/empty for a
  /// blank chin.
  final String? caption;
  final VoidCallback onTap;
  final String semanticLabel;
  final double width;

  // Fixed print inks — legible on the white card under any theme.
  static const _paper = Color(0xFFFCFAF3); // warm photo-paper white
  static const _penInk = Color(0xFF2B3A63); // navy pen: caption + sketch
  static const _photoTint = Color(0xFFE7E4D8); // faint ground behind the sketch
  static const _frameLine = Color(0x1F2B3A63); // hairline around the photo
  static const _tape = Color(0x59D8C48F); // translucent masking tape
  static const _tapeEdge = Color(0x24A88A4B);

  @override
  Widget build(BuildContext context) {
    final shadow = context.notebook.shadow;
    final hasCaption = caption != null && caption!.trim().isNotEmpty;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Transform.rotate(
          angle: -0.035, // a casual, hand-placed tilt
          child: SizedBox(
            width: width,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _paper,
                    boxShadow: [
                      BoxShadow(
                        color: shadow,
                        blurRadius: 9,
                        offset: const Offset(2, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _photoTint,
                            border: Border.all(color: _frameLine),
                          ),
                          child: photo == null
                              ? CustomPaint(painter: _BustPainter())
                              : Image.file(
                                  photo!,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                  errorBuilder: (_, _, _) =>
                                      CustomPaint(painter: _BustPainter()),
                                ),
                        ),
                      ),
                      // The chin — wide bottom border, with the handwritten name.
                      SizedBox(
                        height: 24,
                        child: Center(
                          child: hasCaption
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: Text(
                                    caption!.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Caveat',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _penInk,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                // A strip of masking tape holding the top edge to the page.
                Positioned(
                  top: 0,
                  child: Transform.rotate(
                    angle: 0.15,
                    child: Container(
                      width: 46,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _tape,
                        border: Border.symmetric(
                          vertical: BorderSide(color: _tapeEdge, width: 1),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A minimal head-and-shoulders bust, drawn in pen — the default portrait shown
/// before a real photo is chosen.
class _BustPainter extends CustomPainter {
  static const _ink = PolaroidPhoto._penInk;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Head.
    final headCenter = Offset(w * 0.5, h * 0.4);
    final headRadius = w * 0.17;
    canvas.drawCircle(headCenter, headRadius, stroke);

    // Shoulders — a broad arc rising from the lower corners to the neck.
    final shoulders = Path()
      ..moveTo(w * 0.12, h * 1.02)
      ..cubicTo(
        w * 0.16, h * 0.72,
        w * 0.34, h * 0.6,
        w * 0.5, h * 0.6,
      )
      ..cubicTo(
        w * 0.66, h * 0.6,
        w * 0.84, h * 0.72,
        w * 0.88, h * 1.02,
      );
    canvas.drawPath(shoulders, stroke);
  }

  @override
  bool shouldRepaint(covariant _BustPainter oldDelegate) => false;
}

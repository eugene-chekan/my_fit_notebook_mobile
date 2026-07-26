import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/notebook_theme.dart';

/// A profile photo dressed as a Polaroid print taped to the notebook page:
/// a warm white card with the classic wide chin, tilted a touch, lifted off
/// the page by a soft shadow, and held down by a strip of translucent masking
/// tape. When [photo] is null it shows a hand-drawn ink bust — the "default
/// picture" — so the frame always reads as a portrait.
///
/// The print's own inks follow the theme via [_PrintInks]: warm white on the
/// light grounds, and a dimmer ink-derived stock on the dark ones (see there
/// for why). Its identity comes from the silhouette — square photo, wide chin,
/// tape — so toning the stock down never costs the Polaroid read.
class PolaroidPhoto extends StatelessWidget {
  const PolaroidPhoto({
    super.key,
    this.photo,
    this.caption,
    required this.onTap,
    required this.semanticLabel,
    this.width = 108,
  });

  /// Key on the print card itself, so tests can inspect the resolved stock.
  static const cardKey = ValueKey('polaroid-card');

  /// The photo file, or null to show the ink placeholder bust.
  final File? photo;

  /// Handwritten caption on the chin (the person's name), or null/empty for a
  /// blank chin.
  final String? caption;
  final VoidCallback onTap;
  final String semanticLabel;
  final double width;

  @override
  Widget build(BuildContext context) {
    final palette = context.notebook;
    final inks = _PrintInks.of(palette);
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
                  key: cardKey,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: inks.stock,
                    // Always bordered so the print's footprint is identical in
                    // every theme; on the light grounds the rim is invisible.
                    border: Border.all(color: inks.rim ?? Colors.transparent),
                    boxShadow: [
                      BoxShadow(
                        color: palette.shadow,
                        blurRadius: inks.shadowBlur,
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
                            color: inks.photoTint,
                            border: Border.all(color: inks.frameLine),
                          ),
                          child: photo == null
                              ? CustomPaint(painter: _BustPainter(inks.captionInk))
                              : Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      photo!,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                      errorBuilder: (_, _, _) => CustomPaint(
                                        painter: _BustPainter(inks.captionInk),
                                      ),
                                    ),
                                    // Veils a bright picture so it doesn't blaze
                                    // out of a dark page.
                                    if (inks.scrim != null) ColoredBox(color: inks.scrim!),
                                  ],
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
                                    style: TextStyle(
                                      fontFamily: 'Caveat',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: inks.captionInk,
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
                        color: inks.tape,
                        border: Border.symmetric(
                          vertical: BorderSide(color: inks.tapeEdge, width: 1),
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

/// The print's own inks, resolved per theme.
///
/// A Polaroid is white in daylight, and on the light grounds that is exactly
/// what it stays. On the dark grounds a white card is a floodlight: the stock
/// lands near 0.96 relative luminance while the page's own ink tops out around
/// 0.53, so the print reads as lit for a different room than the page it is
/// taped to. There the stock is derived from the palette's [NotebookPalette.ink]
/// instead, lightened just enough to sit above it — still unmistakably paper,
/// no longer glowing, and hue-matched to each theme for free (cool on
/// blueprint, chalky on chalkboard, warm sepia on lamp, neutral on carbon).
class _PrintInks {
  const _PrintInks({
    required this.stock,
    required this.captionInk,
    required this.photoTint,
    required this.frameLine,
    required this.tape,
    required this.tapeEdge,
    required this.shadowBlur,
    this.rim,
    this.scrim,
  });

  /// The photo-paper card itself.
  final Color stock;

  /// Pen colour for the chin caption and the placeholder bust — dark on the
  /// light stock either way.
  final Color captionInk;

  /// Ground behind the picture area (visible around the placeholder bust).
  final Color photoTint;

  /// Hairline framing the picture area.
  final Color frameLine;
  final Color tape;
  final Color tapeEdge;

  /// Blur on the drop shadow. Wider on the dark grounds, where a dark shadow
  /// barely registers and needs the spread to convey any lift at all.
  final double shadowBlur;

  /// Hairline around the whole card. This is what carries the print's lift on
  /// the dark grounds, where the drop shadow is nearly invisible; null (and so
  /// transparent) on the light ones, which have the shadow for that.
  final Color? rim;

  /// Veil laid over the picture itself, so a bright photo doesn't blaze out of
  /// a dark page. Null on the light grounds.
  final Color? scrim;

  factory _PrintInks.of(NotebookPalette palette) {
    if (!palette.isDark) {
      return const _PrintInks(
        stock: Color(0xFFFCFAF3), // warm photo-paper white
        captionInk: Color(0xFF2B3A63), // navy pen
        photoTint: Color(0xFFE7E4D8),
        frameLine: Color(0x1F2B3A63),
        tape: Color(0x59D8C48F), // translucent masking tape
        tapeEdge: Color(0x24A88A4B),
        shadowBlur: 9,
      );
    }
    final stock = Color.lerp(palette.ink, Colors.white, 0.18)!;
    return _PrintInks(
      stock: stock,
      captionInk: palette.bg, // the page's own dark, as ink on a light card
      photoTint: Color.lerp(stock, palette.bg, 0.18)!,
      frameLine: palette.bg.withValues(alpha: 0.25),
      // Tape catches the page's hue instead of importing a warm one.
      tape: palette.ink.withValues(alpha: 0.22),
      tapeEdge: palette.ink.withValues(alpha: 0.14),
      shadowBlur: 14,
      rim: palette.ink.withValues(alpha: 0.30),
      scrim: palette.bg.withValues(alpha: 0.10),
    );
  }
}

/// A minimal head-and-shoulders bust, drawn in pen — the default portrait shown
/// before a real photo is chosen.
class _BustPainter extends CustomPainter {
  const _BustPainter(this.ink);

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = ink
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
  bool shouldRepaint(covariant _BustPainter oldDelegate) => oldDelegate.ink != ink;
}

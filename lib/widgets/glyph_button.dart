import 'package:flutter/material.dart';

import '../theme/notebook_theme.dart';

/// An inky text-glyph tap target (✐, ×, ✓, ←, ≡ …). Replaces Material's
/// icon set so controls read as pen marks, matching the web app's
/// `.icon-btn` character buttons.
class GlyphButton extends StatelessWidget {
  const GlyphButton({
    super.key,
    required this.glyph,
    required this.onTap,
    this.size = 20,
    this.color,
    this.semanticLabel,
  });

  final String glyph;
  final VoidCallback? onTap;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: Text(
              glyph,
              style: TextStyle(
                fontSize: size,
                height: 1,
                fontWeight: FontWeight.w600,
                color: color ?? context.notebook.sec,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

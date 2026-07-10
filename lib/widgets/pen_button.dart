import 'package:flutter/material.dart';

import '../theme/notebook_theme.dart';

/// Blob-ish corner radii ported from CSS's elliptical border-radius
/// shorthand (`h1 h2 h3 h4 / v1 v2 v3 v4`, corners in TL/TR/BR/BL order).
/// Flutter clamps oversized radii to the widget's actual size, which is
/// exactly how the CSS version behaves too — so the same huge px values
/// reproduce the same "pen stroke" wobble at button scale.
BorderRadius penBlobRadius() => const BorderRadius.only(
  topLeft: Radius.elliptical(255, 25),
  topRight: Radius.elliptical(25, 225),
  bottomRight: Radius.elliptical(225, 25),
  bottomLeft: Radius.elliptical(25, 255),
);

BorderRadius playerBlobRadius() => const BorderRadius.only(
  topLeft: Radius.elliptical(6, 9),
  topRight: Radius.elliptical(10, 7),
  bottomRight: Radius.elliptical(7, 10),
  bottomLeft: Radius.elliptical(9, 6),
);

/// The outlined "ballpoint pen" button used for most actions
/// (`.btn-pen` in notebook.css).
class PenButton extends StatelessWidget {
  const PenButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.danger = false,
    this.small = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool danger;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final color = danger ? NotebookColors.danger : NotebookColors.ink;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: color,
          width: 2,
          style: danger ? BorderStyle.solid : BorderStyle.solid,
        ),
        shape: RoundedRectangleBorder(borderRadius: penBlobRadius()),
        padding: EdgeInsets.symmetric(
          horizontal: small ? 12 : 18,
          vertical: small ? 2 : 6,
        ),
        textStyle: TextStyle(
          fontFamily: 'Caveat',
          fontSize: small ? 17 : 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label),
    );
  }
}

/// Solid ink "Finish workout" call-to-action (`.btn-finish-workout`).
class PenButtonFilled extends StatelessWidget {
  const PenButtonFilled({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: NotebookColors.ink,
        foregroundColor: NotebookColors.paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(5),
            topRight: Radius.circular(6),
            bottomRight: Radius.circular(5),
            bottomLeft: Radius.circular(4),
          ),
          side: const BorderSide(color: NotebookColors.ink, width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
        textStyle: const TextStyle(
          fontFamily: 'Caveat',
          fontSize: 21,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(label),
    );
  }
}

/// Small round-ish transport control (play / pause / stop) —
/// `.player-btn` in notebook.css.
class PlayerButton extends StatelessWidget {
  const PlayerButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.soft = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final color = soft ? NotebookColors.inkSoft : NotebookColors.ink;
    final button = SizedBox(
      width: 40,
      height: 34,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(borderRadius: playerBlobRadius()),
          padding: EdgeInsets.zero,
        ),
        child: Icon(icon, size: 18),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

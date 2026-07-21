import 'package:flutter/material.dart';

import '../theme/notebook_theme.dart';

/// Reveal shown behind a row while swiping right (startToEnd) — copy.
class SwipeCopyBackground extends StatelessWidget {
  const SwipeCopyBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.notebook.trainedFill,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 10),
      child: Text(
        'copy ⟶',
        style: TextStyle(
          fontFamily: 'Caveat',
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: context.notebook.ink,
        ),
      ),
    );
  }
}

/// Reveal shown behind a row while swiping left (endToStart) — delete.
class SwipeDeleteBackground extends StatelessWidget {
  const SwipeDeleteBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.notebook.accent.withValues(alpha: 0.12),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 10),
      child: Text(
        '⟵ delete',
        style: TextStyle(
          fontFamily: 'Caveat',
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: context.notebook.accent,
        ),
      ),
    );
  }
}

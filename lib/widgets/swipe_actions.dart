import 'package:flutter/material.dart';

import '../theme/notebook_theme.dart';

/// Reveal shown behind a row while swiping right (startToEnd) — copy.
class SwipeCopyBackground extends StatelessWidget {
  const SwipeCopyBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NotebookColors.trainedFill,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 10),
      child: const Text(
        'copy ⟶',
        style: TextStyle(
          fontFamily: 'Caveat',
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: NotebookColors.ink,
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
      color: const Color(0x1F8B2F2F),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 10),
      child: const Text(
        '⟵ delete',
        style: TextStyle(
          fontFamily: 'Caveat',
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: NotebookColors.danger,
        ),
      ),
    );
  }
}

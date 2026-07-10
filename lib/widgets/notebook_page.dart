import 'package:flutter/material.dart';

import '../theme/notebook_theme.dart';

/// Paints the ruled-paper texture used behind every screen: a solid paper
/// fill plus faint horizontal rule lines, mirroring the `.page` background
/// gradient in notebook.css.
class _RuledPaperPainter extends CustomPainter {
  const _RuledPaperPainter();

  static const lineSpacing = 27.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = NotebookColors.paper;
    canvas.drawRect(Offset.zero & size, paint);

    final linePaint = Paint()
      ..color = NotebookColors.paperLine
      ..strokeWidth = 1;
    for (double y = 4; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RuledPaperPainter oldDelegate) => false;
}

/// A page of ruled notebook paper with a hand-inked border, used as the
/// backdrop for every screen in the app.
class NotebookPage extends StatelessWidget {
  const NotebookPage({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NotebookColors.desk,
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: NotebookColors.ink, width: 2),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(2),
            topRight: Radius.circular(3),
            bottomRight: Radius.circular(4),
            bottomLeft: Radius.circular(2),
          ),
          boxShadow: const [
            BoxShadow(
              color: NotebookColors.shadow,
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          painter: const _RuledPaperPainter(),
          child: Padding(
            padding: padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: child,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/notebook_theme.dart';

/// A hand-drawn trend line, like a value sketched across the ruled page in
/// ballpoint ink: a polyline over [values] (evenly spaced by index, oldest
/// left), an optional dashed goal line, and a filled dot on the latest
/// point. Values are already in display units — the painter only scales.
///
/// Used full-size for the weight chart and as a compact inline sparkline for
/// the other measurements ([showDots]/[showGoalLabel] off, small [height]).
class NotebookLineChart extends StatelessWidget {
  const NotebookLineChart({
    super.key,
    required this.values,
    this.target,
    this.height = 92,
    this.showDots = true,
    this.showGoalLabel = false,
    this.strokeWidth = 2,
  });

  final List<double> values;
  final double? target;
  final double height;
  final bool showDots;
  final bool showGoalLabel;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _LineChartPainter(
          values: values,
          target: target,
          showDots: showDots,
          showGoalLabel: showGoalLabel,
          strokeWidth: strokeWidth,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.target,
    required this.showDots,
    required this.showGoalLabel,
    required this.strokeWidth,
  });

  final List<double> values;
  final double? target;
  final bool showDots;
  final bool showGoalLabel;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const padTop = 10.0;
    const padBottom = 8.0;
    const padLeft = 4.0;
    const padRight = 8.0;
    final chartW = size.width - padLeft - padRight;
    final chartH = size.height - padTop - padBottom;

    // Value range, widened to include the goal so its line stays on-canvas.
    var minV = values.reduce((a, b) => a < b ? a : b);
    var maxV = values.reduce((a, b) => a > b ? a : b);
    if (target != null) {
      minV = target! < minV ? target! : minV;
      maxV = target! > maxV ? target! : maxV;
    }
    final span = (maxV - minV).abs();

    double y(double v) {
      if (span < 1e-9) return padTop + chartH / 2; // flat series
      return padTop + (1 - (v - minV) / span) * chartH;
    }

    double x(int i) {
      if (values.length == 1) return padLeft + chartW / 2;
      return padLeft + (i / (values.length - 1)) * chartW;
    }

    // Baseline rule along the bottom.
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      Paint()
        ..color = NotebookColors.paperLine
        ..strokeWidth = 1,
    );

    // Dashed goal line.
    if (target != null) {
      final gy = y(target!);
      _drawDashedLine(
        canvas,
        Offset(padLeft, gy),
        Offset(size.width - padRight, gy),
        Paint()
          ..color = NotebookColors.marginLine
          ..strokeWidth = 1.5,
      );
      if (showGoalLabel) {
        final tp = TextPainter(
          text: const TextSpan(
            text: 'goal',
            style: TextStyle(
              fontFamily: 'Caveat',
              fontSize: 14,
              color: NotebookColors.inkSoft,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(size.width - padRight - tp.width, gy - tp.height - 1));
      }
    }

    // The ink polyline.
    final linePaint = Paint()
      ..color = NotebookColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(x(0), y(values.first));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(x(i), y(values[i]));
    }
    canvas.drawPath(path, linePaint);

    // Dots at each point, with a filled marker on the latest.
    if (showDots) {
      final dot = Paint()..color = NotebookColors.ink;
      final hollow = Paint()
        ..color = NotebookColors.paper
        ..style = PaintingStyle.fill;
      for (var i = 0; i < values.length; i++) {
        final center = Offset(x(i), y(values[i]));
        if (i == values.length - 1) {
          canvas.drawCircle(center, 3.5, dot);
        } else {
          canvas.drawCircle(center, 2.5, hollow);
          canvas.drawCircle(
            center,
            2.5,
            Paint()
              ..color = NotebookColors.ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dash = 5.0;
    const gap = 4.0;
    final total = (end - start).distance;
    final dir = (end - start) / total;
    var drawn = 0.0;
    while (drawn < total) {
      final from = start + dir * drawn;
      final to = start + dir * (drawn + dash).clamp(0, total).toDouble();
      canvas.drawLine(from, to, paint);
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      !listEquals(old.values, values) ||
      old.target != target ||
      old.showDots != showDots ||
      old.showGoalLabel != showGoalLabel ||
      old.strokeWidth != strokeWidth;
}

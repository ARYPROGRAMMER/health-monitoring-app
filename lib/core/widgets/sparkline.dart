import 'package:flutter/material.dart';

/// A compact, axis-less trend line with a soft gradient fill and an end dot.
/// Used inside metric tiles to show the recent shape of a series at a glance.
class Sparkline extends StatelessWidget {
  const Sparkline({
    required this.values,
    required this.color,
    this.height = 30,
    super.key,
  });

  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return SizedBox(height: height);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _SparklinePainter(values, color)),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final span = (max - min).abs() < 0.0001 ? 1.0 : max - min;

    Offset at(int i) {
      final x = values.length == 1 ? 0.0 : i / (values.length - 1) * size.width;
      final y = size.height - ((values[i] - min) / span) * (size.height * 0.86) -
          size.height * 0.07;
      return Offset(x, y);
    }

    final line = Path();
    for (var i = 0; i < values.length; i++) {
      final p = at(i);
      i == 0 ? line.moveTo(p.dx, p.dy) : line.lineTo(p.dx, p.dy);
    }

    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    final end = at(values.length - 1);
    canvas.drawCircle(end, 2.8, Paint()..color = color);
    canvas.drawCircle(
      end,
      4.8,
      Paint()..color = color.withValues(alpha: 0.25),
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color;
}

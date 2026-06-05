import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A repeating ECG / heartbeat trace on a faint grid (Heart metric).
class EcgPainter extends CustomPainter {
  EcgPainter({required this.color, required this.gridColor});

  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    const cell = 26.0;
    for (double x = 0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final mid = size.height * 0.55;
    final path = Path()..moveTo(0, mid);
    const period = 96.0;
    for (double x = 0; x < size.width; x += period) {
      path
        ..lineTo(x + 10, mid)
        ..lineTo(x + 18, mid - 6)
        ..lineTo(x + 24, mid)
        ..lineTo(x + 30, mid + 34)
        ..lineTo(x + 36, mid - size.height * 0.42)
        ..lineTo(x + 42, mid + 18)
        ..lineTo(x + 50, mid)
        ..lineTo(x + period, mid);
    }

    final glow = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, glow);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(EcgPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.gridColor != gridColor;
}

/// A dotted trail with footprint marks (Steps metric).
class FootstepsPainter extends CustomPainter {
  FootstepsPainter({required this.color, required this.muted});

  final Color color;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * 0.5;
    final dash = Paint()
      ..color = muted
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (double x = 0; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, y), Offset(x + 5, y), dash);
    }

    final foot = Paint()..color = color;
    final faint = Paint()..color = color.withValues(alpha: 0.4);
    for (int i = 0; i < 9; i++) {
      final x = 14.0 + i * (size.width - 28) / 9;
      final up = i.isEven;
      final cy = y + (up ? -7 : 7);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, cy), width: 11, height: 16),
        i < 5 ? foot : faint,
      );
    }
  }

  @override
  bool shouldRepaint(FootstepsPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.muted != muted;
}

/// Scattered oxygen molecules drifting along a strip (Blood Oxygen metric).
class BubblesPainter extends CustomPainter {
  BubblesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7);
    for (int i = 0; i < 26; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 2.0 + rng.nextDouble() * 7;
      final filled = rng.nextBool();
      final paint = Paint()
        ..color = color.withValues(alpha: 0.18 + rng.nextDouble() * 0.5)
        ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(BubblesPainter oldDelegate) => oldDelegate.color != color;
}

/// A flame silhouette graph for Calories.
class FlamePainter extends CustomPainter {
  FlamePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(3);
    final path = Path()..moveTo(0, size.height);
    double x = 0;
    while (x < size.width) {
      final peak = size.height * (0.15 + rng.nextDouble() * 0.7);
      path
        ..lineTo(x + 6, peak)
        ..lineTo(x + 12, size.height * (0.5 + rng.nextDouble() * 0.4));
      x += 18;
    }
    path
      ..lineTo(size.width, size.height)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withValues(alpha: 0.05)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(FlamePainter oldDelegate) => oldDelegate.color != color;
}

/// A stylised street map with a glowing accent route (dashboard map card).
class RouteMapPainter extends CustomPainter {
  RouteMapPainter({required this.color, required this.line, required this.base});

  final Color color;
  final Color line;
  final Color base;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);

    final rng = math.Random(42);
    final road = Paint()
      ..color = line
      ..strokeWidth = 1.1;
    for (int i = 0; i < 14; i++) {
      final y = rng.nextDouble() * size.height;
      final wob = rng.nextDouble() * 30 - 15;
      canvas.drawLine(Offset(-10, y), Offset(size.width + 10, y + wob), road);
    }
    for (int i = 0; i < 10; i++) {
      final x = rng.nextDouble() * size.width;
      final wob = rng.nextDouble() * 30 - 15;
      canvas.drawLine(Offset(x, -10), Offset(x + wob, size.height + 10), road);
    }

    final route = Path()
      ..moveTo(size.width * 0.12, size.height + 8)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.7,
        size.width * 0.34,
        size.height * 0.55,
        size.width * 0.5,
        size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.41,
        size.width * 0.62,
        size.height * 0.2,
        size.width * 0.78,
        -8,
      );
    final glow = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(route, glow);
    canvas.drawPath(route, stroke);

    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.48), 5, Paint()..color = color);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.48),
      5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(RouteMapPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.line != line ||
      oldDelegate.base != base;
}

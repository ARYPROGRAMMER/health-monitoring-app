import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({
    required this.child,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final value = _controller.value;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + math.sin(value * math.pi * 2) * 0.22, -1),
              end: Alignment(1, 1 - math.cos(value * math.pi * 2) * 0.22),
              colors: isDark
                  ? const [
                      Color(0xFF061114),
                      Color(0xFF082D34),
                      Color(0xFF10172A),
                    ]
                  : const [
                      Color(0xFFEFFDF9),
                      Color(0xFFEAF1FF),
                      Color(0xFFFFF7F8),
                    ],
            ),
          ),
          child: CustomPaint(
            painter: _SignalFieldPainter(progress: value, isDark: isDark),
            child: Padding(padding: widget.padding, child: child),
          ),
        );
      },
    );
  }
}

class _SignalFieldPainter extends CustomPainter {
  const _SignalFieldPainter({required this.progress, required this.isDark});

  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = (isDark ? Colors.white : const Color(0xFF0F766E)).withValues(
        alpha: isDark ? 0.05 : 0.07,
      );

    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF0D9488).withValues(alpha: isDark ? 0.18 : 0.16);

    final spacing = size.width < 430 ? 46.0 : 58.0;

    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      final path = Path();
      final offset = math.sin(progress * math.pi * 2 + y * 0.018) * 14;
      path.moveTo(0, y + offset);

      final step = math.max<double>(size.width / 5, 20.0);
      for (double x = 0; x <= size.width + step; x += step) {
        final nextY =
            y + math.sin((x * 0.01) + progress * math.pi * 2) * 12 + offset;
        path.lineTo(x, nextY);
      }

      canvas.drawPath(path, basePaint);
    }

    final activePath = Path();
    final startY =
        size.height * (0.68 + math.sin(progress * math.pi * 2) * 0.04);
    activePath.moveTo(size.width * 0.08, startY);
    activePath.lineTo(size.width * 0.22, startY);
    activePath.lineTo(size.width * 0.31, startY - 30);
    activePath.lineTo(size.width * 0.45, startY + 34);
    activePath.lineTo(size.width * 0.58, startY - 26);
    activePath.lineTo(size.width * 0.78, startY - 26);
    activePath.lineTo(size.width * 0.92, startY - 4);
    canvas.drawPath(activePath, accentPaint);
  }

  @override
  bool shouldRepaint(covariant _SignalFieldPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}

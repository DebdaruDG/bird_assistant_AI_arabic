import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app/theme_provider.dart';

class SunMoonPainter extends CustomPainter {
  final bool isDarkMode;

  SunMoonPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint();

    if (isDarkMode) {
      // Draw moon
      paint.color = Colors.grey.shade300;
      canvas.drawCircle(center, size.width * 0.3, paint);

      // Draw craters
      paint.color = Colors.grey.shade600;
      canvas.drawCircle(center.translate(-6, -4), 3, paint);
      canvas.drawCircle(center.translate(4, 6), 2, paint);
      canvas.drawCircle(center.translate(8, -5), 1.5, paint);
    } else {
      // Draw sun
      paint.color = Colors.amber;
      canvas.drawCircle(center, size.width * 0.3, paint);

      // Draw sun rays
      final rayPaint =
          Paint()
            ..color = Colors.amberAccent
            ..strokeWidth = 2;

      for (int i = 0; i < 8; i++) {
        final angle = i * (360 / 8) * 3.1416 / 180;
        final start = center + Offset.fromDirection(angle, size.width * 0.35);
        final end = center + Offset.fromDirection(angle, size.width * 0.45);
        canvas.drawLine(start, end, rayPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AnimatedSunMoonPainter extends CustomPainter {
  final bool isDarkMode;
  final double animationValue; // from 0.0 to 1.0

  AnimatedSunMoonPainter({
    required this.isDarkMode,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint();

    if (isDarkMode) {
      // Draw moon (floating effect)
      final floatOffset = Offset(0, 5 * sin(animationValue * 2 * pi));
      final moonCenter = center + floatOffset;

      paint.color = Colors.grey.shade300;
      canvas.drawCircle(moonCenter, size.width * 0.3, paint);

      paint.color = Colors.grey.shade600;
      canvas.drawCircle(moonCenter.translate(-6, -4), 3, paint);
      canvas.drawCircle(moonCenter.translate(4, 6), 2, paint);
      canvas.drawCircle(moonCenter.translate(8, -5), 1.5, paint);
    } else {
      // Draw sun
      paint.color = Colors.amber;
      canvas.drawCircle(center, size.width * 0.3, paint);

      // Rotating rays
      final rayPaint =
          Paint()
            ..color = Colors.amberAccent
            ..strokeWidth = 2;

      for (int i = 0; i < 8; i++) {
        final angle = (i * pi / 4) + (animationValue * 2 * pi); // add rotation
        final start = center + Offset.fromDirection(angle, size.width * 0.35);
        final end = center + Offset.fromDirection(angle, size.width * 0.45);
        canvas.drawLine(start, end, rayPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AnimatedSunMoonWidget extends StatefulWidget {
  const AnimatedSunMoonWidget({super.key});

  @override
  State<AnimatedSunMoonWidget> createState() => _AnimatedSunMoonWidgetState();
}

class _AnimatedSunMoonWidgetState extends State<AnimatedSunMoonWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(); // Loop forever
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder:
          (context, themeState, _) => AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(100, 100),
                painter: AnimatedSunMoonPainter(
                  isDarkMode: themeState.isDarkMode,
                  animationValue: _controller.value,
                ),
              );
            },
          ),
    );
  }
}

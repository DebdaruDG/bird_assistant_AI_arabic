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
    final double radius = size.width * 0.3;

    if (isDarkMode) {
      // Moon with gradient and more craters
      final gradient = RadialGradient(
        colors: [Colors.grey.shade300, Colors.grey.shade800],
        center: Alignment.center,
        radius: 0.8,
      );

      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()..shader = gradient.createShader(rect);
      canvas.drawCircle(center, radius, paint);

      // Glow
      canvas.drawCircle(
        center,
        radius + 4,
        Paint()
          ..color = Colors.blueGrey.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Craters
      final craterPaint = Paint()..color = Colors.grey.shade600;
      final craterOffsets = [
        Offset(-6, -4),
        Offset(4, 6),
        Offset(8, -5),
        Offset(-10, 3),
        Offset(2, -9),
        Offset(6, 9),
      ];
      final craterSizes = [3.0, 2.0, 1.5, 2.5, 1.0, 2.2];

      for (int i = 0; i < craterOffsets.length; i++) {
        canvas.drawCircle(
          center.translate(craterOffsets[i].dx, craterOffsets[i].dy),
          craterSizes[i],
          craterPaint,
        );
      }
    } else {
      // Sun with gradient, more rays, and glow
      final gradient = RadialGradient(
        colors: [Colors.amber, Colors.orange],
        center: Alignment.center,
        radius: 0.8,
      );

      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()..shader = gradient.createShader(rect);
      canvas.drawCircle(center, radius, paint);

      // Glow
      canvas.drawCircle(
        center,
        radius + 4,
        Paint()
          ..color = Colors.amberAccent.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Sun rays (16 total)
      final rayPaint =
          Paint()
            ..color = Colors.amberAccent
            ..strokeWidth = 2;

      for (int i = 0; i < 16; i++) {
        final angle = i * (pi / 8);
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
    final double radius = size.width * 0.3;

    if (isDarkMode) {
      // Moon: Gradient surface + floating effect + more craters
      final floatOffset = Offset(0, 5 * sin(animationValue * 2 * pi));
      final moonCenter = center + floatOffset;

      final gradient = RadialGradient(
        colors: [Colors.grey.shade300, Colors.grey.shade800],
        center: Alignment.center,
        radius: 0.8,
      );

      final rect = Rect.fromCircle(center: moonCenter, radius: radius);
      final paint = Paint()..shader = gradient.createShader(rect);
      canvas.drawCircle(moonCenter, radius, paint);

      // Glow effect
      canvas.drawCircle(
        moonCenter,
        radius + 4,
        Paint()
          ..color = Colors.blueGrey.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Craters
      final craterPaint = Paint()..color = Colors.grey.shade600;
      final craterOffsets = [
        Offset(-6, -4),
        Offset(4, 6),
        Offset(8, -5),
        Offset(-10, 3),
        Offset(2, -9),
        Offset(6, 9),
      ];
      final craterSizes = [3.0, 2.0, 1.5, 2.5, 1.0, 2.2];

      for (int i = 0; i < craterOffsets.length; i++) {
        canvas.drawCircle(
          moonCenter.translate(craterOffsets[i].dx, craterOffsets[i].dy),
          craterSizes[i],
          craterPaint,
        );
      }
    } else {
      // Sun: Gradient + 16 rays + glow
      final gradient = RadialGradient(
        colors: [Colors.amber, Colors.orange],
        center: Alignment.center,
        radius: 0.8,
      );

      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()..shader = gradient.createShader(rect);
      canvas.drawCircle(center, radius, paint);

      // Glow effect
      canvas.drawCircle(
        center,
        radius + 4,
        Paint()
          ..color = Colors.amberAccent.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Rotating rays (16 total)
      final rayPaint =
          Paint()
            ..color = Colors.amberAccent
            ..strokeWidth = 2;

      for (int i = 0; i < 16; i++) {
        final angle = (i * pi / 8) + (animationValue * 2 * pi);
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

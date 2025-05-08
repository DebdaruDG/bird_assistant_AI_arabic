import 'dart:ui';
import 'package:bird_instructor/providers/app/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final double blur;
  const GlassmorphismCard({super.key, required this.child, this.blur = 10.0});

  @override
  Widget build(BuildContext context) {
    Provider.of<ThemeProvider>(context).isDarkMode;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color:
                Provider.of<ThemeProvider>(context).isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  Provider.of<ThemeProvider>(context).isDarkMode
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

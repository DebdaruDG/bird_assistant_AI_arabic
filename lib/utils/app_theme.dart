// 2. App Themes
import 'package:flutter/material.dart';

import 'app_color_palette.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.lightBackground,
  primaryColor: AppColors.lightPrimary,
  fontFamily: 'Inter',
  textTheme: appTextTheme(isDark: false),
);

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.darkBackground,
  primaryColor: AppColors.darkPrimary,
  fontFamily: 'Inter',
  textTheme: appTextTheme(isDark: true),
);

// 3. Font and TextTheme
TextTheme appTextTheme({required bool isDark}) {
  final color = isDark ? AppColors.darkText : AppColors.lightText;

  return TextTheme(
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: color,
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: color,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: color,
    ),
  );
}

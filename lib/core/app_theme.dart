import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light() {
    final baseText = GoogleFonts.nunitoTextTheme();

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.cloudBlue,
      brightness: Brightness.light,
      primary: AppColors.oceanBlue,
      secondary: AppColors.sunYellow,
      tertiary: AppColors.leafGreen,
      surface: AppColors.white,
      background: AppColors.cloudBlue,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cloudBlue,
      textTheme: baseText.copyWith(
        displayLarge: baseText.displayLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: AppColors.darkText,
        ),
        displayMedium: baseText.displayMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: AppColors.darkText,
        ),
        headlineMedium: baseText.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.darkText,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textMain,
        ),
        bodyMedium: baseText.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
        labelLarge: baseText.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.sunYellow,
          foregroundColor: AppColors.darkText,
          minimumSize: const Size(200, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF6F8FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppColors.lightGray, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppColors.lightGray, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppColors.oceanBlue, width: 2),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.oceanBlue, size: 24),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}

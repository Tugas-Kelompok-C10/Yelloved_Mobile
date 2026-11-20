import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';
import 'app_sizes.dart';

class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    fontFamily: AppFonts.body,
    scaffoldBackgroundColor: AppColors.paper,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.violet,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.violet,
          onPrimary: AppColors.text,
          primaryContainer: AppColors.violetLightHover,
          onPrimaryContainer: AppColors.violet,
          secondary: AppColors.blue,
          onSecondary: AppColors.violet,
          secondaryContainer: AppColors.lightBlue,
          onSecondaryContainer: AppColors.violet,
          surface: AppColors.paper,
          onSurface: AppColors.violet,
          onSurfaceVariant: AppColors.gray,
          surfaceContainerLowest: AppColors.lightPaper,
          surfaceContainerLow: AppColors.lightPaper,
          surfaceContainer: AppColors.paper,
          surfaceContainerHigh: AppColors.lightBlue,
          surfaceContainerHighest: AppColors.violetLightHover,
          outline: AppColors.border,
          outlineVariant: AppColors.border,
          error: AppColors.error,
          onError: AppColors.lightPaper,
        ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: AppFonts.heading,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppFonts.heading,
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: TextStyle(
        fontFamily: AppFonts.heading,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
    ),
    appBarTheme: const AppBarThemeData(
      backgroundColor: AppColors.violet,
      foregroundColor: AppColors.text,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.violet,
      surfaceTintColor: Colors.transparent,
      height: 80,
      indicatorColor: Colors.transparent,
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(color: AppColors.text, size: 24),
      ),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightPaper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.violet,
        foregroundColor: AppColors.text,
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.violet,
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        borderSide: const BorderSide(color: AppColors.violet, width: 2),
      ),
    ),
  );
}

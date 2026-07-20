import 'package:flutter/material.dart';
import '../AppColor/app_colors.dart';
import '../AppTextStyle/app_text_styles.dart';

/// ============================================================
/// AppTheme — Wires AppColors + AppTextStyles into ThemeData
/// ============================================================
/// USAGE in main.dart:
///   MaterialApp(
///     theme: AppTheme.light,
///     home: MyHomePage(),
///   )
/// ============================================================
abstract class AppTheme {
  const AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'WorkSans',
    scaffoldBackgroundColor: AppColors.bgPrimary,

    // ── ColorScheme ──────────────────────────────────────
    colorScheme: const ColorScheme.light(
      primary: AppColors.actionPrimary,
      onPrimary: AppColors.textInverse,
      secondary: AppColors.actionSecondary,
      onSecondary: AppColors.textInverse,
      surface: AppColors.bgPrimary,
      onSurface: AppColors.textPrimary,
      error: AppColors.statusError,
      onError: AppColors.textInverse,
      outline: AppColors.borderPrimary,
    ),

    // ── TextTheme mapping ────────────────────────────────
    // Maps Figma tokens → Flutter semantic text roles
    textTheme: const TextTheme(
      // Display (Hero / Landing titles)
      displayLarge: AppTextStyles.tenXL96Bold,
      displayMedium: AppTextStyles.nineXL72Bold,
      displaySmall: AppTextStyles.eightXL60Bold,

      // Headlines
      headlineLarge: AppTextStyles.sevenXL48Bold,
      headlineMedium: AppTextStyles.sixXL36Bold,
      headlineSmall: AppTextStyles.fiveXL32Bold,

      // Titles
      titleLarge: AppTextStyles.threeXL28SemiBold,
      titleMedium: AppTextStyles.xl20SemiBold,
      titleSmall: AppTextStyles.lg18SemiBold,

      // Body
      bodyLarge: AppTextStyles.base16Regular,
      bodyMedium: AppTextStyles.sm14Regular,
      bodySmall: AppTextStyles.xs12Regular,

      // Labels / Captions
      labelLarge: AppTextStyles.sm14Medium,
      labelMedium: AppTextStyles.xs12Medium,
      labelSmall: AppTextStyles.xxs9Medium,
    ),

    // ── AppBar ───────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgPrimary,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.base16SemiBold,
      iconTheme: IconThemeData(color: AppColors.iconPrimary),
    ),

    // ── ElevatedButton ───────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.actionPrimary,
        foregroundColor: AppColors.textInverse,
        disabledBackgroundColor: AppColors.actionPrimaryDisabled,
        textStyle: AppTextStyles.base16SemiBold,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    // ── OutlinedButton ───────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.actionSecondary,
        side: const BorderSide(color: AppColors.borderPrimary),
        textStyle: AppTextStyles.base16Medium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    // ── TextButton ───────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.actionPrimary,
        textStyle: AppTextStyles.sm14SemiBold,
      ),
    ),

    // ── InputDecoration (TextField) ───────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgTertiary,
      hintStyle: AppTextStyles.base16Regular.copyWith(
        color: AppColors.textTertiary,
      ),
      labelStyle: AppTextStyles.sm14Medium.copyWith(
        color: AppColors.textSecondary,
      ),
      errorStyle: AppTextStyles.xs12Regular.copyWith(
        color: AppColors.statusError,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderPrimary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderPrimary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderFocus, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderError, width: 2),
      ),
    ),

    // ── Card ─────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.bgPrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSecondary),
      ),
      margin: const EdgeInsets.all(0),
    ),

    // ── Divider ──────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.borderPrimary,
      thickness: 1,
      space: 1,
    ),

    // ── BottomNavigationBar ───────────────────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bgPrimary,
      selectedItemColor: AppColors.actionPrimary,
      unselectedItemColor: AppColors.iconSecondary,
      selectedLabelStyle: AppTextStyles.xxs9Bold,
      unselectedLabelStyle: AppTextStyles.xxs9Regular,
      elevation: 0,
    ),

    // ── SnackBar ─────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.actionSecondary,
      contentTextStyle: AppTextStyles.sm14Regular.copyWith(
        color: AppColors.textInverse,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),

    // ── Chip ─────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.bgTertiaryGrey,
      labelStyle: AppTextStyles.xs12Medium,
      side: const BorderSide(color: AppColors.borderSecondary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
  );
}

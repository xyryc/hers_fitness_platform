import 'package:flutter/material.dart';

/// ============================================================
/// AppColors — Generated from Figma Design Tokens
/// ============================================================
/// Usage:
///   Container(color: AppColors.bgPrimary)
///   Text('Hi', style: TextStyle(color: AppColors.textPrimary))
/// ============================================================
abstract class AppColors {
  const AppColors._();

  // ─── Background Colors ───────────────────────────────────────
  /// #FFFFFF — Main screen/page background
  static const Color bgPrimary = Color(0xFFFFFFFF);

  /// #FDF2F4 — Card, bottom sheet, subtle pink-tinted background
  static const Color bgSecondary = Color(0xFFFDF2F4);

  /// #F7F7F7 — Input fields, chips, neutral surface
  static const Color bgTertiary = Color(0xFFF7F7F7);

  /// #F3F3F4 — Grey tinted surface (tags, badges)
  static const Color bgTertiaryGrey = Color(0xFFF3F3F4);

  // ─── Text Colors ─────────────────────────────────────────────
  /// #121212 — Primary body text, headings
  static const Color textPrimary = Color(0xFF121212);

  /// #4A4A4A — Secondary text, subtitles
  static const Color textSecondary = Color(0xFF4A4A4A);

  /// #7A7A7A — Placeholder, helper text, captions
  static const Color textTertiary = Color(0xFF7A7A7A);

  /// #FFFFFF — Text on dark/colored backgrounds
  static const Color textInverse = Color(0xFFFFFFFF);

  /// #BDBDBD — Disabled text
  static const Color textDisabled = Color(0xFFBDBDBD);

  // ─── Action / Button Colors ───────────────────────────────────
  /// #F7869A — Primary CTA button background, links
  static const Color actionPrimary = Color(0xFFF7869A);

  /// #E06F83 — Primary button hover/pressed state
  static const Color actionPrimaryHover = Color(0xFFE06F83);

  /// #FBC3CC — Primary button disabled state
  static const Color actionPrimaryDisabled = Color(0xFFFBC3CC);

  /// #000000 — Secondary button background
  static const Color actionSecondary = Color(0xFF000000);

  /// #333333 — Secondary button hover/pressed state
  static const Color actionSecondaryHover = Color(0xFF333333);

  // ─── Border Colors ────────────────────────────────────────────
  /// #E0E0E0 — Default input border, divider
  static const Color borderPrimary = Color(0xFFE0E0E0);

  /// #F2F2F2 — Subtle border, card outline
  static const Color borderSecondary = Color(0xFFF2F2F2);

  /// #F7869A — Focused input border
  static const Color borderFocus = Color(0xFFF7869A);

  /// #F7869A @ 25% — Focus ring / glow effect
  static const Color borderFocusEffect = Color(0x40F7869A);

  /// #D32F2F — Error state border
  static const Color borderError = Color(0xFFD32F2F);

  // ─── Status Colors ────────────────────────────────────────────
  /// #16A34A — Success text/icon
  static const Color statusSuccess = Color(0xFF16A34A);

  /// #DCFCE7 — Success background chip/banner
  static const Color statusSuccessSubtle = Color(0xFFDCFCE7);

  /// #D97706 — Warning text/icon
  static const Color statusWarning = Color(0xFFD97706);

  /// #FEF3C7 — Warning background chip/banner
  static const Color statusWarningSubtle = Color(0xFFFEF3C7);

  /// #DC2626 — Error text/icon
  static const Color statusError = Color(0xFFDC2626);

  /// #FEE2E2 — Error background chip/banner
  static const Color statusErrorSubtle = Color(0xFFFEE2E2);

  /// #0284C7 — Info text/icon
  static const Color statusInfo = Color(0xFF0284C7);

  // ─── Icon Colors ──────────────────────────────────────────────
  /// #000000 — Default icon
  static const Color iconPrimary = Color(0xFF000000);

  /// #7A7A7A — Secondary/muted icon
  static const Color iconSecondary = Color(0xFF7A7A7A);

  /// #BDBDBD — Disabled icon
  static const Color iconDisabled = Color(0xFFBDBDBD);

  /// #FFFFFF — Icon on dark background
  static const Color iconInverse = Color(0xFFFFFFFF);

  // ─── Overlay Colors ───────────────────────────────────────────
  /// #197A52 @ 40% — Scrim for bottom sheets with green tint
  static const Color overlayScrim = Color(0x66197A52);

  /// #000000 @ 40% — Modal backdrop
  static const Color overlayModal = Color(0x66000000);

  // Dark theme colors
  static const Color DarkThemeBackground = Color(0xFF2a2a2a);
  static const Color DarkThemeSurface = Color(0xFF3a3a3a);
  static const Color DarkThemeOnSurface = Color(0xFFe0e0e0);
  static const Color DarkThemeOnBackground = Color(0xFFe0e0e0);
  static const Color DarkThemeAppBar = Color(0xFF2a2a2a);
  static const Color DarkThemeCard = Color(0xFF3a3a3a);
  static const Color DarkThemeText = Color(0xFFe0e0e0);
  static const Color DarkThemeSecondaryText = Color(0xFFa0a0a0);
  static const Color DarkThemeDivider = Color(0xFF555555);
  static const Color DarkBlue = Color(0xFF11293A);

  static const Color Red = Color(0xFFF34F4F);
  static const Color Black = Color(0xFF111111);
  static const Color White = Color(0xFFFFFFFF);
}

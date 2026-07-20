import 'package:flutter/material.dart';

/// ============================================================
/// AppTextStyles — Generated from Figma Design Tokens
/// ============================================================
///
/// FONT FAMILIES required in pubspec.yaml:
///   fonts:
///     - family: WorkSans
///       fonts:
///         - asset: assets/fonts/WorkSans-Light.ttf
///           weight: 300
///         - asset: assets/fonts/WorkSans-Regular.ttf
///           weight: 400
///         - asset: assets/fonts/WorkSans-Medium.ttf
///           weight: 500
///         - asset: assets/fonts/WorkSans-SemiBold.ttf
///           weight: 600
///         - asset: assets/fonts/WorkSans-Bold.ttf
///           weight: 700
///         - asset: assets/fonts/WorkSans-ExtraBold.ttf
///           weight: 800
///         - asset: assets/fonts/WorkSans-Black.ttf
///           weight: 900
///     - family: SFPro
///       fonts:
///         - asset: assets/fonts/SFPro-Bold.ttf
///           weight: 700
///
/// USAGE:
///   Text('Hello', style: AppTextStyles.base16Medium)
///   Text('Heading', style: AppTextStyles.xl20Bold)
///
/// NAMING CONVENTION:
///   [size_label][font_size][weight]
///   e.g. xxs9Bold, xs12Regular, sm14SemiBold, base16Light
///   Large sizes: xl20, twoXL24, threeXL28, fourXL30 ...
/// ============================================================
abstract class AppTextStyles {
  const AppTextStyles._();

  static const String _workSans = 'WorkSans';
  static const String _sfPro = 'SFPro';

  // ─── XXS — 9px ───────────────────────────────────────────────

  static const TextStyle xxs9Light = TextStyle(
    fontSize: 9,
    fontFamily: _workSans,
    fontWeight: FontWeight.w300,
    height: 12 / 9,
    letterSpacing: -1,
    decoration: TextDecoration.none,
  );

  static const TextStyle xxs9Regular = TextStyle(
    fontSize: 9,
    fontFamily: _workSans,
    fontWeight: FontWeight.w400,
    height: 12 / 9,
    letterSpacing: -1,
    decoration: TextDecoration.none,
  );

  static const TextStyle xxs9Medium = TextStyle(
    fontSize: 9,
    fontFamily: _workSans,
    fontWeight: FontWeight.w500,
    height: 12 / 9,
    letterSpacing: -1,
    decoration: TextDecoration.none,
  );

  static const TextStyle xxs9SemiBold = TextStyle(
    fontSize: 9,
    fontFamily: _workSans,
    fontWeight: FontWeight.w600,
    height: 12 / 9,
    letterSpacing: -1,
    decoration: TextDecoration.none,
  );

  /// Uses SFPro-Bold as per original Figma token
  static const TextStyle xxs9Bold = TextStyle(
    fontSize: 9,
    fontFamily: _sfPro,
    fontWeight: FontWeight.w700,
    height: 12 / 9,
    letterSpacing: -1,
    decoration: TextDecoration.none,
  );

  // ─── XS — 12px ───────────────────────────────────────────────

  static const TextStyle xs12Light = TextStyle(
    fontSize: 12,
    fontFamily: _workSans,
    fontWeight: FontWeight.w300,
    height: 16 / 12,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle xs12Regular = TextStyle(
    fontSize: 12,
    fontFamily: _workSans,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle xs12Medium = TextStyle(
    fontSize: 12,
    fontFamily: _workSans,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle xs12SemiBold = TextStyle(
    fontSize: 12,
    fontFamily: _workSans,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle xs12Bold = TextStyle(
    fontSize: 12,
    fontFamily: _workSans,
    fontWeight: FontWeight.w700,
    height: 16 / 12,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  // ─── SM — 14px ───────────────────────────────────────────────

  static const TextStyle sm14Light = TextStyle(
    fontSize: 14,
    fontFamily: _workSans,
    fontWeight: FontWeight.w300,
    height: 20 / 14,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle sm14Regular = TextStyle(
    fontSize: 14,
    fontFamily: _workSans,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle sm14Medium = TextStyle(
    fontSize: 14,
    fontFamily: _workSans,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle sm14SemiBold = TextStyle(
    fontSize: 14,
    fontFamily: _workSans,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle sm14Bold = TextStyle(
    fontSize: 14,
    fontFamily: _workSans,
    fontWeight: FontWeight.w700,
    height: 20 / 14,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  // ─── BASE — 16px ─────────────────────────────────────────────

  static const TextStyle base16Light = TextStyle(
    fontSize: 16,
    fontFamily: _workSans,
    fontWeight: FontWeight.w300,
    height: 24 / 16,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle base16Regular = TextStyle(
    fontSize: 16,
    fontFamily: _workSans,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle base16Medium = TextStyle(
    fontSize: 16,
    fontFamily: _workSans,
    fontWeight: FontWeight.w500,
    height: 24 / 16,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle base16SemiBold = TextStyle(
    fontSize: 16,
    fontFamily: _workSans,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle base16Bold = TextStyle(
    fontSize: 16,
    fontFamily: _workSans,
    fontWeight: FontWeight.w700,
    height: 24 / 16,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  // ─── LG — 18px ───────────────────────────────────────────────

  static const TextStyle lg18Light = TextStyle(
    fontSize: 18,
    fontFamily: _workSans,
    fontWeight: FontWeight.w300,
    height: 28 / 18,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle lg18Regular = TextStyle(
    fontSize: 18,
    fontFamily: _workSans,
    fontWeight: FontWeight.w400,
    height: 28 / 18,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle lg18Medium = TextStyle(
    fontSize: 18,
    fontFamily: _workSans,
    fontWeight: FontWeight.w500,
    height: 28 / 18,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle lg18SemiBold = TextStyle(
    fontSize: 18,
    fontFamily: _workSans,
    fontWeight: FontWeight.w600,
    height: 28 / 18,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle lg18Bold = TextStyle(
    fontSize: 18,
    fontFamily: _workSans,
    fontWeight: FontWeight.w700,
    height: 28 / 18,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  // ─── XL — 20px ───────────────────────────────────────────────

  static const TextStyle xl20Light = TextStyle(
    fontSize: 20,
    fontFamily: _workSans,
    fontWeight: FontWeight.w300,
    height: 28 / 20,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle xl20Regular = TextStyle(
    fontSize: 20,
    fontFamily: _workSans,
    fontWeight: FontWeight.w400,
    height: 28 / 20,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle xl20Medium = TextStyle(
    fontSize: 20,
    fontFamily: _workSans,
    fontWeight: FontWeight.w500,
    height: 28 / 20,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle xl20SemiBold = TextStyle(
    fontSize: 20,
    fontFamily: _workSans,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle xl20Bold = TextStyle(
    fontSize: 20,
    fontFamily: _workSans,
    fontWeight: FontWeight.w700,
    height: 28 / 20,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  // ─── 2XL — 24px ──────────────────────────────────────────────

  static const TextStyle twoXL24Light = TextStyle(
    fontSize: 24,
    fontFamily: _workSans,
    fontWeight: FontWeight.w300,
    height: 32 / 24,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle twoXL24Regular = TextStyle(
    fontSize: 24,
    fontFamily: _workSans,
    fontWeight: FontWeight.w400,
    height: 32 / 24,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle twoXL24Medium = TextStyle(
    fontSize: 24,
    fontFamily: _workSans,
    fontWeight: FontWeight.w500,
    height: 32 / 24,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle twoXL24SemiBold = TextStyle(
    fontSize: 24,
    fontFamily: _workSans,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle twoXL24Bold = TextStyle(
    fontSize: 24,
    fontFamily: _workSans,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  // ─── 3XL — 28px ──────────────────────────────────────────────

  static const TextStyle threeXL28Light = TextStyle(
    fontSize: 28,
    fontFamily: _workSans,
    fontWeight: FontWeight.w300,
    height: 1.0,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );

  static const TextStyle threeXL28Regular = TextStyle(
    fontSize: 28,
    fontFamily: _workSans,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );

  static const TextStyle threeXL28Medium = TextStyle(
    fontSize: 28,
    fontFamily: _workSans,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );

  static const TextStyle threeXL28SemiBold = TextStyle(
    fontSize: 28,
    fontFamily: _workSans,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );

  static const TextStyle threeXL28Bold = TextStyle(
    fontSize: 28,
    fontFamily: _workSans,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );

  /// w900 — Black/ExtraBlack weight for display headings
  static const TextStyle threeXL28ExtraBold = TextStyle(
    fontSize: 28,
    fontFamily: _workSans,
    fontWeight: FontWeight.w900,
    height: 1.0,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );

  // ─── 4XL — 30px ──────────────────────────────────────────────

  static const TextStyle fourXL30Light = TextStyle(
    fontSize: 30,
    fontFamily: _workSans,
    fontWeight: FontWeight.w300,
    height: 36 / 30,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle fourXL30Regular = TextStyle(
    fontSize: 30,
    fontFamily: _workSans,
    fontWeight: FontWeight.w400,
    height: 36 / 30,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle fourXL30Medium = TextStyle(
    fontSize: 30,
    fontFamily: _workSans,
    fontWeight: FontWeight.w500,
    height: 36 / 30,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle fourXL30SemiBold = TextStyle(
    fontSize: 30,
    fontFamily: _workSans,
    fontWeight: FontWeight.w600,
    height: 36 / 30,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle fourXL30Bold = TextStyle(
    fontSize: 30,
    fontFamily: _workSans,
    fontWeight: FontWeight.w700,
    height: 36 / 30,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  // ─── 5XL — 32px ──────────────────────────────────────────────

  static const TextStyle fiveXL32Regular = TextStyle(
    fontSize: 32,
    fontFamily: _workSans,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );

  static const TextStyle fiveXL32Medium = TextStyle(
    fontSize: 32,
    fontFamily: _workSans,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );

  static const TextStyle fiveXL32SemiBold = TextStyle(
    fontSize: 32,
    fontFamily: _workSans,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );

  static const TextStyle fiveXL32Bold = TextStyle(
    fontSize: 32,
    fontFamily: _workSans,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );

  /// w900 — Black/ExtraBlack weight for display headings
  static const TextStyle fiveXL32ExtraBold = TextStyle(
    fontSize: 32,
    fontFamily: _workSans,
    fontWeight: FontWeight.w900,
    height: 1.0,
    letterSpacing: 0,
    decoration: TextDecoration.none,
  );

  // ─── 6XL — 36px ──────────────────────────────────────────────

  static const TextStyle sixXL36Light = TextStyle(
    fontSize: 36,
    fontFamily: _workSans,
    fontWeight: FontWeight.w300,
    height: 40 / 36,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle sixXL36Regular = TextStyle(
    fontSize: 36,
    fontFamily: _workSans,
    fontWeight: FontWeight.w400,
    height: 40 / 36,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle sixXL36Medium = TextStyle(
    fontSize: 36,
    fontFamily: _workSans,
    fontWeight: FontWeight.w500,
    height: 40 / 36,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle sixXL36SemiBold = TextStyle(
    fontSize: 36,
    fontFamily: _workSans,
    fontWeight: FontWeight.w600,
    height: 40 / 36,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle sixXL36Bold = TextStyle(
    fontSize: 36,
    fontFamily: _workSans,
    fontWeight: FontWeight.w700,
    height: 40 / 36,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  // ─── 7XL — 48px ──────────────────────────────────────────────

  static const TextStyle sevenXL48Light = TextStyle(
    fontSize: 48,
    fontFamily: _workSans,
    fontWeight: FontWeight.w300,
    height: 1.0,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle sevenXL48Regular = TextStyle(
    fontSize: 48,
    fontFamily: _workSans,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle sevenXL48Medium = TextStyle(
    fontSize: 48,
    fontFamily: _workSans,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle sevenXL48SemiBold = TextStyle(
    fontSize: 48,
    fontFamily: _workSans,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle sevenXL48Bold = TextStyle(
    fontSize: 48,
    fontFamily: _workSans,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  // ─── 8XL — 60px ──────────────────────────────────────────────

  static const TextStyle eightXL60Light = TextStyle(
    fontSize: 60,
    fontFamily: _workSans,
    fontWeight: FontWeight.w300,
    height: 1.0,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle eightXL60Regular = TextStyle(
    fontSize: 60,
    fontFamily: _workSans,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle eightXL60Medium = TextStyle(
    fontSize: 60,
    fontFamily: _workSans,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle eightXL60SemiBold = TextStyle(
    fontSize: 60,
    fontFamily: _workSans,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle eightXL60Bold = TextStyle(
    fontSize: 60,
    fontFamily: _workSans,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  // ─── 9XL — 72px ──────────────────────────────────────────────

  static const TextStyle nineXL72Light = TextStyle(
    fontSize: 72,
    fontFamily: _workSans,
    fontWeight: FontWeight.w300,
    height: 1.0,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle nineXL72Regular = TextStyle(
    fontSize: 72,
    fontFamily: _workSans,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle nineXL72Medium = TextStyle(
    fontSize: 72,
    fontFamily: _workSans,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle nineXL72SemiBold = TextStyle(
    fontSize: 72,
    fontFamily: _workSans,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle nineXL72Bold = TextStyle(
    fontSize: 72,
    fontFamily: _workSans,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  // ─── 10XL — 96px ─────────────────────────────────────────────

  static const TextStyle tenXL96Light = TextStyle(
    fontSize: 96,
    fontFamily: _workSans,
    fontWeight: FontWeight.w300,
    height: 1.0,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle tenXL96Regular = TextStyle(
    fontSize: 96,
    fontFamily: _workSans,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle tenXL96Medium = TextStyle(
    fontSize: 96,
    fontFamily: _workSans,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle tenXL96SemiBold = TextStyle(
    fontSize: 96,
    fontFamily: _workSans,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  static const TextStyle tenXL96Bold = TextStyle(
    fontSize: 96,
    fontFamily: _workSans,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );
}

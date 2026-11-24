import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';

/// Design System Tokens for TESS Clothes Organizer.
/// Dynamically adapts to Light (default brand kit) and Dark (approved dark spatial)
/// based on the user's theme selection in settings.
class WardrobeTheme {
  WardrobeTheme._();

  /// Returns true if dark mode is selected in Settings or system preference
  static bool get isDark {
    final mode = ThemeController.instance.themeMode;
    if (mode == ThemeMode.dark) return true;
    if (mode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  // --- Backgrounds ---
  static Color get voidBg => isDark ? const Color(0xFF0B100F) : AppColors.lightBg;
  static Color get deepVoidBg => isDark ? const Color(0xFF080D0C) : AppColors.lightSurfaceSubtle;
  static Color get railBg => isDark ? const Color(0xFF0E1514) : AppColors.lightSurfaceSubtle;
  static Color get spatialSurface => isDark ? const Color(0xFF131A19) : AppColors.lightSurface;
  static Color get elevatedSurface => isDark ? const Color(0xFF1B2523) : const Color(0xFFF4F7F6);

  // --- Borders ---
  static Color get border => isDark ? const Color(0xFF22302D) : AppColors.lightBorder;
  static Color get borderSubtle => isDark ? const Color(0xFF1A2624) : AppColors.lightBorderSubtle;
  static Color get borderViolet => isDark ? const Color(0x598B5CF6) : const Color(0x33168F83);
  static Color get borderCyan => isDark ? const Color(0x5922D3EE) : const Color(0x3335B9A5);

  // --- Primary Accents (Aligned with TESS Brand Kit: Teal & Vibrant Mint) ---
  static Color get electricViolet => isDark ? const Color(0xFF8B5CF6) : AppColors.tessTeal;
  static Color get softViolet => isDark ? const Color(0xFFA78BFA) : AppColors.deepTeal;
  static Color get electricCyan => isDark ? const Color(0xFF22D3EE) : AppColors.vibrantMint;
  static Color get skyCyan => isDark ? const Color(0xFF38BDF8) : AppColors.tessTeal;

  // --- Status & Telemetry ---
  static Color get statusSuccess => isDark ? const Color(0xFF34D399) : AppColors.success;
  static Color get statusWarning => isDark ? const Color(0xFFFBBF24) : AppColors.warning;
  static Color get statusCritical => isDark ? const Color(0xFFFB7185) : AppColors.danger;

  // --- Typography Tokens ---
  static Color get textPrimary => isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  static Color get textSecondary => isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  static Color get textMuted => isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
  static Color get textDim => isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8);

  // --- Convenience Aliases for Design System Tokens ---
  static Color get voidBlack => voidBg;
  static Color get subtleBorder => borderSubtle;
  static Color get successEmerald => statusSuccess;
  static Color get warningRose => statusCritical;

  // --- Garment Photography Studio Background ---
  static const Color studioBackground = Color(0xFFFAFAFA);
}

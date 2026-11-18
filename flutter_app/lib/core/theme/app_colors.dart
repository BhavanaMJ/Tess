import 'package:flutter/material.dart';

/// Centralized TESS Brand & Design System Color Palette.
/// Approved TESS Expressive Companion Specification v1.0.
class AppColors {
  // --- Approved TESS Mascot Brand Identity ---
  static const Color vibrantMint = Color(0xFF35B9A5); // Primary Brand Vibrant Mint
  static const Color tessTeal = Color(0xFF168F83);    // TESS Teal
  static const Color deepTeal = Color(0xFF08776E);    // Deep Teal
  static const Color mascotFace = Color(0xFFF4FFFB);  // Luminescent Face Surface
  static const Color mintHighlight = Color(0xFFBDF2E4); // Soft Mint Highlight
  static const Color mascotEyes = Color(0xFF174C48);  // Deep Mascot Eyes

  // Brand aliases
  static const Color primary = vibrantMint;
  static const Color primaryDark = tessTeal;
  static const Color primaryDeep = deepTeal;

  // --- Semantic & Status Colors ---
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444);  // Coral Red
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0EA5E9);    // Sky Blue
  static const Color infoLight = Color(0xFFE0F2FE);
  static const Color neutral = Color(0xFF6B7280);

  // Backward-compatible semantic aliases
  static const Color amber = warning;
  static const Color accentSuccess = success;
  static const Color accentWarning = warning;
  static const Color accentDanger = danger;

  // --- Light Theme Tokens (Default) ---
  static const Color lightBg = Color(0xFFF8FAF9);
  static const Color lightBackground = lightBg;
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightSurfaceSubtle = Color(0xFFF0F4F2);
  static const Color lightSecondary = lightSurfaceSubtle;
  static const Color lightTextPrimary = Color(0xFF111817);
  static const Color lightTextSecondary = Color(0xFF4A5E5A);
  static const Color lightTextMuted = Color(0xFF758A85);
  static const Color lightBorder = Color(0xFFE2EAE7);
  static const Color lightBorderSubtle = Color(0xFFEDF2F0);

  // --- Dark Theme Tokens ---
  static const Color darkBg = Color(0xFF0B100F);
  static const Color darkBackground = darkBg;
  static const Color darkSurface = Color(0xFF131A19);
  static const Color darkSurfaceElevated = Color(0xFF1B2523);
  static const Color darkSurfaceSubtle = Color(0xFF17201E);
  static const Color darkTextPrimary = Color(0xFFF4FFFB);
  static const Color darkTextSecondary = Color(0xFFA5B8B4);
  static const Color darkTextMuted = Color(0xFF637874);
  static const Color darkBorder = Color(0xFF22302D);
  static const Color darkBorderSubtle = Color(0xFF1A2624);

  // --- Static Defaults for Const Expressions (Backwards Compatible) ---
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color textMuted = lightTextMuted;
  static const Color border = lightBorder;
  static const Color borderSubtle = lightBorderSubtle;

  // --- Dynamic Theme Adaptors ---
  static Color dynamicBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBg : lightBg;

  static Color dynamicSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurface : lightSurface;

  static Color dynamicSurfaceElevated(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurfaceElevated : lightSurfaceElevated;

  static Color dynamicSurfaceSubtle(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurfaceSubtle : lightSurfaceSubtle;

  static Color dynamicTextPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;

  static Color dynamicTextSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary;

  static Color dynamicTextMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextMuted : lightTextMuted;

  static Color dynamicBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBorder : lightBorder;

  static Color dynamicBorderSubtle(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBorderSubtle : lightBorderSubtle;

  // --- Preserved Static Tokens for Existing Dark Widgets ---
  static const Color bgVoid = darkBg;
  static const Color bgPrimary = darkBg;
  static const Color bgSecondary = darkSurface;
  static const Color bgSurface = darkSurface;
  static const Color bgElevated = darkSurfaceElevated;
  static const Color violet = vibrantMint;
  static const Color violetLight = mintHighlight;
  static const Color cyan = tessTeal;
  static const Color ice = mintHighlight;
  static const Color borderViolet = Color(0x5935B9A5);
  static const Color borderCyan = Color(0x59168F83);
}

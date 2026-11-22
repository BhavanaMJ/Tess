import 'package:flutter/material.dart';

/// Dark Spatial Design System Tokens for TESS Clothes Organizer.
/// Strictly implements the dark visual identity with electric violet and cyan accents.
class WardrobeTheme {
  WardrobeTheme._();

  // Backgrounds
  static const Color voidBg = Color(0xFF05060A);
  static const Color deepVoidBg = Color(0xFF080910);
  static const Color railBg = Color(0xFF0B0D18);
  static const Color spatialSurface = Color(0xFF111426);
  static const Color elevatedSurface = Color(0xFF171A2D);

  // Borders
  static const Color border = Color(0x1FFFFFFF); // 12% white
  static const Color borderSubtle = Color(0x0FFFFFFF); // 6% white
  static const Color borderViolet = Color(0x598B5CF6);
  static const Color borderCyan = Color(0x5922D3EE);

  // Primary Accents
  static const Color electricViolet = Color(0xFF8B5CF6);
  static const Color softViolet = Color(0xFFA78BFA);
  static const Color electricCyan = Color(0xFF22D3EE);
  static const Color skyCyan = Color(0xFF38BDF8);

  // Status & Telemetry
  static const Color statusSuccess = Color(0xFF34D399);
  static const Color statusWarning = Color(0xFFFBBF24);
  static const Color statusCritical = Color(0xFFFB7185);

  // Typography Tokens
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDim = Color(0xFF475569);

  // Garment Photography Studio Background
  static const Color studioBackground = Color(0xFFFAFAFA);
}


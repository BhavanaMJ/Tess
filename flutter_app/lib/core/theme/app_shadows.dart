import 'package:flutter/material.dart';

/// Centralized Elevation and Shadow System for TESS.
class AppShadows {
  // Light Theme Shadows (Subtle, soft diffusion)
  static const List<BoxShadow> lightSubtle = [
    BoxShadow(
      color: Color(0x0A000000), // 4% black
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> lightCard = [
    BoxShadow(
      color: Color(0x0F000000), // 6% black
      offset: Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> lightElevated = [
    BoxShadow(
      color: Color(0x14000000), // 8% black
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  // Dark Theme Shadows (Soft deep glow & depth)
  static const List<BoxShadow> darkSubtle = [
    BoxShadow(
      color: Color(0x33000000),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> darkCard = [
    BoxShadow(
      color: Color(0x4D000000),
      offset: Offset(0, 4),
      blurRadius: 14,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> darkElevated = [
    BoxShadow(
      color: Color(0x66000000),
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  // Brand Aura Glows
  static List<BoxShadow> mintGlow({double opacity = 0.25, double blur = 16}) => [
        BoxShadow(
          color: const Color(0xFF35B9A5).withValues(alpha: opacity),
          offset: const Offset(0, 4),
          blurRadius: blur,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> card(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkCard : lightCard;
  }

  static List<BoxShadow> elevated(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkElevated : lightElevated;
  }
}

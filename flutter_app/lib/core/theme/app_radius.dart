import 'package:flutter/material.dart';

/// Centralized Corner Radius System for TESS.
class AppRadius {
  // Raw scalar radius values
  static const double rawXs = 4.0;
  static const double rawSm = 8.0;
  static const double rawMd = 12.0;
  static const double rawLg = 16.0;
  static const double rawXl = 20.0;
  static const double rawXxl = 24.0;
  static const double rawPill = 999.0;

  // Primary BorderRadius Constants
  static const BorderRadius xs = BorderRadius.all(Radius.circular(rawXs));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(rawSm));
  static const BorderRadius md = BorderRadius.all(Radius.circular(rawMd));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(rawLg));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(rawXl));
  static const BorderRadius xxl = BorderRadius.all(Radius.circular(rawXxl));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(rawPill));

  // Semantic Aliases
  static const BorderRadius card = lg;
  static const BorderRadius button = pill;

  // Backwards-compatible radius* aliases
  static const BorderRadius radiusXs = xs;
  static const BorderRadius radiusSm = sm;
  static const BorderRadius radiusMd = md;
  static const BorderRadius radiusLg = lg;
  static const BorderRadius radiusXl = xl;
  static const BorderRadius radiusXxl = xxl;
  static const BorderRadius radiusPill = pill;
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../mascot/tess_mascot_state.dart';

/// The 9 Approved Emotion States for the TESS AI Companion.
enum TessEmotion {
  idle,
  thinking,
  happy,
  attention,
  planning,
  confirming,
  acting,
  success,
  error;

  /// Human-friendly display label for UI and telemetry
  String get label {
    switch (this) {
      case TessEmotion.idle:
        return 'Present & Attentive';
      case TessEmotion.thinking:
        return 'Synthesizing...';
      case TessEmotion.happy:
        return 'Delighted';
      case TessEmotion.attention:
        return 'Observing Closely';
      case TessEmotion.planning:
        return 'Formulating Strategy';
      case TessEmotion.confirming:
        return 'Awaiting Confirmation';
      case TessEmotion.acting:
        return 'Executing Action';
      case TessEmotion.success:
        return 'Accomplished';
      case TessEmotion.error:
        return 'Needs Attention';
    }
  }

  /// Ambient reactive aura color
  Color get auraColor {
    switch (this) {
      case TessEmotion.idle:
        return AppColors.vibrantMint;
      case TessEmotion.thinking:
        return AppColors.tessTeal;
      case TessEmotion.happy:
        return AppColors.vibrantMint;
      case TessEmotion.attention:
        return AppColors.warning;
      case TessEmotion.planning:
        return AppColors.tessTeal;
      case TessEmotion.confirming:
        return AppColors.warning;
      case TessEmotion.acting:
        return AppColors.vibrantMint;
      case TessEmotion.success:
        return AppColors.vibrantMint;
      case TessEmotion.error:
        return AppColors.danger;
    }
  }

  /// Pacing for breathing / floating cycle in milliseconds
  int get breathDurationMs {
    switch (this) {
      case TessEmotion.idle:
        return 3200;
      case TessEmotion.thinking:
        return 1600;
      case TessEmotion.happy:
        return 1200;
      case TessEmotion.attention:
        return 2200;
      case TessEmotion.planning:
        return 1800;
      case TessEmotion.confirming:
        return 2400;
      case TessEmotion.acting:
        return 1400;
      case TessEmotion.success:
        return 1000;
      case TessEmotion.error:
        return 3600;
    }
  }

  /// Convert to equivalent TessMascotState
  TessMascotState toTessMascotState() {
    switch (this) {
      case TessEmotion.idle:
        return TessMascotState.idle;
      case TessEmotion.thinking:
        return TessMascotState.thinking;
      case TessEmotion.happy:
        return TessMascotState.happy;
      case TessEmotion.attention:
        return TessMascotState.attention;
      case TessEmotion.planning:
        return TessMascotState.planning;
      case TessEmotion.confirming:
        return TessMascotState.confirming;
      case TessEmotion.acting:
        return TessMascotState.acting;
      case TessEmotion.success:
        return TessMascotState.success;
      case TessEmotion.error:
        return TessMascotState.error;
    }
  }
}

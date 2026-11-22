import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'tess_emotion.dart';

/// Organic Vector CustomPainter for the Expressive TESS Companion.
/// Renders fluid asymmetrical silhouettes, responsive facial features (eyes, eyebrows, mouth),
/// sensory antenna, and emotion-reactive luminescent glow.
class TessCompanionPainter extends CustomPainter {
  final TessEmotion emotion;
  final double breathProgress; // 0.0 to 1.0 (sine breathing cycle)
  final double blinkProgress;  // 0.0 (open) to 1.0 (fully closed)
  final double transitionProgress; // 0.0 to 1.0 (expression transition interpolation)

  TessCompanionPainter({
    required this.emotion,
    required this.breathProgress,
    required this.blinkProgress,
    this.transitionProgress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.52);

    // 1. Dynamic Float & Squash-Stretch Physics based on Emotion
    double floatY = math.sin(breathProgress * math.pi) * 3.5;
    double scaleX = 1.0;
    double scaleY = 1.0;

    switch (emotion) {
      case TessEmotion.happy:
      case TessEmotion.success:
        // Bouncy squash & stretch
        final bounce = math.sin(breathProgress * math.pi * 2);
        floatY = -math.max(0.0, bounce) * 5.5;
        scaleX = 1.0 + (bounce * 0.05);
        scaleY = 1.0 - (bounce * 0.04);
        break;
      case TessEmotion.thinking:
        // Gentle forward tilt
        floatY = math.sin(breathProgress * math.pi) * 2.0;
        break;
      case TessEmotion.attention:
        // Alert upward stretch
        scaleY = 1.03;
        scaleX = 0.98;
        floatY = -2.0;
        break;
      case TessEmotion.error:
        // Sympathetic lower slump
        floatY = 2.5 + (math.sin(breathProgress * math.pi) * 1.5);
        scaleX = 1.02;
        scaleY = 0.97;
        break;
      default:
        scaleX = 1.0 + (breathProgress * 0.025);
        scaleY = 1.0 - (breathProgress * 0.015);
        break;
    }

    canvas.save();
    canvas.translate(center.dx, center.dy + floatY);
    canvas.scale(scaleX, scaleY);
    canvas.translate(-center.dx, -center.dy);

    // 2. Emotion-Reactive Luminescent Aura
    _drawAura(canvas, center, w, h);

    // 3. Sensory Top Antenna Node
    _drawAntenna(canvas, center, w, h);

    // 4. Secondary Rear Flowing Form (Deep Teal)
    _drawRearSilhouette(canvas, w, h);

    // 5. Primary Front Flowing Form (Mint-Teal Fluid Cloud)
    _drawMainSilhouette(canvas, w, h);

    // 6. Soft Mint Highlight Sheen
    _drawTopContourHighlight(canvas, w, h);

    // 7. Luminescent Face Plateau
    _drawFacePlateau(canvas, center, w, h);

    // 8. Expressive Facial Features: Eyebrows, Eyes, Mouth
    _drawFaceFeatures(canvas, center, w, h);

    canvas.restore();
  }

  void _drawAura(Canvas canvas, Offset center, double w, double h) {
    final auraPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16.0)
      ..color = emotion.auraColor.withValues(alpha: 0.26);

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: w * 0.86,
        height: h * 0.74,
      ),
      auraPaint,
    );
  }

  void _drawAntenna(Canvas canvas, Offset center, double w, double h) {
    final antennaBase = Offset(center.dx + (w * 0.04), h * 0.18);
    double tiltX = 0.0;
    double tiltY = 0.0;

    switch (emotion) {
      case TessEmotion.thinking:
      case TessEmotion.planning:
        tiltX = 4.0;
        tiltY = -2.0;
        break;
      case TessEmotion.attention:
        tiltX = 0.0;
        tiltY = -4.0;
        break;
      case TessEmotion.happy:
      case TessEmotion.success:
        tiltX = math.sin(breathProgress * math.pi * 2) * 3.0;
        tiltY = -2.0;
        break;
      case TessEmotion.error:
        tiltX = -3.0;
        tiltY = 2.0;
        break;
      default:
        tiltX = math.sin(breathProgress * math.pi) * 1.5;
        break;
    }

    final antennaTip = Offset(antennaBase.dx + tiltX, antennaBase.dy - (h * 0.09) + tiltY);

    // Stem
    final stemPaint = Paint()
      ..color = AppColors.tessTeal
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final stemPath = Path()
      ..moveTo(antennaBase.dx, antennaBase.dy)
      ..quadraticBezierTo(
        antennaBase.dx + (tiltX * 0.5),
        antennaBase.dy - (h * 0.045),
        antennaTip.dx,
        antennaTip.dy,
      );
    canvas.drawPath(stemPath, stemPaint);

    // Glowing Sensory Orb Tip
    final orbGlowPaint = Paint()
      ..color = emotion.auraColor.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawCircle(antennaTip, 4.2, orbGlowPaint);

    final orbPaint = Paint()
      ..color = AppColors.mintHighlight
      ..style = PaintingStyle.fill;
    canvas.drawCircle(antennaTip, 3.2, orbPaint);
  }

  void _drawRearSilhouette(Canvas canvas, double w, double h) {
    final rearPath = Path();
    rearPath.moveTo(w * 0.18, h * 0.52);
    rearPath.cubicTo(w * 0.12, h * 0.22, w * 0.45, h * 0.12, w * 0.68, h * 0.28);
    rearPath.cubicTo(w * 0.92, h * 0.40, w * 0.88, h * 0.78, w * 0.62, h * 0.86);
    rearPath.cubicTo(w * 0.38, h * 0.92, w * 0.22, h * 0.78, w * 0.18, h * 0.52);
    rearPath.close();

    final rearShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.deepTeal, AppColors.tessTeal],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final rearPaint = Paint()
      ..shader = rearShader
      ..style = PaintingStyle.fill;
    canvas.drawPath(rearPath, rearPaint);
  }

  void _drawMainSilhouette(Canvas canvas, double w, double h) {
    final mainPath = Path();
    mainPath.moveTo(w * 0.22, h * 0.48);
    mainPath.cubicTo(w * 0.20, h * 0.18, w * 0.52, h * 0.16, w * 0.74, h * 0.26);
    mainPath.cubicTo(w * 0.94, h * 0.36, w * 0.90, h * 0.72, w * 0.70, h * 0.82);
    mainPath.cubicTo(w * 0.48, h * 0.90, w * 0.24, h * 0.75, w * 0.22, h * 0.48);
    mainPath.close();

    final mainShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.vibrantMint, AppColors.tessTeal],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final mainPaint = Paint()
      ..shader = mainShader
      ..style = PaintingStyle.fill;
    canvas.drawPath(mainPath, mainPaint);
  }

  void _drawTopContourHighlight(Canvas canvas, double w, double h) {
    final highlightPath = Path();
    highlightPath.moveTo(w * 0.32, h * 0.24);
    highlightPath.cubicTo(w * 0.46, h * 0.18, w * 0.64, h * 0.22, w * 0.72, h * 0.30);

    final highlightPaint = Paint()
      ..color = AppColors.mintHighlight.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawPath(highlightPath, highlightPaint);
  }

  void _drawFacePlateau(Canvas canvas, Offset center, double w, double h) {
    final faceRect = Rect.fromCenter(
      center: Offset(center.dx + (w * 0.02), center.dy * 1.02),
      width: w * 0.52,
      height: h * 0.44,
    );
    final facePaint = Paint()
      ..color = AppColors.mascotFace.withValues(alpha: 0.92)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawOval(faceRect, facePaint);
  }

  void _drawFaceFeatures(Canvas canvas, Offset center, double w, double h) {
    final eyeSpacing = w * 0.14;
    final leftEye = Offset(center.dx - eyeSpacing + (w * 0.02), center.dy);
    final rightEye = Offset(center.dx + eyeSpacing + (w * 0.02), center.dy);

    final eyePaint = Paint()
      ..color = AppColors.mascotEyes
      ..style = PaintingStyle.fill;

    final eyeHighlightPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final featureStrokePaint = Paint()
      ..color = AppColors.mascotEyes
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    // A. EYEBROWS
    _drawEyebrows(canvas, leftEye, rightEye, featureStrokePaint);

    // B. EYES
    _drawEyes(canvas, leftEye, rightEye, eyePaint, eyeHighlightPaint, featureStrokePaint);

    // C. MOUTH
    _drawMouth(canvas, center, w, h, featureStrokePaint);
  }

  void _drawEyebrows(
    Canvas canvas,
    Offset leftEye,
    Offset rightEye,
    Paint strokePaint,
  ) {
    const browWidth = 8.0;
    final browPaint = Paint()
      ..color = AppColors.mascotEyes.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    double leftYOffset = -9.0;
    double rightYOffset = -9.0;
    double leftTilt = 0.0;
    double rightTilt = 0.0;

    switch (emotion) {
      case TessEmotion.thinking:
      case TessEmotion.planning:
        leftYOffset = -7.0;
        leftTilt = 1.5;
        rightYOffset = -11.5;
        rightTilt = -2.0;
        break;
      case TessEmotion.happy:
      case TessEmotion.success:
        leftYOffset = -11.0;
        rightYOffset = -11.0;
        leftTilt = -1.0;
        rightTilt = 1.0;
        break;
      case TessEmotion.attention:
      case TessEmotion.confirming:
        leftYOffset = -12.0;
        rightYOffset = -12.0;
        break;
      case TessEmotion.error:
        leftYOffset = -8.0;
        rightYOffset = -8.0;
        leftTilt = -2.5; // Inner furrow
        rightTilt = 2.5;
        break;
      case TessEmotion.idle:
      case TessEmotion.acting:
        leftYOffset = -9.0;
        rightYOffset = -9.0;
        break;
    }

    // Left eyebrow
    final leftPath = Path()
      ..moveTo(leftEye.dx - (browWidth * 0.5), leftEye.dy + leftYOffset + leftTilt)
      ..quadraticBezierTo(
        leftEye.dx,
        leftEye.dy + leftYOffset - 1.0,
        leftEye.dx + (browWidth * 0.5),
        leftEye.dy + leftYOffset - leftTilt,
      );
    canvas.drawPath(leftPath, browPaint);

    // Right eyebrow
    final rightPath = Path()
      ..moveTo(rightEye.dx - (browWidth * 0.5), rightEye.dy + rightYOffset - rightTilt)
      ..quadraticBezierTo(
        rightEye.dx,
        rightEye.dy + rightYOffset - 1.0,
        rightEye.dx + (browWidth * 0.5),
        rightEye.dy + rightYOffset + rightTilt,
      );
    canvas.drawPath(rightPath, browPaint);
  }

  void _drawEyes(
    Canvas canvas,
    Offset leftEye,
    Offset rightEye,
    Paint eyePaint,
    Paint highlightPaint,
    Paint strokePaint,
  ) {
    switch (emotion) {
      case TessEmotion.happy:
      case TessEmotion.success:
        // Joyful smiling arcs (^ ^)
        final leftArc = Path()
          ..moveTo(leftEye.dx - 6, leftEye.dy + 2)
          ..quadraticBezierTo(leftEye.dx, leftEye.dy - 6, leftEye.dx + 6, leftEye.dy + 2);
        final rightArc = Path()
          ..moveTo(rightEye.dx - 6, rightEye.dy + 2)
          ..quadraticBezierTo(rightEye.dx, rightEye.dy - 6, rightEye.dx + 6, rightEye.dy + 2);

        canvas.drawPath(leftArc, strokePaint);
        canvas.drawPath(rightArc, strokePaint);
        break;

      case TessEmotion.thinking:
      case TessEmotion.planning:
        // Inquisitive gaze shifted up-right
        const radiusX = 4.8;
        const radiusY = 5.8;
        final leftOffset = Offset(leftEye.dx + 1.2, leftEye.dy - 2.2);
        final rightOffset = Offset(rightEye.dx + 1.2, rightEye.dy - 2.2);

        canvas.drawOval(
          Rect.fromCenter(center: leftOffset, width: radiusX * 2, height: radiusY * 2),
          eyePaint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: rightOffset, width: radiusX * 2, height: radiusY * 2),
          eyePaint,
        );

        canvas.drawCircle(Offset(leftOffset.dx + 1.4, leftOffset.dy - 1.8), 1.7, highlightPaint);
        canvas.drawCircle(Offset(rightOffset.dx + 1.4, rightOffset.dy - 1.8), 1.7, highlightPaint);
        break;

      case TessEmotion.attention:
      case TessEmotion.confirming:
        // Wide observant eyes with double catchlights
        const eyeRadius = 6.8;
        canvas.drawCircle(leftEye, eyeRadius, eyePaint);
        canvas.drawCircle(rightEye, eyeRadius, eyePaint);

        // Catchlights
        canvas.drawCircle(Offset(leftEye.dx + 1.8, leftEye.dy - 1.8), 2.0, highlightPaint);
        canvas.drawCircle(Offset(rightEye.dx + 1.8, rightEye.dy - 1.8), 2.0, highlightPaint);
        canvas.drawCircle(Offset(leftEye.dx - 1.8, leftEye.dy + 2.0), 1.0, highlightPaint);
        canvas.drawCircle(Offset(rightEye.dx - 1.8, rightEye.dy + 2.0), 1.0, highlightPaint);
        break;

      case TessEmotion.error:
        // Sympathetic curved eyes
        final leftErr = Path()
          ..moveTo(leftEye.dx - 5.5, leftEye.dy + 1)
          ..quadraticBezierTo(leftEye.dx, leftEye.dy + 5, leftEye.dx + 5.5, leftEye.dy + 1);
        final rightErr = Path()
          ..moveTo(rightEye.dx - 5.5, rightEye.dy + 1)
          ..quadraticBezierTo(rightEye.dx, rightEye.dy + 5, rightEye.dx + 5.5, rightEye.dy + 1);

        canvas.drawPath(leftErr, strokePaint);
        canvas.drawPath(rightErr, strokePaint);
        break;

      case TessEmotion.idle:
      case TessEmotion.acting:
        // Natural oval eyes with blink eyelid
        final effectiveHeight = math.max(0.8, 12.0 * (1.0 - blinkProgress));
        final leftRect = Rect.fromCenter(center: leftEye, width: 8.8, height: effectiveHeight);
        final rightRect = Rect.fromCenter(center: rightEye, width: 8.8, height: effectiveHeight);

        canvas.drawOval(leftRect, eyePaint);
        canvas.drawOval(rightRect, eyePaint);

        if (blinkProgress < 0.6) {
          canvas.drawCircle(Offset(leftEye.dx + 1.6, leftEye.dy - 2.0), 1.8, highlightPaint);
          canvas.drawCircle(Offset(rightEye.dx + 1.6, rightEye.dy - 2.0), 1.8, highlightPaint);
        }
        break;
    }
  }

  void _drawMouth(
    Canvas canvas,
    Offset center,
    double w,
    double h,
    Paint strokePaint,
  ) {
    final mouthCenter = Offset(center.dx + (w * 0.02), center.dy + (h * 0.12));
    final mouthPaint = Paint()
      ..color = AppColors.mascotEyes
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    switch (emotion) {
      case TessEmotion.happy:
      case TessEmotion.success:
        // Wide cheerful smile arc
        final smile = Path()
          ..moveTo(mouthCenter.dx - 6.5, mouthCenter.dy - 1)
          ..quadraticBezierTo(mouthCenter.dx, mouthCenter.dy + 5.0, mouthCenter.dx + 6.5, mouthCenter.dy - 1);
        canvas.drawPath(smile, mouthPaint);
        break;

      case TessEmotion.thinking:
      case TessEmotion.planning:
        // Tiny thoughtful curved line
        final thoughtMouth = Path()
          ..moveTo(mouthCenter.dx - 2.5, mouthCenter.dy)
          ..quadraticBezierTo(mouthCenter.dx, mouthCenter.dy + 1.5, mouthCenter.dx + 2.5, mouthCenter.dy);
        canvas.drawPath(thoughtMouth, mouthPaint);
        break;

      case TessEmotion.attention:
        // Gentle curious "o" mouth
        final openMouthPaint = Paint()
          ..color = AppColors.mascotEyes
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8;
        canvas.drawOval(
          Rect.fromCenter(center: mouthCenter, width: 4.5, height: 5.5),
          openMouthPaint,
        );
        break;

      case TessEmotion.confirming:
        // Soft reassuring subtle smile
        final subtleSmile = Path()
          ..moveTo(mouthCenter.dx - 4.5, mouthCenter.dy)
          ..quadraticBezierTo(mouthCenter.dx, mouthCenter.dy + 2.5, mouthCenter.dx + 4.5, mouthCenter.dy);
        canvas.drawPath(subtleSmile, mouthPaint);
        break;

      case TessEmotion.error:
        // Gentle sympathetic soft downturn
        final softFrown = Path()
          ..moveTo(mouthCenter.dx - 4.5, mouthCenter.dy + 2)
          ..quadraticBezierTo(mouthCenter.dx, mouthCenter.dy - 1.5, mouthCenter.dx + 4.5, mouthCenter.dy + 2);
        canvas.drawPath(softFrown, mouthPaint);
        break;

      case TessEmotion.idle:
      case TessEmotion.acting:
        // Gentle neutral sweet curve
        final neutralCurve = Path()
          ..moveTo(mouthCenter.dx - 4.0, mouthCenter.dy)
          ..quadraticBezierTo(mouthCenter.dx, mouthCenter.dy + 1.8, mouthCenter.dx + 4.0, mouthCenter.dy);
        canvas.drawPath(neutralCurve, mouthPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant TessCompanionPainter oldDelegate) {
    return oldDelegate.emotion != emotion ||
        oldDelegate.breathProgress != breathProgress ||
        oldDelegate.blinkProgress != blinkProgress ||
        oldDelegate.transitionProgress != transitionProgress;
  }
}


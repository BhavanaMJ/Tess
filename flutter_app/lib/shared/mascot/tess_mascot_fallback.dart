import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'tess_mascot_state.dart';

/// Organic Vector Fallback for TESS Mascot Companion.
/// Faithfully implements the approved TESS Expressive Companion Design Specification v1.0:
/// - Asymmetrical, cloud-like organic silhouette composed of two softly blended flowing forms.
/// - Approved Brand Colors: Vibrant Mint (#35B9A5), TESS Teal (#168F83), Deep Teal (#08776E),
///   Luminescent Face (#F4FFFB), Mint Highlight (#BDF2E4), Deep Eyes (#174C48).
/// - Independently animated eyelids and expressive eye curvature.
/// - Idle breathing loop (3.0s) and natural blink cycle (140ms).
class TessMascotFallback extends StatefulWidget {
  final TessMascotState state;
  final double size;
  final bool animate;

  const TessMascotFallback({
    super.key,
    required this.state,
    this.size = 80.0,
    this.animate = true,
  });

  @override
  State<TessMascotFallback> createState() => _TessMascotFallbackState();
}

class _TessMascotFallbackState extends State<TessMascotFallback>
    with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _blinkController;
  late AnimationController _stateController;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    // Idle gentle breathing loop: 3.2 seconds
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // Natural blink cycle: 140ms blink every 3.6s
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    // Expression transition controller: 350ms
    _stateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    if (widget.animate) {
      _startAnimationLoop();
    }
  }

  void _startAnimationLoop() {
    _idleController.repeat(reverse: true);
    _scheduleNextBlink();
  }

  void _scheduleNextBlink() {
    if (!mounted) return;
    _blinkTimer?.cancel();
    _blinkTimer = Timer(const Duration(milliseconds: 3400), () {
      if (mounted && widget.animate) {
        _blinkController.forward().then((_) {
          if (mounted) {
            _blinkController.reverse().then((_) {
              _scheduleNextBlink();
            });
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant TessMascotFallback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _stateController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _blinkTimer = null;
    _idleController.dispose();
    _blinkController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final effectiveAnimate = widget.animate && !disableAnimations;

    // Silhouette ratio approx 1.6 : 1 (width : height)
    final double width = widget.size * 1.35;
    final double height = widget.size * 0.95;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _idleController,
        _blinkController,
        _stateController,
      ]),
      builder: (context, child) {
        final double breathT = effectiveAnimate ? _idleController.value : 0.5;
        final double blinkT = effectiveAnimate ? _blinkController.value : 0.0;

        return SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _TessOrganicPainter(
              state: widget.state,
              breathProgress: breathT,
              blinkProgress: blinkT,
            ),
          ),
        );
      },
    );
  }
}

/// CustomPainter rendering the fluid, asymmetrical cloud silhouette and expressive facial features
class _TessOrganicPainter extends CustomPainter {
  final TessMascotState state;
  final double breathProgress;
  final double blinkProgress;

  _TessOrganicPainter({
    required this.state,
    required this.breathProgress,
    required this.blinkProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // Subtle breathing displacement
    final floatY = math.sin(breathProgress * math.pi) * 3.0;
    final floatScale = 1.0 + (breathProgress * 0.035);

    canvas.save();
    canvas.translate(center.dx, center.dy + floatY);
    canvas.scale(floatScale, floatScale);
    canvas.translate(-center.dx, -center.dy);

    // 1. Soft Ambient Luminescent Aura Glow
    final auraPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14.0)
      ..color = _getAuraColor(state).withValues(alpha: 0.28);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: w * 0.88,
        height: h * 0.78,
      ),
      auraPaint,
    );

    // 2. Secondary Flowing Organic Form (Rear Soft Teal Layer)
    final rearFormPath = Path();
    rearFormPath.moveTo(w * 0.18, h * 0.52);
    rearFormPath.cubicTo(
      w * 0.12, h * 0.22,
      w * 0.45, h * 0.12,
      w * 0.68, h * 0.28,
    );
    rearFormPath.cubicTo(
      w * 0.92, h * 0.40,
      w * 0.88, h * 0.78,
      w * 0.62, h * 0.86,
    );
    rearFormPath.cubicTo(
      w * 0.38, h * 0.92,
      w * 0.22, h * 0.78,
      w * 0.18, h * 0.52,
    );
    rearFormPath.close();

    final rearShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.deepTeal,
        AppColors.tessTeal,
      ],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final rearPaint = Paint()
      ..shader = rearShader
      ..style = PaintingStyle.fill;
    canvas.drawPath(rearFormPath, rearPaint);

    // 3. Primary Flowing Organic Form (Front Luminescent Vibrant Mint Cloud)
    final mainFormPath = Path();
    mainFormPath.moveTo(w * 0.22, h * 0.48);
    mainFormPath.cubicTo(
      w * 0.20, h * 0.18,
      w * 0.52, h * 0.16,
      w * 0.74, h * 0.26,
    );
    mainFormPath.cubicTo(
      w * 0.94, h * 0.36,
      w * 0.90, h * 0.72,
      w * 0.70, h * 0.82,
    );
    mainFormPath.cubicTo(
      w * 0.48, h * 0.90,
      w * 0.24, h * 0.75,
      w * 0.22, h * 0.48,
    );
    mainFormPath.close();

    final mainShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.vibrantMint,
        AppColors.tessTeal,
      ],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final mainPaint = Paint()
      ..shader = mainShader
      ..style = PaintingStyle.fill;
    canvas.drawPath(mainFormPath, mainPaint);

    // 4. Soft Mint Highlight (Top contour sheen)
    final highlightPath = Path();
    highlightPath.moveTo(w * 0.32, h * 0.24);
    highlightPath.cubicTo(
      w * 0.46, h * 0.18,
      w * 0.64, h * 0.22,
      w * 0.72, h * 0.30,
    );
    final highlightPaint = Paint()
      ..color = AppColors.mintHighlight.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawPath(highlightPath, highlightPaint);

    // 5. Luminescent Soft Face Plateau
    final faceRect = Rect.fromCenter(
      center: Offset(center.dx + (w * 0.02), center.dy * 1.02),
      width: w * 0.52,
      height: h * 0.44,
    );
    final facePaint = Paint()
      ..color = AppColors.mascotFace.withValues(alpha: 0.92)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawOval(faceRect, facePaint);

    // 6. Expressive Eyes & Eyelids
    _drawEyes(canvas, center, w, h);

    canvas.restore();
  }

  void _drawEyes(Canvas canvas, Offset center, double w, double h) {
    final eyeSpacing = w * 0.14;
    final leftEyeCenter = Offset(center.dx - eyeSpacing + (w * 0.02), center.dy);
    final rightEyeCenter = Offset(center.dx + eyeSpacing + (w * 0.02), center.dy);

    final eyePaint = Paint()
      ..color = AppColors.mascotEyes
      ..style = PaintingStyle.fill;

    final eyeHighlightPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    switch (state) {
      case TessMascotState.happy:
      case TessMascotState.success:
        // Joyful smiling arcs (^ ^)
        final arcPaint = Paint()
          ..color = AppColors.mascotEyes
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round;

        final leftArc = Path()
          ..moveTo(leftEyeCenter.dx - 6, leftEyeCenter.dy + 2)
          ..quadraticBezierTo(leftEyeCenter.dx, leftEyeCenter.dy - 6, leftEyeCenter.dx + 6, leftEyeCenter.dy + 2);
        final rightArc = Path()
          ..moveTo(rightEyeCenter.dx - 6, rightEyeCenter.dy + 2)
          ..quadraticBezierTo(rightEyeCenter.dx, rightEyeCenter.dy - 6, rightEyeCenter.dx + 6, rightEyeCenter.dy + 2);

        canvas.drawPath(leftArc, arcPaint);
        canvas.drawPath(rightArc, arcPaint);
        break;

      case TessMascotState.thinking:
      case TessMascotState.planning:
        // Inquisitive / looking slightly up
        const eyeRadiusX = 5.0;
        const eyeRadiusY = 6.0;
        final offsetLeft = Offset(leftEyeCenter.dx + 1.0, leftEyeCenter.dy - 2.0);
        final offsetRight = Offset(rightEyeCenter.dx + 1.0, rightEyeCenter.dy - 2.0);

        canvas.drawOval(Rect.fromCenter(center: offsetLeft, width: eyeRadiusX * 2, height: eyeRadiusY * 2), eyePaint);
        canvas.drawOval(Rect.fromCenter(center: offsetRight, width: eyeRadiusX * 2, height: eyeRadiusY * 2), eyePaint);

        // Highlight glint
        canvas.drawCircle(Offset(offsetLeft.dx + 1.5, offsetLeft.dy - 2.0), 1.8, eyeHighlightPaint);
        canvas.drawCircle(Offset(offsetRight.dx + 1.5, offsetRight.dy - 2.0), 1.8, eyeHighlightPaint);
        break;

      case TessMascotState.attention:
      case TessMascotState.confirming:
        // Wide observant eyes
        const eyeRadius = 6.8;
        canvas.drawCircle(leftEyeCenter, eyeRadius, eyePaint);
        canvas.drawCircle(rightEyeCenter, eyeRadius, eyePaint);

        // Double catchlight
        canvas.drawCircle(Offset(leftEyeCenter.dx + 1.8, leftEyeCenter.dy - 1.8), 2.0, eyeHighlightPaint);
        canvas.drawCircle(Offset(rightEyeCenter.dx + 1.8, rightEyeCenter.dy - 1.8), 2.0, eyeHighlightPaint);
        break;

      case TessMascotState.error:
        // Sympathetic soft eyes (flat tops)
        final eyePath = Path();
        eyePath.moveTo(leftEyeCenter.dx - 5, leftEyeCenter.dy);
        eyePath.quadraticBezierTo(leftEyeCenter.dx, leftEyeCenter.dy + 4, leftEyeCenter.dx + 5, leftEyeCenter.dy);
        eyePath.close();

        final errPaint = Paint()
          ..color = AppColors.mascotEyes
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(eyePath, errPaint);

        final rightErrPath = Path()
          ..moveTo(rightEyeCenter.dx - 5, rightEyeCenter.dy)
          ..quadraticBezierTo(rightEyeCenter.dx, rightEyeCenter.dy + 4, rightEyeCenter.dx + 5, rightEyeCenter.dy);
        canvas.drawPath(rightErrPath, errPaint);
        break;

      case TessMascotState.idle:
      case TessMascotState.acting:
        // Natural oval eyes with blink eyelid
        final effectiveHeight = math.max(0.8, 12.0 * (1.0 - blinkProgress));
        final leftRect = Rect.fromCenter(center: leftEyeCenter, width: 9.0, height: effectiveHeight);
        final rightRect = Rect.fromCenter(center: rightEyeCenter, width: 9.0, height: effectiveHeight);

        canvas.drawOval(leftRect, eyePaint);
        canvas.drawOval(rightRect, eyePaint);

        if (blinkProgress < 0.6) {
          canvas.drawCircle(Offset(leftEyeCenter.dx + 1.6, leftEyeCenter.dy - 2.0), 1.8, eyeHighlightPaint);
          canvas.drawCircle(Offset(rightEyeCenter.dx + 1.6, rightEyeCenter.dy - 2.0), 1.8, eyeHighlightPaint);
        }
        break;
    }
  }

  Color _getAuraColor(TessMascotState state) {
    switch (state) {
      case TessMascotState.attention:
        return AppColors.warning;
      case TessMascotState.error:
        return AppColors.danger;
      case TessMascotState.happy:
      case TessMascotState.success:
        return AppColors.vibrantMint;
      case TessMascotState.thinking:
      case TessMascotState.planning:
      case TessMascotState.acting:
        return AppColors.tessTeal;
      case TessMascotState.confirming:
        return AppColors.warning;
      case TessMascotState.idle:
        return AppColors.vibrantMint;
    }
  }

  @override
  bool shouldRepaint(covariant _TessOrganicPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.breathProgress != breathProgress ||
        oldDelegate.blinkProgress != blinkProgress;
  }
}

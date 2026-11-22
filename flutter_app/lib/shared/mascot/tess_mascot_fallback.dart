import 'dart:async';
import 'package:flutter/material.dart';
import '../companion/tess_companion_painter.dart';
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
            painter: TessCompanionPainter(
              emotion: widget.state.toTessEmotion(),
              breathProgress: breathT,
              blinkProgress: blinkT,
              transitionProgress: _stateController.value,
            ),
          ),
        );
      },
    );
  }
}



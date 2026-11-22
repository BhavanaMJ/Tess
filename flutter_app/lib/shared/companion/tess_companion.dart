import 'dart:async';
import 'package:flutter/material.dart';
import 'tess_companion_controller.dart';
import 'tess_companion_painter.dart';
import 'tess_emotion.dart';

/// Predefined standard size variants for the TESS Companion.
enum TessCompanionSize {
  compact(44.0),
  standard(80.0),
  hero(130.0);

  final double dimension;
  const TessCompanionSize(this.dimension);
}

/// The Expressive TESS Mascot AI Companion Widget.
/// Faithfully brings TESS to life through fluid vector animations,
/// expressive eyes, reactive eyebrows, responsive mouth curves, sensory antenna,
/// and emotion-reactive luminescent glow.
class TessCompanion extends StatefulWidget {
  final TessEmotion emotion;
  final TessCompanionController? controller;
  final double? size;
  final TessCompanionSize sizeVariant;
  final bool animate;
  final VoidCallback? onTap;

  const TessCompanion({
    super.key,
    this.emotion = TessEmotion.idle,
    this.controller,
    this.size,
    this.sizeVariant = TessCompanionSize.standard,
    this.animate = true,
    this.onTap,
  });

  /// Convenient Hero constructor for primary focal points (e.g., Home header, Login)
  const TessCompanion.hero({
    super.key,
    this.emotion = TessEmotion.idle,
    this.controller,
    this.size,
    this.animate = true,
    this.onTap,
  }) : sizeVariant = TessCompanionSize.hero;

  /// Convenient Compact constructor for headers, cards, and small indicators
  const TessCompanion.compact({
    super.key,
    this.emotion = TessEmotion.idle,
    this.controller,
    this.size,
    this.animate = true,
    this.onTap,
  }) : sizeVariant = TessCompanionSize.compact;

  @override
  State<TessCompanion> createState() => _TessCompanionState();
}

class _TessCompanionState extends State<TessCompanion> with TickerProviderStateMixin {
  late AnimationController _breathController;
  late AnimationController _blinkController;
  late AnimationController _transitionController;
  Timer? _blinkTimer;

  TessEmotion _currentEmotion = TessEmotion.idle;

  @override
  void initState() {
    super.initState();
    _currentEmotion = widget.controller?.emotion ?? widget.emotion;
    widget.controller?.addListener(_onControllerUpdate);

    // Dynamic breathing controller
    _breathController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _currentEmotion.breathDurationMs),
    );

    // Natural blink controller (140ms duration)
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    // Expression transition controller
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );

    if (widget.animate) {
      _startLoops();
    }
  }

  void _onControllerUpdate() {
    if (widget.controller != null && mounted) {
      _updateEmotion(widget.controller!.emotion);
    }
  }

  void _updateEmotion(TessEmotion newEmotion) {
    if (_currentEmotion != newEmotion) {
      setState(() {
        _currentEmotion = newEmotion;
      });
      // Adjust breath pacing
      _breathController.duration = Duration(milliseconds: newEmotion.breathDurationMs);
      if (!_breathController.isAnimating && widget.animate) {
        _breathController.repeat(reverse: true);
      }
      _transitionController.forward(from: 0.0);
    }
  }

  void _startLoops() {
    _breathController.repeat(reverse: true);
    _scheduleBlink();
  }

  void _scheduleBlink() {
    if (!mounted) return;
    _blinkTimer?.cancel();
    _blinkTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted && widget.animate) {
        _blinkController.forward().then((_) {
          if (mounted) {
            _blinkController.reverse().then((_) {
              _scheduleBlink();
            });
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant TessCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerUpdate);
      widget.controller?.addListener(_onControllerUpdate);
      if (widget.controller != null) {
        _updateEmotion(widget.controller!.emotion);
      }
    } else if (widget.controller == null && oldWidget.emotion != widget.emotion) {
      _updateEmotion(widget.emotion);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerUpdate);
    _blinkTimer?.cancel();
    _blinkTimer = null;
    _breathController.dispose();
    _blinkController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final effectiveAnimate = widget.animate && !disableAnimations;

    final baseSize = widget.size ?? widget.sizeVariant.dimension;
    final width = baseSize * 1.35;
    final height = baseSize * 0.95;

    Widget companion = AnimatedBuilder(
      animation: Listenable.merge([
        _breathController,
        _blinkController,
        _transitionController,
      ]),
      builder: (context, child) {
        final breathT = effectiveAnimate ? _breathController.value : 0.5;
        final blinkT = effectiveAnimate ? _blinkController.value : 0.0;
        final transT = effectiveAnimate ? _transitionController.value : 1.0;

        return SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: TessCompanionPainter(
              emotion: _currentEmotion,
              breathProgress: breathT,
              blinkProgress: blinkT,
              transitionProgress: transT,
            ),
          ),
        );
      },
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: companion,
      );
    }

    return companion;
  }
}


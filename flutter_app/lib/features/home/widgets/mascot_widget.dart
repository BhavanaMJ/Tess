import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum MascotState {
  idle,
  thinking,
  listening,
  speaking,
  intervening,
  attention,
  happy,
}

/// Animated Living Holographic Mascot Orb
class MascotWidget extends StatefulWidget {
  final MascotState state;
  final double size;

  const MascotWidget({
    super.key,
    this.state = MascotState.idle,
    this.size = 72.0,
  });

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _faceText {
    switch (widget.state) {
      case MascotState.happy:
        return '^_^';
      case MascotState.thinking:
        return 'O_O';
      case MascotState.listening:
        return 'O_o';
      case MascotState.speaking:
        return '^o^';
      case MascotState.intervening:
      case MascotState.attention:
        return 'O_O!';
      case MascotState.idle:
        return '•_•';
    }
  }

  Color get _stateColor {
    switch (widget.state) {
      case MascotState.happy:
        return AppColors.success;
      case MascotState.thinking:
        return AppColors.violetLight;
      case MascotState.listening:
        return AppColors.cyan;
      case MascotState.speaking:
        return AppColors.success;
      case MascotState.intervening:
      case MascotState.attention:
        return AppColors.danger;
      case MascotState.idle:
        return AppColors.violet;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _stateColor.withOpacity(0.12),
                  border: Border.all(
                    color: _stateColor,
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _stateColor.withOpacity(0.35),
                      blurRadius: 16.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  _faceText,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: widget.size * 0.28,
                    fontWeight: FontWeight.bold,
                    color: _stateColor,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8.0),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6.0,
              height: 6.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _stateColor,
              ),
            ),
            const SizedBox(width: 6.0),
            Text(
              widget.state.name.toUpperCase(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.0,
                fontWeight: FontWeight.bold,
                color: _stateColor,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}


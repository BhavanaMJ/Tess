import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'mascot_widget.dart';

/// MascotSection integrates the animated breathing orb with real application states.
class MascotSection extends StatelessWidget {
  final MascotState state;
  final String statusText;

  const MascotSection({
    super.key,
    required this.state,
    required this.statusText,
  });

  Color get _accentColor {
    switch (state) {
      case MascotState.happy:
      case MascotState.speaking:
        return AppColors.success;
      case MascotState.thinking:
      case MascotState.planning:
        return AppColors.cyan;
      case MascotState.attention:
      case MascotState.intervening:
      case MascotState.error:
        return AppColors.danger;
      case MascotState.idle:
      case MascotState.listening:
        return AppColors.violet;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MascotWidget(
          state: state,
          size: 76.0,
        ),
        const SizedBox(height: 12.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accentColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _accentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                statusText.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: _accentColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


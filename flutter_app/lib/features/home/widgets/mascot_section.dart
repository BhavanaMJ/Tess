import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/mascot/tess_mascot.dart';
import 'mascot_widget.dart';

/// MascotSection presents the animated TESS companion with dynamic cognitive status
/// seamlessly integrated into both Light and Dark themes.
class MascotSection extends StatelessWidget {
  final MascotState state;
  final String statusText;

  const MascotSection({
    super.key,
    required this.state,
    required this.statusText,
  });

  Color get _statusColor {
    switch (state) {
      case MascotState.happy:
        return AppColors.success;
      case MascotState.thinking:
      case MascotState.planning:
        return AppColors.tessTeal;
      case MascotState.attention:
        return AppColors.warning;
      case MascotState.error:
        return AppColors.danger;
      case MascotState.idle:
      default:
        return AppColors.vibrantMint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TessMascot(
          state: state.toTessMascotState(),
          size: 80.0,
          showStatusBadge: false,
        ),
        const SizedBox(height: 10.0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _statusColor.withValues(alpha: isDark ? 0.16 : 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _statusColor.withValues(alpha: isDark ? 0.35 : 0.22),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _statusColor.withValues(alpha: 0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusText.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

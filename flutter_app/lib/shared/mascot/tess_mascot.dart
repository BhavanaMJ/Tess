import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'tess_mascot_controller.dart';
import 'tess_mascot_fallback.dart';
import 'tess_mascot_state.dart';

/// The Canonical TESS Mascot Companion Widget.
/// Implements the Approved TESS Expressive Companion Design Specification v1.0.
/// Renders the fluid, asymmetrical organic cloud silhouette and coordinates
/// the 9 expressive cognitive states.
class TessMascot extends StatelessWidget {
  final TessMascotState state;
  final TessMascotController? controller;
  final double size;
  final bool showStatusBadge;
  final bool animate;
  final VoidCallback? onTap;

  bool get showStatusPill => showStatusBadge;

  const TessMascot({
    super.key,
    this.state = TessMascotState.idle,
    this.controller,
    this.size = 76.0,
    bool showStatusBadge = false,
    bool? showStatusPill,
    this.animate = true,
    this.onTap,
  }) : showStatusBadge = showStatusPill ?? showStatusBadge;

  /// Factory constructor for a compact app bar or header indicator
  factory TessMascot.compact({
    Key? key,
    TessMascotState state = TessMascotState.idle,
    double size = 38.0,
    VoidCallback? onTap,
  }) {
    return TessMascot(
      key: key,
      state: state,
      size: size,
      showStatusBadge: false,
      onTap: onTap,
    );
  }

  /// Factory constructor for a full hero card section with cognitive status chip
  factory TessMascot.hero({
    Key? key,
    TessMascotState state = TessMascotState.idle,
    double size = 88.0,
    VoidCallback? onTap,
  }) {
    return TessMascot(
      key: key,
      state: state,
      size: size,
      showStatusBadge: true,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return AnimatedBuilder(
        animation: controller!,
        builder: (context, _) => _buildMascot(context, controller!.currentState),
      );
    }
    return _buildMascot(context, state);
  }

  Widget _buildMascot(BuildContext context, TessMascotState activeState) {
    final mascotWidget = Semantics(
      label: 'TESS Companion (${activeState.displayName})',
      child: TessMascotFallback(
        state: activeState,
        size: size,
        animate: animate,
      ),
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        mascotWidget,
        if (showStatusBadge) ...[
          const SizedBox(height: 8.0),
          _buildStatusPill(context, activeState),
        ],
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }

  Widget _buildStatusPill(BuildContext context, TessMascotState activeState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getStatusColor(activeState);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.25),
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
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            activeState.displayName.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TessMascotState activeState) {
    switch (activeState) {
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
        return AppColors.tessTeal;
    }
  }
}

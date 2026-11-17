import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'tess_card.dart';

/// Reusable Responsive Metric Card.
/// Demonstrates:
/// - LayoutBuilder for responsive adaptations based on parent container width
/// - Stack & Positioned for overlaying spatial badges
/// - Row, Column, Expanded, and Flexible layout mechanics
class ResponsiveMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const ResponsiveMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.accentColor = AppColors.violet,
  });

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder provides BoxConstraints of the immediate parent
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adapt padding and font sizes dynamically according to available width
        final isCompact = constraints.maxWidth < 160;

        return TessCard(
          padding: EdgeInsets.all(isCompact ? 10.0 : 14.0),
          borderColor: accentColor.withValues(alpha: 0.3),
          child: Stack(
            children: [
              // Background accent glow indicator using Positioned
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  icon,
                  size: isCompact ? 36 : 48,
                  color: accentColor.withValues(alpha: 0.06),
                ),
              ),

              // Foreground Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: isCompact ? 14 : 16, color: accentColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isCompact ? 9 : 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: isCompact ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}


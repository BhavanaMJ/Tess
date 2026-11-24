import 'package:flutter/material.dart';
import '../theme/wardrobe_theme.dart';

/// Clean header row for Wardrobe sections.
class WardrobeSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? badgeText;
  final VoidCallback? onAction;
  final String? actionLabel;

  const WardrobeSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.badgeText,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: WardrobeTheme.textPrimary,
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: WardrobeTheme.electricViolet.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          WardrobeTheme.electricViolet.withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    badgeText!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: WardrobeTheme.softViolet,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (onAction != null && actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: WardrobeTheme.electricCyan,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/wardrobe_theme.dart';

class RepeatedOutfitWarning extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const RepeatedOutfitWarning({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: WardrobeTheme.statusWarning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WardrobeTheme.statusWarning.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.history_edu_rounded,
            color: WardrobeTheme.statusWarning,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: WardrobeTheme.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(
                Icons.close_rounded,
                color: WardrobeTheme.textMuted,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}

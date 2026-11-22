import 'package:flutter/material.dart';
import '../../../../shared/widgets/tess_button.dart';
import '../../../../shared/widgets/tess_card.dart';
import '../theme/wardrobe_theme.dart';

/// Empty state widget for Wardrobe Overview and My Wardrobe.
class WardrobeEmptyState extends StatelessWidget {
  final VoidCallback? onImportInitial;
  final VoidCallback? onAddGarment;
  final bool isImporting;

  const WardrobeEmptyState({
    super.key,
    this.onImportInitial,
    this.onAddGarment,
    this.isImporting = false,
  });

  @override
  Widget build(BuildContext context) {
    return TessCard(
      backgroundColor: WardrobeTheme.spatialSurface,
      borderColor: WardrobeTheme.borderViolet,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WardrobeTheme.electricViolet.withValues(alpha: 0.12),
              border: Border.all(color: WardrobeTheme.borderViolet, width: 1.5),
            ),
            child: const Icon(
              Icons.checkroom_rounded,
              color: WardrobeTheme.electricViolet,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your Wardrobe is Ready to Populate',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: WardrobeTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Digitize garments, track laundry cycles, and unlock TESS AI daily outfit recommendations.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: WardrobeTheme.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          if (onImportInitial != null) ...[
            TessButton(
              label: 'Import Initial 18 Garments',
              icon: Icons.download_rounded,
              isLoading: isImporting,
              variant: TessButtonVariant.primary,
              onPressed: onImportInitial,
            ),
            const SizedBox(height: 10),
          ],
          if (onAddGarment != null)
            TessButton(
              label: 'Add New Garment',
              icon: Icons.add_photo_alternate_outlined,
              variant: TessButtonVariant.secondary,
              onPressed: onAddGarment,
            ),
        ],
      ),
    );
  }
}

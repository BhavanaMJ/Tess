import 'package:flutter/material.dart';
import '../theme/wardrobe_theme.dart';

/// Renders garment photograph on a clean studio white/neutral background
/// providing intentional, crisp contrast against the dark spatial UI.
class GarmentImagePlaceholder extends StatelessWidget {
  final String? imageUrl;
  final String category;
  final double width;
  final double height;
  final double borderRadius;

  const GarmentImagePlaceholder({
    super.key,
    this.imageUrl,
    required this.category,
    this.width = 72,
    this.height = 72,
    this.borderRadius = 12,
  });

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'tops':
        return Icons.checkroom_rounded;
      case 'bottoms':
        return Icons.dry_cleaning_rounded;
      case 'ethnic wear':
        return Icons.style_rounded;
      case 'dresses':
        return Icons.woman_rounded;
      case 'outerwear':
        return Icons.layers_rounded;
      case 'activewear':
        return Icons.fitness_center_rounded;
      case 'innerwear':
        return Icons.favorite_border_rounded;
      case 'sleepwear':
        return Icons.bedtime_rounded;
      case 'footwear':
        return Icons.roller_skating_rounded;
      case 'accessories':
        return Icons.watch_rounded;
      default:
        return Icons.checkroom_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: WardrobeTheme.studioBackground, // Clean white studio background
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageUrl != null && imageUrl!.startsWith('http')
            ? Image.network(
                imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _buildFallback(),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(category),
            color: const Color(0xFF475569), // Dark slate icon on white card
            size: width * 0.45,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
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

  String? _resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      final base = AppConfig.resolveDefaultBackendUrl().replaceAll(RegExp(r'/+$'), '');
      return '$base$trimmed';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveImageUrl(imageUrl);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: WardrobeTheme.studioBackground, // Clean white studio background
        borderRadius: BorderRadius.circular(borderRadius),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.0),
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
        child: resolved != null
            ? Image.network(
                resolved,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: WardrobeTheme.electricViolet,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => _buildFallback(),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    double iconSize = 48.0;
    if (width.isFinite && width > 0) {
      iconSize = width * 0.45;
    } else if (height.isFinite && height > 0) {
      iconSize = height * 0.35;
    }
    iconSize = iconSize.clamp(20.0, 96.0);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(category),
            color: const Color(0xFF475569), // Dark slate icon on white card
            size: iconSize,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../domain/entities/actual_wear_record.dart';
import '../theme/wardrobe_theme.dart';

class ActualOutfitCard extends StatelessWidget {
  final ActualWearRecord wear;

  const ActualOutfitCard({
    super.key,
    required this.wear,
  });

  @override
  Widget build(BuildContext context) {
    final outfit = wear.outfit;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WardrobeTheme.spatialSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WardrobeTheme.borderCyan),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: WardrobeTheme.electricCyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ACTUALLY WORN',
                  style: TextStyle(
                    color: WardrobeTheme.electricCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: WardrobeTheme.railBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.repeat_rounded, size: 10, color: WardrobeTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Worn ${wear.wearCount}x',
                      style: TextStyle(
                        color: WardrobeTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            wear.outfitName,
            style: TextStyle(
              color: WardrobeTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (wear.notes != null && wear.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              wear.notes!,
              style: TextStyle(
                color: WardrobeTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 10),
          // Constituent Garment chips
          if (outfit.items.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: outfit.items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: WardrobeTheme.railBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: WardrobeTheme.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: WardrobeTheme.electricCyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.name,
                        style: TextStyle(
                          color: WardrobeTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 8),
          Text(
            'Recorded: ${wear.actualWornDate}',
            style: TextStyle(
              color: WardrobeTheme.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

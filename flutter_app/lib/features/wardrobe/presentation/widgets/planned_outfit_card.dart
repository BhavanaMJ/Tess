import 'package:flutter/material.dart';
import '../../domain/entities/outfit_plan.dart';
import '../theme/wardrobe_theme.dart';

class PlannedOutfitCard extends StatelessWidget {
  final OutfitPlan plan;
  final VoidCallback onConfirmWorn;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PlannedOutfitCard({
    super.key,
    required this.plan,
    required this.onConfirmWorn,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final outfit = plan.outfit;
    final isAvailable = plan.isAvailable;
    final isWorn = plan.isWorn;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WardrobeTheme.spatialSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWorn ? WardrobeTheme.borderCyan : WardrobeTheme.borderViolet,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: WardrobeTheme.electricViolet.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PLANNED',
                  style: TextStyle(
                    color: WardrobeTheme.softViolet,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: WardrobeTheme.railBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  plan.occasion,
                  style: TextStyle(
                    color: WardrobeTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              if (onEdit != null)
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 16, color: WardrobeTheme.textMuted),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, size: 16, color: WardrobeTheme.textMuted),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            plan.outfitName,
            style: TextStyle(
              color: WardrobeTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (plan.notes != null && plan.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              plan.notes!,
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
                    border: Border.all(
                      color: item.isEligible ? WardrobeTheme.borderSubtle : WardrobeTheme.statusCritical.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: item.isEligible ? WardrobeTheme.statusSuccess : WardrobeTheme.statusCritical,
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
          const SizedBox(height: 14),
          // Readiness badge and Action button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? WardrobeTheme.statusSuccess.withOpacity(0.12)
                      : WardrobeTheme.statusCritical.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAvailable ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                      size: 12,
                      color: isAvailable ? WardrobeTheme.statusSuccess : WardrobeTheme.statusCritical,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAvailable ? 'Ready to wear' : 'Laundry conflicts',
                      style: TextStyle(
                        color: isAvailable ? WardrobeTheme.statusSuccess : WardrobeTheme.statusCritical,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (isWorn)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: WardrobeTheme.electricCyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_rounded, size: 14, color: WardrobeTheme.electricCyan),
                      const SizedBox(width: 4),
                      Text(
                        'Confirmed Worn',
                        style: TextStyle(
                          color: WardrobeTheme.electricCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: onConfirmWorn,
                  icon: const Icon(Icons.check_rounded, size: 14),
                  label: const Text('Confirm Worn', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WardrobeTheme.electricViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../../domain/entities/wishlist_summary.dart';
import '../theme/wardrobe_theme.dart';

class WishlistSummaryCard extends StatelessWidget {
  final WishlistSummary summary;

  const WishlistSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final currencySymbol = summary.primaryCurrency == 'INR' ? '₹' : summary.primaryCurrency;
    final estimatedAmount = summary.primaryEstimatedValue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            WardrobeTheme.spatialSurface,
            WardrobeTheme.electricViolet.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WardrobeTheme.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WISHLIST OVERVIEW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: WardrobeTheme.softViolet,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: WardrobeTheme.electricViolet.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${summary.totalItems} ITEMS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: WardrobeTheme.electricViolet,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$currencySymbol${estimatedAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: WardrobeTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'planned budget',
                style: TextStyle(
                  fontSize: 13,
                  color: WardrobeTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (summary.unpricedItemsCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${summary.unpricedItemsCount} item(s) without estimated price',
              style: TextStyle(
                fontSize: 11,
                color: WardrobeTheme.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Divider(color: WardrobeTheme.subtleBorder, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('High Priority', summary.highPriorityCount.toString(), WardrobeTheme.warningRose),
              _buildMiniStat('Shortlisted', summary.shortlistedCount.toString(), WardrobeTheme.electricCyan),
              _buildMiniStat('Purchased', summary.purchasedCount.toString(), WardrobeTheme.successEmerald),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: WardrobeTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

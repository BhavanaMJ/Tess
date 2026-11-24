import 'package:flutter/material.dart';
import '../../domain/entities/wardrobe_gap.dart';
import '../controllers/wishlist_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/wardrobe_gap_card.dart';
import 'wishlist_add_edit_screen.dart';

class WardrobeGapAnalysisScreen extends StatelessWidget {
  final WishlistController controller;

  const WardrobeGapAnalysisScreen({super.key, required this.controller});

  void _addFromGap(BuildContext context, WardrobeGap gap) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WishlistAddEditScreen(
          controller: controller,
        ),
      ),
    );
    if (result == true) {
      controller.loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gaps = controller.gaps;

    return Scaffold(
      backgroundColor: WardrobeTheme.voidBlack,
      appBar: AppBar(
        backgroundColor: WardrobeTheme.voidBlack,
        title: Text(
          'Wardrobe Gap Analysis',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: WardrobeTheme.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header info banner
          Container(
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
                  children: [
                    Icon(Icons.insights_rounded,
                        color: WardrobeTheme.electricViolet, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'EMPIRICAL WARDROBE GAPS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: WardrobeTheme.softViolet,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Before buying something new, understand whether your existing wardrobe already meets that need.',
                  style: TextStyle(
                    fontSize: 13,
                    color: WardrobeTheme.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (gaps.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: WardrobeTheme.spatialSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: WardrobeTheme.subtleBorder),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 40, color: WardrobeTheme.successEmerald),
                    const SizedBox(height: 12),
                    Text(
                      'No Major Wardrobe Gaps Detected',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: WardrobeTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your wardrobe has healthy category and color balance across your active pieces.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: WardrobeTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ...gaps.map((gap) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: WardrobeGapCard(
                  gap: gap,
                  onAddWishlistItem: () => _addFromGap(context, gap),
                ),
              );
            }),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

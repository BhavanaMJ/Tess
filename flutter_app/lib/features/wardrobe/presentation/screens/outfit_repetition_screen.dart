import 'package:flutter/material.dart';
import '../controllers/insights_controller.dart';
import '../theme/wardrobe_theme.dart';

class OutfitRepetitionScreen extends StatefulWidget {
  final InsightsController controller;

  const OutfitRepetitionScreen({
    super.key,
    required this.controller,
  });

  @override
  State<OutfitRepetitionScreen> createState() => _OutfitRepetitionScreenState();
}

class _OutfitRepetitionScreenState extends State<OutfitRepetitionScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadOutfitRepetition();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;
        final list = ctrl.outfitRepetition;

        return Scaffold(
          backgroundColor: WardrobeTheme.voidBg,
          appBar: AppBar(
            backgroundColor: WardrobeTheme.deepVoidBg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              color: WardrobeTheme.textPrimary,
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Outfit Repetition Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: WardrobeTheme.textPrimary,
              ),
            ),
          ),
          body: ctrl.isLoading && list.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(WardrobeTheme.softViolet),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: WardrobeTheme.spatialSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: WardrobeTheme.borderViolet.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: WardrobeTheme.softViolet.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.repeat_rounded,
                              color: WardrobeTheme.softViolet,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Recurring Combinations',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: WardrobeTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tracking look repeats helps maintain outfit variety across social settings.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: WardrobeTheme.textSecondary.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (list.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: WardrobeTheme.spatialSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: WardrobeTheme.border),
                        ),
                        child: const Center(
                          child: Text(
                            'No repeated outfits recorded yet. Log your looks in the Outfit Calendar to track repetition intervals.',
                            style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ...list.map((rep) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: WardrobeTheme.spatialSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: WardrobeTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      rep.outfitName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: WardrobeTheme.textPrimary,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: WardrobeTheme.softViolet.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${rep.wearCount} Wears',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: WardrobeTheme.softViolet,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  rep.garmentNames.join(' • '),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: WardrobeTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      rep.averageIntervalDays != null
                                          ? 'Avg interval: every ${rep.averageIntervalDays} days'
                                          : 'First repeated log',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: WardrobeTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      rep.occasion,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: WardrobeTheme.electricCyan,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
        );
      },
    );
  }
}

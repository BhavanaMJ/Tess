import 'package:flutter/material.dart';
import '../../domain/entities/cost_per_wear.dart';
import '../controllers/insights_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/cost_per_wear_card.dart';

class CostPerWearScreen extends StatefulWidget {
  final InsightsController controller;

  const CostPerWearScreen({
    super.key,
    required this.controller,
  });

  @override
  State<CostPerWearScreen> createState() => _CostPerWearScreenState();
}

class _CostPerWearScreenState extends State<CostPerWearScreen> {
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    widget.controller.loadCostPerWear();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;
        final summary = ctrl.costPerWearSummary;

        List<CostPerWearItem> filteredItems = [];
        if (summary != null) {
          switch (_selectedFilter) {
            case 'BEST':
              filteredItems = summary.bestValueGarments;
              break;
            case 'HIGH':
              filteredItems = summary.highestCostPerWearGarments;
              break;
            case 'UNPRICED':
              filteredItems = summary.items.where((it) => it.valueTier == ValueTier.missingPrice).toList();
              break;
            default:
              filteredItems = summary.items;
          }
        }

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
              'Cost-Per-Wear Analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: WardrobeTheme.textPrimary,
              ),
            ),
          ),
          body: ctrl.isLoading && summary == null
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(WardrobeTheme.electricCyan),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Overview Investment Card
                    if (summary != null) ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: WardrobeTheme.spatialSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: WardrobeTheme.borderCyan.withOpacity(0.3)),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              WardrobeTheme.spatialSurface,
                              WardrobeTheme.electricCyan.withOpacity(0.06),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL WARDROBE INVESTMENT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: WardrobeTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${summary.totalInvestment.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: WardrobeTheme.electricCyan,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMetricCol(
                                  label: 'Avg CPW',
                                  value: summary.averageCostPerWear != null
                                      ? '₹${summary.averageCostPerWear!.toStringAsFixed(0)}'
                                      : 'N/A',
                                  color: WardrobeTheme.statusSuccess,
                                ),
                                _buildMetricCol(
                                  label: 'Priced Items',
                                  value: '${summary.garmentsWithPriceCount}',
                                  color: WardrobeTheme.textPrimary,
                                ),
                                _buildMetricCol(
                                  label: 'Missing Price',
                                  value: '${summary.garmentsWithoutPriceCount}',
                                  color: WardrobeTheme.textMuted,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Filter Chips
                    Row(
                      children: [
                        _buildFilterChip('ALL', 'All Items'),
                        const SizedBox(width: 8),
                        _buildFilterChip('BEST', 'Best Value'),
                        const SizedBox(width: 8),
                        _buildFilterChip('HIGH', 'Highest CPW'),
                        const SizedBox(width: 8),
                        _buildFilterChip('UNPRICED', 'Unpriced'),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (filteredItems.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: WardrobeTheme.spatialSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: WardrobeTheme.border),
                        ),
                        child: const Center(
                          child: Text(
                            'No items match the selected filter',
                            style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ...filteredItems.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CostPerWearCard(item: item),
                        );
                      }),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? WardrobeTheme.electricCyan.withOpacity(0.18)
              : WardrobeTheme.spatialSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? WardrobeTheme.electricCyan : WardrobeTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? WardrobeTheme.electricCyan : WardrobeTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: WardrobeTheme.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}


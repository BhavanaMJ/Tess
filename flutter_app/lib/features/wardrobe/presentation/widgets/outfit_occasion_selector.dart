import 'package:flutter/material.dart';
import '../theme/wardrobe_theme.dart';

const List<String> kOutfitOccasions = [
  'Casual',
  'Office',
  'Formal',
  'Ethnic',
  'Party',
  'Wedding',
  'Travel',
  'Home wear',
  'Workout',
];

class OutfitOccasionSelector extends StatelessWidget {
  final String selectedOccasion;
  final ValueChanged<String> onSelected;
  final bool showAllOption;

  const OutfitOccasionSelector({
    super.key,
    required this.selectedOccasion,
    required this.onSelected,
    this.showAllOption = false,
  });

  @override
  Widget build(BuildContext context) {
    final occasions =
        showAllOption ? ['All', ...kOutfitOccasions] : kOutfitOccasions;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: occasions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, idx) {
          final occ = occasions[idx];
          final isSelected =
              occ.toLowerCase() == selectedOccasion.toLowerCase();
          return GestureDetector(
            onTap: () => onSelected(occ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? WardrobeTheme.electricViolet
                    : WardrobeTheme.elevatedSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? WardrobeTheme.softViolet
                      : WardrobeTheme.borderSubtle,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: WardrobeTheme.electricViolet
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  occ,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isSelected ? Colors.white : WardrobeTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

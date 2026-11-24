import 'package:flutter/material.dart';
import '../../domain/entities/laundry_status.dart';
import '../theme/wardrobe_theme.dart';
import 'garment_status_indicator.dart';

/// Modal bottom sheet allowing selection of any of the 5 confirmed laundry statuses
/// or clearing status to unassigned.
class LaundryStatusSelectorSheet extends StatelessWidget {
  final String garmentName;
  final LaundryStatus? currentStatus;
  final ValueChanged<LaundryStatus?> onSelected;

  const LaundryStatusSelectorSheet({
    super.key,
    required this.garmentName,
    required this.currentStatus,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Laundry Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: WardrobeTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        garmentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: WardrobeTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: WardrobeTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 5 confirmed statuses
            ...LaundryStatus.values.map((status) {
              final isSelected = currentStatus == status;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: GarmentStatusIndicator(status: status, compact: true),
                title: Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? WardrobeTheme.textPrimary
                        : WardrobeTheme.textSecondary,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded,
                        color: WardrobeTheme.electricViolet, size: 20)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onSelected(status);
                },
              );
            }),

            Divider(color: WardrobeTheme.borderSubtle, height: 24),

            // Reset to unassigned
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: WardrobeTheme.textMuted, width: 2),
                ),
              ),
              title: Text(
                'Status Not Assigned (Unset)',
                style: TextStyle(
                    fontSize: 13,
                    color: WardrobeTheme.textMuted,
                    fontWeight: FontWeight.w500),
              ),
              trailing: currentStatus == null
                  ? Icon(Icons.check_circle_rounded,
                      color: WardrobeTheme.textMuted, size: 20)
                  : null,
              onTap: () {
                Navigator.pop(context);
                onSelected(null);
              },
            ),
          ],
        ),
      ),
    );
  }
}

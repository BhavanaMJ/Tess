import 'package:flutter/material.dart';
import '../../domain/entities/laundry_status.dart';
import '../theme/wardrobe_theme.dart';

/// Tag indicator displaying the garment's laundry status.
class GarmentStatusIndicator extends StatelessWidget {
  final LaundryStatus? status;
  final bool compact;

  const GarmentStatusIndicator({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case LaundryStatus.clean:
        bg = WardrobeTheme.statusSuccess.withValues(alpha: 0.15);
        fg = WardrobeTheme.statusSuccess;
        label = compact ? 'CLEAN' : 'Clean & Ready';
        break;
      case LaundryStatus.worn:
        bg = WardrobeTheme.statusWarning.withValues(alpha: 0.15);
        fg = WardrobeTheme.statusWarning;
        label = compact ? 'WORN' : 'In Hamper';
        break;
      case LaundryStatus.washing:
        bg = WardrobeTheme.electricCyan.withValues(alpha: 0.15);
        fg = WardrobeTheme.electricCyan;
        label = compact ? 'WASH' : 'Washing';
        break;
      case LaundryStatus.drying:
        bg = WardrobeTheme.skyCyan.withValues(alpha: 0.15);
        fg = WardrobeTheme.skyCyan;
        label = compact ? 'DRY' : 'Drying';
        break;
      case LaundryStatus.stored:
        bg = WardrobeTheme.electricViolet.withValues(alpha: 0.15);
        fg = WardrobeTheme.softViolet;
        label = compact ? 'STORED' : 'Stored';
        break;
      case null:
        bg = WardrobeTheme.borderSubtle;
        fg = WardrobeTheme.textMuted;
        label = compact ? 'UNSET' : 'Status Unset';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.35), width: 1.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: fg,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}


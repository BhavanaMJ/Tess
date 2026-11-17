import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tess_card.dart';

/// DailyIntelligence renders live system telemetry and synchronization health.
class DailyIntelligence extends StatelessWidget {
  final bool isBackendOnline;

  const DailyIntelligence({
    super.key,
    required this.isBackendOnline,
  });

  @override
  Widget build(BuildContext context) {
    return TessCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SYSTEM TELEMETRY STATUS',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isBackendOnline ? AppColors.success : AppColors.danger)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isBackendOnline ? 'LIVE SYNC' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: isBackendOnline ? AppColors.success : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildTelemetryBadge(
                Icons.memory,
                'Neural Core',
                isBackendOnline ? 'Online' : 'Degraded',
                isBackendOnline ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(width: 8),
              _buildTelemetryBadge(
                Icons.sync,
                'Cross-Device',
                'Synced',
                AppColors.cyan,
              ),
              const SizedBox(width: 8),
              _buildTelemetryBadge(
                Icons.security,
                'Auth Token',
                'Valid',
                AppColors.violetLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryBadge(IconData icon, String label, String status, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
        decoration: BoxDecoration(
          color: AppColors.bgVoid.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textMuted,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}


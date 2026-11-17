import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tess_button.dart';
import '../../../shared/widgets/tess_card.dart';
import '../models/device_registration_model.dart';

/// DeviceStatusCard: Manages device registration, push token association, and notification preferences.
class DeviceStatusCard extends StatelessWidget {
  final DeviceRegistrationModel? registeredDevice;
  final bool isRegistering;
  final VoidCallback onRegister;

  const DeviceStatusCard({
    super.key,
    required this.registeredDevice,
    required this.isRegistering,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final isRegistered = registeredDevice != null;

    return TessCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.phonelink_setup_rounded, color: AppColors.cyan, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DEVICE NOTIFICATION IDENTITY',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isRegistered ? 'Device linked to neural session' : 'Device not registered with backend',
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isRegistered ? AppColors.success : AppColors.warning).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: (isRegistered ? AppColors.success : AppColors.warning).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  isRegistered ? 'REGISTERED' : 'UNLINKED',
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: isRegistered ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (isRegistered) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Device ID: ',
                        style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.textMuted),
                      ),
                      Expanded(
                        child: Text(
                          registeredDevice!.deviceId,
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: AppColors.cyan,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        'Platform: ',
                        style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.textMuted),
                      ),
                      Text(
                        registeredDevice!.platform.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      const Icon(Icons.notifications_active_rounded, size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      const Text(
                        'Notifications Ready',
                        style: TextStyle(fontSize: 10, color: AppColors.success),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            const Text(
              'Link this Android terminal to receive real-time proactive intervention alerts and schedule warnings.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],

          const SizedBox(height: 12),

          TessButton(
            label: isRegistering
                ? 'Registering Device...'
                : (isRegistered ? 'Refresh Device Token' : 'Register Device Terminal'),
            icon: Icons.sync_rounded,
            variant: isRegistered ? TessButtonVariant.secondary : TessButtonVariant.cyan,
            onPressed: isRegistering ? null : onRegister,
          ),
        ],
      ),
    );
  }
}

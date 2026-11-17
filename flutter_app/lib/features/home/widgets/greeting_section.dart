import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tess_button.dart';
import '../../../shared/widgets/tess_card.dart';
import 'mascot_section.dart';
import 'mascot_widget.dart';

/// GreetingSection displays commander persona, real email, and quick-action navigation.
class GreetingSection extends StatelessWidget {
  final String callsign;
  final String email;
  final MascotState mascotState;
  final String statusText;
  final Function(int) onNavigateTab;

  const GreetingSection({
    super.key,
    required this.callsign,
    required this.email,
    required this.mascotState,
    required this.statusText,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    return TessCard(
      borderColor: AppColors.violet.withValues(alpha: 0.35),
      child: Column(
        children: [
          MascotSection(
            state: mascotState,
            statusText: statusText,
          ),
          const SizedBox(height: 16.0),
          Text(
            'Commander $callsign',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            email,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.cyan,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8.0),
          const Text(
            'Personal Future Simulator & AI Operating System actively observing telemetry.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TessButton(
                label: 'Talk to TESS',
                icon: Icons.chat_bubble_outline,
                onPressed: () => onNavigateTab(1), // Switch to Chat tab
              ),
              const SizedBox(width: 10),
              TessButton(
                label: 'Futures Engine',
                icon: Icons.explore_outlined,
                variant: TessButtonVariant.cyan,
                onPressed: () => onNavigateTab(2), // Switch to Futures tab
              ),
            ],
          ),
        ],
      ),
    );
  }
}


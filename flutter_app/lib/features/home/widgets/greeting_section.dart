import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tess_button.dart';
import '../../../shared/widgets/tess_card.dart';
import 'mascot_section.dart';
import 'mascot_widget.dart';

/// Redesigned GreetingSection with Expressive TESS Companion,
/// personal greeting, and intuitive quick-action pills.
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

  String get _greetingText {
    final trimmed = callsign.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'commander') {
      return 'Welcome back';
    }
    if (trimmed.toLowerCase().startsWith('commander ')) {
      return 'Welcome back, ${trimmed.substring(10).trim()}';
    }
    return 'Welcome back, $trimmed';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return TessCard(
      elevated: true,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22.0),
      child: Column(
        children: [
          // 1. Approved Expressive TESS Companion
          MascotSection(
            state: mascotState,
            statusText: statusText,
          ),
          const SizedBox(height: 14.0),

          // 2. Personal Greeting (clean & natural, never duplicated)
          Text(
            _greetingText,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 4.0),
          const Text(
            'See Where Today Takes You.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.tessTeal,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            email,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 18.0),

          // 3. Quick Action Buttons
          Row(
            children: [
              Expanded(
                child: TessButton(
                  label: 'Talk to TESS',
                  icon: Icons.chat_bubble_outline_rounded,
                  variant: TessButtonVariant.primary,
                  height: 42,
                  onPressed: () => onNavigateTab(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TessButton(
                  label: 'Simulate Futures',
                  icon: Icons.explore_outlined,
                  variant: TessButtonVariant.secondary,
                  height: 42,
                  onPressed: () => onNavigateTab(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tess_card.dart';
import '../../../shared/widgets/tess_button.dart';
import '../../../shared/widgets/responsive_metric_card.dart';
import '../widgets/mascot_widget.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onNavigateTab;

  const HomeScreen({
    super.key,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'TESS',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
              ),
              child: const Text(
                'FLUTTER OS',
                style: TextStyle(
                  fontSize: 9,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: AppColors.cyan,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Section: Living Mascot & Command Greeting
            TessCard(
              borderColor: AppColors.violet.withOpacity(0.35),
              child: Column(
                children: [
                  const MascotWidget(
                    state: MascotState.idle,
                    size: 80.0,
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Welcome to TESS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  const Text(
                    'Your personal AI companion & future simulator is observing telemetry.',
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
                        onPressed: () => onNavigateTab(1), // Switch to Chat
                      ),
                      const SizedBox(width: 10),
                      TessButton(
                        label: 'Futures',
                        icon: Icons.explore_outlined,
                        variant: TessButtonVariant.cyan,
                        onPressed: () => onNavigateTab(2), // Switch to Futures
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16.0),

            // Daily Intelligence Telemetry Strip
            const Text(
              'DAILY INTELLIGENCE',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8.0),

            const Row(
              children: [
                Expanded(
                  child: ResponsiveMetricCard(
                    title: 'ACTIVE TASKS',
                    value: '5',
                    subtitle: 'Work packages',
                    icon: Icons.task_alt,
                    accentColor: AppColors.violet,
                  ),
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child: ResponsiveMetricCard(
                    title: 'CONVERGENCE',
                    value: '88%',
                    subtitle: 'Trajectory optimal',
                    icon: Icons.trending_up,
                    accentColor: AppColors.cyan,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16.0),

            // Future Trajectory Preview Card
            TessCard(
              borderColor: AppColors.cyan.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'FUTURE ENGINE TRAJECTORY',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: AppColors.cyan,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NEXT 24H',
                          style: TextStyle(
                            fontSize: 9,
                            fontFamily: 'monospace',
                            color: AppColors.cyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    'Momentum is balanced. 1 deadline requires attention by 18:00.',
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                  ),
                  const SizedBox(height: 12.0),
                  TessButton(
                    label: 'Explore Scenario Timeline →',
                    variant: TessButtonVariant.secondary,
                    onPressed: () => onNavigateTab(2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


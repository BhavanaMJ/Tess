import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tess_button.dart';
import '../../../shared/widgets/tess_card.dart';
import '../../agent/screens/agent_screen.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';
import '../widgets/daily_intelligence.dart';
import '../widgets/future_preview.dart';
import '../widgets/greeting_section.dart';
import '../widgets/mascot_widget.dart';
import '../widgets/productivity_overview.dart';

/// HomeScreen transforms into a real, functional TESS Operating System Dashboard
/// powered by live FastAPI backend endpoints and Supabase session state.
class HomeScreen extends StatefulWidget {
  final Function(int) onNavigateTab;
  final DashboardService? dashboardService;

  const HomeScreen({
    super.key,
    required this.onNavigateTab,
    this.dashboardService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final DashboardService _dashboardService;

  bool _isLoading = true;
  DashboardData? _dashboardData;
  String? _errorMessage;
  MascotState _mascotState = MascotState.thinking;

  @override
  void initState() {
    super.initState();
    _dashboardService = widget.dashboardService ?? DashboardService();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _mascotState = MascotState.thinking;
    });

    try {
      final data = await _dashboardService.fetchDashboardData();

      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;

          // Connect mascot animation state to real application telemetry
          if (data.hasUrgentAlerts) {
            _mascotState = MascotState.attention;
          } else if (data.summary.completedRecently > 0) {
            _mascotState = MascotState.happy;
          } else {
            _mascotState = MascotState.idle;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
          _mascotState = MascotState.attention;
        });
      }
    }
  }

  String get _mascotStatusText {
    if (_isLoading) return 'Synthesizing Telemetry...';
    if (_errorMessage != null) return 'Telemetry Interrupted';
    if (_dashboardData?.summary.hasOverdue == true) return 'Attention Required';
    if (_dashboardData?.predictions.any((p) => p.isRisk) == true) return 'Convergence Risk Detected';
    return 'Neural Core Nominal';
  }

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
                color: AppColors.cyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology_rounded, color: AppColors.cyan, size: 22),
            tooltip: 'Agent Action Core',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AgentScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.cyan, size: 20),
            tooltip: 'Refresh Telemetry',
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.violet,
        backgroundColor: AppColors.bgSurface,
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error Banner with Retry Action
              if (_errorMessage != null) ...[
                TessCard(
                  borderColor: AppColors.danger.withValues(alpha: 0.5),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.wifi_off_rounded, color: AppColors.danger, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TessButton(
                        label: 'Retry Synchronization',
                        icon: Icons.refresh,
                        variant: TessButtonVariant.cyan,
                        onPressed: _loadDashboardData,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
              ],

              // 1. Living Mascot Hero & Commander Greeting
              GreetingSection(
                callsign: _dashboardData?.callsign ?? 'Commander',
                email: _dashboardData?.userEmail ?? 'commander@tess.ai',
                mascotState: _mascotState,
                statusText: _mascotStatusText,
                onNavigateTab: widget.onNavigateTab,
              ),

              const SizedBox(height: 16.0),

              // 2. Real Productivity Overview (FastAPI GET /api/v1/productivity/summary)
              ProductivityOverview(
                summary: _dashboardData?.summary ?? const ProductivitySummaryModel(),
              ),

              const SizedBox(height: 16.0),

              // 3. Real Future Engine Preview (FastAPI GET /api/v1/future/predictions)
              FuturePreview(
                predictions: _dashboardData?.predictions ?? [],
                onExplore: () => widget.onNavigateTab(2), // Switch to Futures Tab
              ),

              const SizedBox(height: 16.0),

              // 4. System Telemetry & Cross-Device Sync State
              DailyIntelligence(
                isBackendOnline: _errorMessage == null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

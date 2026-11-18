import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../home/widgets/mascot_widget.dart';
import '../models/agent_plan_model.dart';
import '../services/agent_service.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/execution_history_view.dart';
import '../widgets/objective_composer.dart';
import '../widgets/plan_review_card.dart';

/// AgentScreen: Autonomous Agent Intelligence & Action Execution Command Center
class AgentScreen extends StatefulWidget {
  final AgentService? agentService;
  final String? initialObjective;

  const AgentScreen({
    super.key,
    this.agentService,
    this.initialObjective,
  });

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  late final AgentService _agentService;

  List<AgentPlanModel> _plans = [];
  AgentPlanModel? _activePlan;
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  int _selectedTab = 0; // 0: PLANNER, 1: HISTORY

  MascotState _mascotState = MascotState.idle;

  @override
  void initState() {
    super.initState();
    _agentService = widget.agentService ?? AgentService();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _mascotState = MascotState.thinking;
    });

    try {
      final plans = await _agentService.getPlans();
      if (!mounted) return;

      setState(() {
        _plans = plans;
        _isLoading = false;
        if (plans.isNotEmpty && _activePlan == null) {
          // Default active plan to most recent non-terminal or newest plan
          _activePlan = plans.firstWhere(
            (p) => !p.isTerminal,
            orElse: () => plans.first,
          );
        }
        _updateMascotState();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        _mascotState = MascotState.attention;
      });
    }
  }

  void _updateMascotState() {
    if (_activePlan == null) {
      _mascotState = MascotState.idle;
    } else if (_activePlan!.isExecuting) {
      _mascotState = MascotState.planning;
    } else if (_activePlan!.hasPendingConfirmation) {
      _mascotState = MascotState.attention;
    } else if (_activePlan!.isSuccess) {
      _mascotState = MascotState.happy;
    } else {
      _mascotState = MascotState.idle;
    }
  }

  /// Submits objective prompt to backend planner
  Future<void> _handleCreateObjective(String objective) async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _mascotState = MascotState.thinking;
    });

    try {
      final newPlan = await _agentService.createObjective(objective);
      if (!mounted) return;

      setState(() {
        _isGenerating = false;
        _activePlan = newPlan;
        _plans.insert(0, newPlan);
        _updateMascotState();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action plan formulated: ${newPlan.steps.length} sequential step(s) generated.'),
          backgroundColor: AppColors.tessTeal,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _mascotState = MascotState.attention;
      });
    }
  }

  /// Triggers explicit confirmation modal and approves pending steps
  Future<void> _handleConfirmPlan() async {
    if (_activePlan == null || _isSubmitting) return;

    await ConfirmationDialog.show(
      context,
      plan: _activePlan!,
      onApprove: () async {
        setState(() => _isSubmitting = true);
        try {
          await _agentService.confirmPlan(_activePlan!.id);
          final updated = await _agentService.getPlan(_activePlan!.id);
          if (!mounted) return;

          setState(() {
            _activePlan = updated;
            final idx = _plans.indexWhere((p) => p.id == updated.id);
            if (idx != -1) _plans[idx] = updated;
            _isSubmitting = false;
            _updateMascotState();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Operations approved: Execution lock released.'),
              backgroundColor: AppColors.accentSuccess,
            ),
          );
        } catch (e) {
          if (!mounted) return;
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Confirmation failed: $e'),
              backgroundColor: AppColors.accentDanger,
            ),
          );
        }
      },
      onReject: () async {
        await _handleCancelPlan();
      },
    );
  }

  /// Executes approved plan steps through backend ToolRouter
  Future<void> _handleExecutePlan() async {
    if (_activePlan == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _activePlan = _activePlan!.copyWith(status: 'EXECUTING');
      _mascotState = MascotState.planning;
    });

    try {
      final result = await _agentService.executePlan(_activePlan!.id);
      final refreshed = await _agentService.getPlan(_activePlan!.id);
      if (!mounted) return;

      setState(() {
        _activePlan = refreshed;
        final idx = _plans.indexWhere((p) => p.id == refreshed.id);
        if (idx != -1) _plans[idx] = refreshed;
        _isSubmitting = false;
        _updateMascotState();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.isSuccess
              ? 'Plan executed successfully. Operations verified.'
              : 'Execution finished with warnings.'),
          backgroundColor: result.isSuccess ? AppColors.accentSuccess : AppColors.accentWarning,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Refresh to see which step failed
      try {
        final failed = await _agentService.getPlan(_activePlan!.id);
        setState(() {
          _activePlan = failed;
          final idx = _plans.indexWhere((p) => p.id == failed.id);
          if (idx != -1) _plans[idx] = failed;
        });
      } catch (_) {}

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _mascotState = MascotState.attention;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Execution failed: $e'),
          backgroundColor: AppColors.accentDanger,
        ),
      );
    }
  }

  /// Cancels plan and invalidates pending confirmations
  Future<void> _handleCancelPlan() async {
    if (_activePlan == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await _agentService.cancelPlan(_activePlan!.id);
      final cancelled = await _agentService.getPlan(_activePlan!.id);
      if (!mounted) return;

      setState(() {
        _activePlan = cancelled;
        final idx = _plans.indexWhere((p) => p.id == cancelled.id);
        if (idx != -1) _plans[idx] = cancelled;
        _isSubmitting = false;
        _updateMascotState();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan cancelled: Security authorizations revoked.'),
          backgroundColor: AppColors.textMuted,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel plan: $e'),
          backgroundColor: AppColors.accentDanger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Agent Core',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.tessTeal.withOpacity(0.12),
                borderRadius: AppRadius.pill,
                border: Border.all(color: AppColors.tessTeal.withOpacity(0.35)),
              ),
              child: const Text(
                'ACTION LAYER',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.tessTeal,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.tessTeal, size: 20),
            tooltip: 'Refresh Plans',
            onPressed: _loadPlans,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.tessTeal,
        backgroundColor: cardBg,
        onRefresh: _loadPlans,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mascot Cognitive Reactive Telemetry Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    MascotWidget(
                      state: _mascotState,
                      size: 40,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _mascotStatusTitle,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.tessTeal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _mascotStatusDetail,
                            style: TextStyle(fontSize: 11, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Navigation Tabs (PLANNER / HISTORY)
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: AppRadius.pill,
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(0, 'ACTION PLANNER', Icons.terminal_rounded, isDark),
                    ),
                    Expanded(
                      child: _buildTabButton(1, 'AUDIT HISTORY (${_plans.length})', Icons.history_rounded, isDark),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Error Banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentDanger.withOpacity(0.1),
                    borderRadius: AppRadius.card,
                    border: Border.all(color: AppColors.accentDanger.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.accentDanger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: AppColors.accentDanger),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.accentDanger, size: 18),
                        onPressed: _loadPlans,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Content based on tab
              if (_selectedTab == 0) ...[
                // Objective Composer
                ObjectiveComposer(
                  initialPrompt: widget.initialObjective,
                  isGenerating: _isGenerating,
                  onSubmit: _handleCreateObjective,
                ),

                const SizedBox(height: AppSpacing.md),

                // Active Plan Card
                if (_activePlan != null) ...[
                  PlanReviewCard(
                    plan: _activePlan!,
                    isSubmitting: _isSubmitting,
                    onConfirm: _handleConfirmPlan,
                    onExecute: _handleExecutePlan,
                    onCancel: _handleCancelPlan,
                  ),
                ] else if (!_isLoading && !_isGenerating) ...[
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: AppRadius.card,
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.architecture_rounded, size: 40, color: textMuted),
                        const SizedBox(height: 10),
                        Text(
                          'No Active Plan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Compose an objective above to let TESS generate a deterministic action plan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                // Execution History Tab
                ExecutionHistoryView(
                  plans: _plans,
                  onSelectPlan: (selected) {
                    setState(() {
                      _activePlan = selected;
                      _selectedTab = 0; // Switch to planner tab to inspect
                      _updateMascotState();
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon, bool isDark) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: AppRadius.pill,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tessTeal.withOpacity(0.12) : Colors.transparent,
          borderRadius: AppRadius.pill,
          border: isSelected ? Border.all(color: AppColors.tessTeal.withOpacity(0.4)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.tessTeal : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.tessTeal : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _mascotStatusTitle {
    if (_isGenerating) return 'Synthesizing Tool Plan...';
    if (_isSubmitting) return 'Executing Operations...';
    if (_activePlan?.hasPendingConfirmation == true) return 'Authorization Required';
    if (_activePlan?.isSuccess == true) return 'Operations Verified';
    return 'Agent Core Ready';
  }

  String get _mascotStatusDetail {
    if (_isGenerating) return 'Evaluating tool capabilities and safety boundaries.';
    if (_isSubmitting) return 'Dispatching sequential tools through ToolRouter.';
    if (_activePlan?.hasPendingConfirmation == true) return 'User confirmation mandatory before high-risk execution.';
    if (_activePlan?.isSuccess == true) return 'Action completed. Replay prevention active.';
    return 'User-controlled agent standing by for directives.';
  }
}

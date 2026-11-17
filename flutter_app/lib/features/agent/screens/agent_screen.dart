import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
          backgroundColor: AppColors.cyan,
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
              backgroundColor: AppColors.success,
            ),
          );
        } catch (e) {
          if (!mounted) return;
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Confirmation failed: $e'),
              backgroundColor: AppColors.danger,
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
          backgroundColor: result.isSuccess ? AppColors.success : AppColors.warning,
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
          backgroundColor: AppColors.danger,
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
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'AGENT CORE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.violet.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.violet.withValues(alpha: 0.4)),
              ),
              child: const Text(
                'ACTION LAYER',
                style: TextStyle(
                  fontSize: 9,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: AppColors.violet,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.cyan, size: 20),
            tooltip: 'Refresh Plans',
            onPressed: _loadPlans,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.cyan,
        backgroundColor: AppColors.bgSurface,
        onRefresh: _loadPlans,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mascot Cognitive Reactive Telemetry Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    MascotWidget(
                      state: _mascotState,
                      size: 38,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _mascotStatusTitle,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: AppColors.cyan,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _mascotStatusDetail,
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Navigation Tabs (PLANNER / HISTORY)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(0, 'ACTION PLANNER', Icons.terminal_rounded),
                    ),
                    Expanded(
                      child: _buildTabButton(1, 'AUDIT HISTORY (${_plans.length})', Icons.history_rounded),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Error Banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 11, color: AppColors.danger),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.danger, size: 18),
                        onPressed: _loadPlans,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Content based on tab
              if (_selectedTab == 0) ...[
                // Objective Composer
                ObjectiveComposer(
                  initialPrompt: widget.initialObjective,
                  isGenerating: _isGenerating,
                  onSubmit: _handleCreateObjective,
                ),

                const SizedBox(height: 16),

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
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.bgSecondary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.architecture_rounded, size: 36, color: AppColors.textMuted),
                        SizedBox(height: 10),
                        Text(
                          'NO ACTIVE PLAN',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Compose an objective above to let TESS generate a deterministic action plan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.violet.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: AppColors.violet.withValues(alpha: 0.4)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.violet : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.violet : AppColors.textMuted,
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

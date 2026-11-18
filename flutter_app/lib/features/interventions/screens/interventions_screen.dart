import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../agent/screens/agent_screen.dart';
import '../../home/widgets/mascot_widget.dart';
import '../models/intervention_model.dart';
import '../services/intervention_service.dart';
import '../widgets/effectiveness_card.dart';
import '../widgets/intervention_card.dart';

/// InterventionsScreen: Proactive Intelligence & Decision Dashboard
class InterventionsScreen extends StatefulWidget {
  final InterventionService? interventionService;

  const InterventionsScreen({super.key, this.interventionService});

  @override
  State<InterventionsScreen> createState() => _InterventionsScreenState();
}

class _InterventionsScreenState extends State<InterventionsScreen> {
  late final InterventionService _interventionService;
  List<InterventionModel> _interventions = [];
  bool _isLoading = true;
  bool _isEvaluating = false;
  String? _errorMessage;
  int _selectedTab = 0; // 0: PENDING, 1: HISTORY, 2: EFFECTIVENESS

  final Set<String> _submittingIds = {};

  final List<String> _tabs = ['PENDING', 'HISTORY', 'EFFECTIVENESS'];

  @override
  void initState() {
    super.initState();
    _interventionService = widget.interventionService ?? InterventionService();
    _loadInterventions();
  }

  Future<void> _loadInterventions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _interventionService.getInterventions();
      if (!mounted) return;

      setState(() {
        _interventions = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Trigger proactive evaluation over latest predictions to spawn new interventions
  Future<void> _triggerEvaluation() async {
    setState(() => _isEvaluating = true);
    try {
      final spawned = await _interventionService.evaluateProactive();
      if (!mounted) return;

      setState(() {
        _isEvaluating = false;
        // Merge or replace with fresh list
        for (final item in spawned) {
          if (!_interventions.any((existing) => existing.id == item.id)) {
            _interventions.insert(0, item);
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(spawned.isNotEmpty
              ? 'Proactive Intelligence: ${spawned.length} actionable recommendation(s) generated.'
              : 'Proactive scan nominal: No new interventions required at this time.'),
          backgroundColor: AppColors.tessTeal,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isEvaluating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Proactive scan error: $e'),
          backgroundColor: AppColors.accentDanger,
        ),
      );
    }
  }

  /// Execute user decision ('ACTED', 'LATER', 'DISMISS') with duplicate submission protection
  Future<void> _handleUserDecision(InterventionModel intervention, String action) async {
    if (_submittingIds.contains(intervention.id)) return;

    setState(() => _submittingIds.add(intervention.id));

    try {
      await _interventionService.respondIntervention(
        interventionId: intervention.id,
        action: action,
      );

      if (!mounted) return;

      setState(() {
        _submittingIds.remove(intervention.id);

        String newStatus = action;
        DateTime? deferred;
        if (action == 'LATER') {
          newStatus = 'DEFERRED';
          deferred = DateTime.now().add(const Duration(hours: 4));
        } else if (action == 'DISMISS') {
          newStatus = 'DISMISSED';
        }

        final idx = _interventions.indexWhere((i) => i.id == intervention.id);
        if (idx != -1) {
          _interventions[idx] = _interventions[idx].copyWith(
            status: newStatus,
            deferredUntil: deferred,
          );
        }
      });

      String feedbackMessage;
      Color feedbackColor;
      if (action == 'ACTED') {
        feedbackMessage = 'Directive confirmed: Corrective action registered with TESS.';
        feedbackColor = AppColors.accentSuccess;
      } else if (action == 'LATER') {
        feedbackMessage = 'Recommendation deferred for 4 hours.';
        feedbackColor = AppColors.tessTeal;
      } else {
        feedbackMessage = 'Recommendation dismissed.';
        feedbackColor = AppColors.textMuted;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(feedbackMessage),
          backgroundColor: feedbackColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submittingIds.remove(intervention.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to record decision: $e'),
          backgroundColor: AppColors.accentDanger,
        ),
      );
    }
  }

  MascotState get _resolvedMascotState {
    if (_isEvaluating || _isLoading) return MascotState.thinking;
    if (_submittingIds.isNotEmpty) return MascotState.planning;
    final pending = _interventions.where((i) => i.isPending).toList();
    if (pending.any((i) => i.isCritical)) return MascotState.attention;
    if (pending.isNotEmpty) return MascotState.intervening;
    return MascotState.idle;
  }

  String get _mascotStatusText {
    switch (_resolvedMascotState) {
      case MascotState.thinking:
        return 'Evaluating sensors & convergence...';
      case MascotState.planning:
        return 'Registering action directive...';
      case MascotState.attention:
        return 'CRITICAL INTERVENTION ACTION REQUIRED';
      case MascotState.intervening:
        return 'Proactive recommendations pending';
      default:
        return 'NO INTERVENTIONS PENDING // TRAJECTORY NOMINAL';
    }
  }

  List<InterventionModel> get _pendingInterventions =>
      _interventions.where((i) => i.isPending).toList();

  List<InterventionModel> get _historyInterventions =>
      _interventions.where((i) => !i.isPending).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mascotState = _resolvedMascotState;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PROACTIVE INTELLIGENCE',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              'Autonomous Decision Engine // Corrective Levers',
              style: TextStyle(
                fontSize: 11.0,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology_rounded, color: AppColors.tessTeal),
            tooltip: 'Agent Action Core',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AgentScreen()),
              );
            },
          ),
          IconButton(
            icon: _isEvaluating
                ? const SizedBox(
                    width: 16.0,
                    height: 16.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.tessTeal),
                    ),
                  )
                : const Icon(Icons.radar_rounded, color: AppColors.tessTeal),
            tooltip: 'Run Proactive Scan',
            onPressed: _isEvaluating ? null : _triggerEvaluation,
          ),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            tooltip: 'Synchronize Interventions',
            onPressed: _loadInterventions,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInterventions,
        color: AppColors.tessTeal,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40.0),
          children: [
            // Mascot Telemetry Card
            _buildMascotHeader(mascotState, isDark),
            const SizedBox(height: AppSpacing.sm),

            // Tab bar
            _buildTabBar(isDark),
            const SizedBox(height: AppSpacing.md),

            if (_errorMessage != null) _buildErrorBanner(),

            // Tab Content
            _buildActiveContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildMascotHeader(MascotState state, bool isDark) {
    Color color = AppColors.tessTeal;
    if (state == MascotState.attention) color = AppColors.accentDanger;
    if (state == MascotState.intervening) color = AppColors.accentWarning;
    if (state == MascotState.planning) color = AppColors.tessTeal;
    if (state == MascotState.thinking) color = AppColors.vibrantMint;

    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8.0),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.card,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.03),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          MascotWidget(
            state: state,
            size: 42.0,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROACTIVE COMPANION TELEMETRY',
                  style: TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  _mascotStatusText,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    final chipBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          final idx = entry.key;
          final title = entry.value;
          final isSelected = _selectedTab == idx;

          String badgeText = '';
          if (idx == 0 && _pendingInterventions.isNotEmpty) {
            badgeText = ' (${_pendingInterventions.length})';
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text('$title$badgeText'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedTab = idx);
              },
              labelStyle: TextStyle(
                fontSize: 12.0,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              selectedColor: AppColors.tessTeal,
              backgroundColor: chipBg,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.pill,
                side: BorderSide(
                  color: isSelected ? AppColors.tessTeal : borderColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _delegateToAgent(InterventionModel item) {
    final objective = item.message.isNotEmpty
        ? item.message
        : (item.title.isNotEmpty ? item.title : 'Take corrective action on trajectory risk');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgentScreen(initialObjective: objective),
      ),
    );
  }

  Widget _buildActiveContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.tessTeal),
        ),
      );
    }

    if (_selectedTab == 2) {
      return EffectivenessCard(interventionService: _interventionService);
    }

    final list = _selectedTab == 0 ? _pendingInterventions : _historyInterventions;

    if (list.isEmpty) {
      return _buildEmptyState(_selectedTab == 0);
    }

    return Column(
      children: list.map((item) {
        return InterventionCard(
          intervention: item,
          isSubmitting: _submittingIds.contains(item.id),
          onAccept: () => _handleUserDecision(item, 'ACTED'),
          onPostpone: () => _handleUserDecision(item, 'LATER'),
          onDismiss: () => _handleUserDecision(item, 'DISMISS'),
          onDelegateToAgent: () => _delegateToAgent(item),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(bool isPendingTab) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              isPendingTab ? Icons.check_circle_outline_rounded : Icons.history_rounded,
              color: AppColors.tessTeal,
              size: 40.0,
            ),
            const SizedBox(height: 12.0),
            Text(
              isPendingTab ? 'No Pending Interventions' : 'No Intervention History',
              style: TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              isPendingTab
                  ? 'All convergence vectors are currently nominal. Tap "Run Proactive Scan" to check against new predictions.'
                  : 'Past accepted, deferred, or dismissed suggestions will be cataloged here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 13.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.accentDanger.withOpacity(0.1),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.accentDanger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.accentDanger, size: 18.0),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              _errorMessage ?? 'Intervention synchronization issue',
              style: const TextStyle(color: AppColors.accentDanger, fontSize: 12.0),
            ),
          ),
          TextButton(
            onPressed: _loadInterventions,
            child: const Text('Retry', style: TextStyle(color: AppColors.accentDanger)),
          ),
        ],
      ),
    );
  }
}

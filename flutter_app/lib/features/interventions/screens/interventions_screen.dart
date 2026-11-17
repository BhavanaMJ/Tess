import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
          backgroundColor: AppColors.cyan,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isEvaluating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Proactive scan error: $e'),
          backgroundColor: AppColors.danger,
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
        feedbackColor = AppColors.success;
      } else if (action == 'LATER') {
        feedbackMessage = 'Recommendation deferred for 4 hours.';
        feedbackColor = AppColors.violet;
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
          backgroundColor: AppColors.danger,
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
        return 'EVALUATING SENSORS & CONVERGENCE...';
      case MascotState.planning:
        return 'REGISTERING USER ACTION DIRECTIVE...';
      case MascotState.attention:
        return 'CRITICAL INTERVENTION ACTION REQUIRED';
      case MascotState.intervening:
        return 'PROACTIVE RECOMMENDATIONS PENDING';
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
    final mascotState = _resolvedMascotState;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PROACTIVE INTELLIGENCE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: AppColors.cyan,
              ),
            ),
            Text(
              'Autonomous Decision Engine // Corrective Levers',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.0,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isEvaluating
                ? const SizedBox(
                    width: 16.0,
                    height: 16.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
                    ),
                  )
                : const Icon(Icons.radar_rounded, color: AppColors.cyan),
            tooltip: 'Run Proactive Scan',
            onPressed: _isEvaluating ? null : _triggerEvaluation,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Synchronize Interventions',
            onPressed: _loadInterventions,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInterventions,
        color: AppColors.cyan,
        backgroundColor: AppColors.bgSecondary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40.0),
          children: [
            // Mascot Telemetry Card
            _buildMascotHeader(mascotState),
            const SizedBox(height: 12.0),

            // Tab bar
            _buildTabBar(),
            const SizedBox(height: 12.0),

            if (_errorMessage != null) _buildErrorBanner(),

            // Tab Content
            _buildActiveContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildMascotHeader(MascotState state) {
    Color color = AppColors.cyan;
    if (state == MascotState.attention) color = AppColors.danger;
    if (state == MascotState.intervening) color = AppColors.amber;
    if (state == MascotState.planning) color = AppColors.cyan;
    if (state == MascotState.thinking) color = AppColors.violetLight;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: color.withOpacity(0.35), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10.0,
          ),
        ],
      ),
      child: Row(
        children: [
          MascotWidget(
            state: state,
            size: 44.0,
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROACTIVE AGENT TELEMETRY',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  _mascotStatusText,
                  style: TextStyle(
                    color: color,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                fontFamily: 'monospace',
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              selectedColor: AppColors.violet,
              backgroundColor: AppColors.bgSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(
                  color: isSelected ? AppColors.violet : AppColors.border,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
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
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(bool isPendingTab) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              isPendingTab ? Icons.check_circle_outline_rounded : Icons.history_rounded,
              color: AppColors.cyan,
              size: 40.0,
            ),
            const SizedBox(height: 12.0),
            Text(
              isPendingTab ? 'No Pending Interventions' : 'No Intervention History',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              isPendingTab
                  ? 'All convergence vectors are currently nominal. Tap "Run Proactive Scan" to check against new predictions.'
                  : 'Past accepted, deferred, or dismissed suggestions will be cataloged here.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppColors.danger.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18.0),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              _errorMessage ?? 'Intervention synchronization issue',
              style: const TextStyle(color: AppColors.danger, fontSize: 11.5),
            ),
          ),
          TextButton(
            onPressed: _loadInterventions,
            child: const Text('Retry', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../shared/widgets/tess_button.dart';
import '../../../../shared/widgets/tess_card.dart';
import '../../data/repositories/wardrobe_repository_impl.dart';
import '../../domain/repositories/wardrobe_repository.dart';
import '../controllers/wardrobe_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/wardrobe_action_card.dart';
import '../widgets/wardrobe_empty_state.dart';
import '../widgets/wardrobe_section_header.dart';
import '../widgets/wardrobe_summary_card.dart';
import 'garment_form_screen.dart';
import 'smart_capture_screen.dart';
import 'wardrobe_inventory_screen.dart';
import '../../data/repositories/wardrobe_capture_repository_impl.dart';
import '../controllers/wardrobe_capture_controller.dart';
import '../../data/repositories/laundry_repository_impl.dart';
import '../controllers/laundry_controller.dart';
import 'laundry_dashboard_screen.dart';

/// WardrobeOverviewScreen: Foundational Home Dashboard for TESS Clothes Organizer.
/// Implements persistent inventory navigation, real-time telemetry summary, and module routing.
class WardrobeOverviewScreen extends StatefulWidget {
  final WardrobeRepository? repository;
  final AuthService? authService;

  const WardrobeOverviewScreen({
    super.key,
    this.repository,
    this.authService,
  });

  @override
  State<WardrobeOverviewScreen> createState() => _WardrobeOverviewScreenState();
}

class _WardrobeOverviewScreenState extends State<WardrobeOverviewScreen> {
  late final WardrobeRepository _repository;
  late final AuthService _authService;
  late final WardrobeController _controller;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _repository = widget.repository ?? WardrobeRepositoryImpl(authService: _authService);
    _controller = WardrobeController(repository: _repository);
    _controller.loadInitialData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToInventory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WardrobeInventoryScreen(
          controller: _controller,
          authService: _authService,
        ),
      ),
    );
  }

  void _navigateToAddGarment() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GarmentFormScreen(
          controller: _controller,
          userId: _authService.currentUser?.id ?? 'tess_user',
        ),
      ),
    );
  }

  void _navigateToSmartCapture() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SmartCaptureScreen(
          controller: WardrobeCaptureController(
            repository: WardrobeCaptureRepositoryImpl(),
          ),
        ),
      ),
    ).then((_) {
      _controller.loadInitialData();
    });
  }

  void _navigateToLaundry() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LaundryDashboardScreen(
          controller: LaundryController(
            repository: LaundryRepositoryImpl(),
          ),
        ),
      ),
    ).then((_) {
      _controller.loadInitialData();
    });
  }

  void _showAddClothesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: WardrobeTheme.elevatedSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Clothes to Wardrobe',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: WardrobeTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.auto_awesome_rounded, color: WardrobeTheme.electricViolet),
                  title: const Text('Smart Capture (Camera & AI)', style: TextStyle(color: WardrobeTheme.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Detect multiple garments, studio cutout & auto-attributes', style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: WardrobeTheme.electricViolet.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('AI ACTIVE', style: TextStyle(fontSize: 10, color: WardrobeTheme.softViolet, fontWeight: FontWeight.w700)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _navigateToSmartCapture();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.edit_note_rounded, color: WardrobeTheme.electricCyan),
                  title: const Text('Add Garment Manually', style: TextStyle(color: WardrobeTheme.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Enter garment attributes, color, category and specs', style: TextStyle(color: WardrobeTheme.textMuted, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: WardrobeTheme.textMuted),
                  onTap: () {
                    Navigator.pop(ctx);
                    _navigateToAddGarment();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showComingSoonSnackbar(String moduleName, String phase) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: WardrobeTheme.elevatedSurface,
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: WardrobeTheme.softViolet, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$moduleName will be activated in $phase.',
                style: const TextStyle(color: WardrobeTheme.textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.id ?? 'tess_user';

    return Scaffold(
      backgroundColor: WardrobeTheme.voidBg,
      appBar: AppBar(
        backgroundColor: WardrobeTheme.voidBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WardrobeTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            const Text(
              'Wardrobe Intelligence',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: WardrobeTheme.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: WardrobeTheme.electricViolet.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: WardrobeTheme.electricViolet.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
              child: const Text(
                'PHASE 4',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: WardrobeTheme.softViolet,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: WardrobeTheme.textSecondary, size: 20),
            tooltip: 'Refresh Wardrobe',
            onPressed: () => _controller.loadInitialData(),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading && _controller.garments.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: WardrobeTheme.electricViolet),
            );
          }

          return RefreshIndicator(
            color: WardrobeTheme.electricViolet,
            backgroundColor: WardrobeTheme.spatialSurface,
            onRefresh: _controller.loadInitialData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Contextual Introduction Banner
                  TessCard(
                    backgroundColor: WardrobeTheme.spatialSurface,
                    borderColor: WardrobeTheme.borderViolet,
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: WardrobeTheme.electricViolet.withValues(alpha: 0.15),
                            border: Border.all(color: WardrobeTheme.borderViolet, width: 1.0),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: WardrobeTheme.softViolet,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Personal Clothes Organizer',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: WardrobeTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Catalogued garments with clean studio backgrounds, lifecycle tracking & AI styling.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: WardrobeTheme.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Telemetry Summary Area
                  if (_controller.garments.isNotEmpty) ...[
                    WardrobeSummaryCard(
                      totalCount: _controller.totalGarmentsCount,
                      cleanCount: _controller.cleanCount,
                      inLaundryCount: _controller.inLaundryCount,
                      unassignedCount: _controller.unassignedCount,
                      onExplore: _navigateToInventory,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 3. Primary Add Clothes Action
                  TessButton(
                    label: 'Smart Capture / Add Clothes',
                    icon: Icons.add_circle_outline_rounded,
                    variant: TessButtonVariant.primary,
                    onPressed: _showAddClothesSheet,
                  ),

                  const SizedBox(height: 20),

                  // 4. Wardrobe Core Modules
                  const WardrobeSectionHeader(
                    title: 'CORE MODULES',
                    badgeText: '8 MODULES',
                  ),

                  const SizedBox(height: 8),

                  WardrobeActionCard(
                    icon: Icons.checkroom_rounded,
                    title: 'My Wardrobe',
                    subtitle: 'Browse, filter & search your digitized garment catalog',
                    badge: _controller.garments.isNotEmpty
                        ? '${_controller.garments.length} ITEMS'
                        : 'READY',
                    badgeColor: WardrobeTheme.electricCyan,
                    isFeatured: true,
                    onTap: _navigateToInventory,
                  ),

                  const SizedBox(height: 10),

                  WardrobeActionCard(
                    icon: Icons.style_rounded,
                    title: 'Outfit Studio',
                    subtitle: 'Canvas for creating combinations & daily lookbooks',
                    badge: 'PHASE 5',
                    badgeColor: WardrobeTheme.textMuted,
                    onTap: () => _showComingSoonSnackbar('Outfit Studio', 'Phase 5'),
                  ),

                  const SizedBox(height: 10),

                  WardrobeActionCard(
                    icon: Icons.local_laundry_service_outlined,
                    title: 'Laundry Manager',
                    subtitle: '5-status garment lifecycle, hampers & wash cycles',
                    badge: 'ACTIVE',
                    badgeColor: WardrobeTheme.electricCyan,
                    isFeatured: true,
                    onTap: _navigateToLaundry,
                  ),

                  const SizedBox(height: 10),

                  WardrobeActionCard(
                    icon: Icons.calendar_month_outlined,
                    title: 'Outfit Calendar',
                    subtitle: 'Plan upcoming outfits and log wear history',
                    badge: 'PHASE 6',
                    badgeColor: WardrobeTheme.textMuted,
                    onTap: () => _showComingSoonSnackbar('Outfit Calendar', 'Phase 6'),
                  ),

                  const SizedBox(height: 10),

                  WardrobeActionCard(
                    icon: Icons.insights_rounded,
                    title: 'Wardrobe Insights',
                    subtitle: 'Cost-per-wear analytics & category balance',
                    badge: 'PHASE 7',
                    badgeColor: WardrobeTheme.textMuted,
                    onTap: () => _showComingSoonSnackbar('Wardrobe Insights', 'Phase 7'),
                  ),

                  const SizedBox(height: 20),

                  // 5. Empty State / Initial Migration Card
                  if (_controller.garments.isEmpty) ...[
                    WardrobeEmptyState(
                      isImporting: _controller.isLoading,
                      onImportInitial: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final count = await _controller.importInitialInventory(userId);
                        if (mounted && count > 0) {
                          messenger.showSnackBar(
                            SnackBar(
                              backgroundColor: WardrobeTheme.elevatedSurface,
                              content: Text('Imported $count initial garments successfully!'),
                            ),
                          );
                        }
                      },
                      onAddGarment: _navigateToAddGarment,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

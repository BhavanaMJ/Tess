import 'package:flutter/material.dart';
import '../../domain/repositories/wardrobe_import_repository.dart';
import '../../data/repositories/wardrobe_import_repository_impl.dart';
import '../controllers/garment_import_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/import_stage1_prepare.dart';
import '../widgets/import_stage2_catalogue.dart';
import '../widgets/import_stage3_json.dart';
import '../widgets/import_stage4_review.dart';

class GarmentImportWizardScreen extends StatefulWidget {
  final String userId;
  final WardrobeImportRepository? repository;

  const GarmentImportWizardScreen({
    super.key,
    required this.userId,
    this.repository,
  });

  @override
  State<GarmentImportWizardScreen> createState() => _GarmentImportWizardScreenState();
}

class _GarmentImportWizardScreenState extends State<GarmentImportWizardScreen> {
  late GarmentImportController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GarmentImportController(
      repository: widget.repository ?? WardrobeImportRepositoryImpl(),
      userId: widget.userId,
    );

    // Attempt to restore local draft
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final restored = await _controller.loadDraftIfExists();
      if (restored && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: WardrobeTheme.elevatedSurface,
            content: Text(
              'Restored your saved import draft.',
              style: TextStyle(color: WardrobeTheme.textPrimary, fontSize: 12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleNext() {
    final step = _controller.currentStep;

    if (step == 0) {
      _controller.nextStep();
    } else if (step == 1) {
      if (!_controller.hasCatalogueImage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: WardrobeTheme.statusCritical,
            content: const Text(
              'Please upload a catalogue image before continuing.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
        return;
      }
      _controller.nextStep();
    } else if (step == 2) {
      if (!_controller.isMetadataValid) {
        _controller.validateMetadata().then((valid) {
          if (valid) {
            _controller.nextStep();
          }
        });
        return;
      }
      _controller.nextStep();
    }
  }

  Widget _buildStepIndicatorItem(int stepIndex, String title) {
    final current = _controller.currentStep;
    final isDone = current > stepIndex;
    final isActive = current == stepIndex;

    Color bg;
    Color fg;

    if (isDone) {
      bg = WardrobeTheme.statusSuccess;
      fg = Colors.white;
    } else if (isActive) {
      bg = WardrobeTheme.electricViolet;
      fg = Colors.white;
    } else {
      bg = WardrobeTheme.spatialSurface;
      fg = WardrobeTheme.textMuted;
    }

    return Expanded(
      child: InkWell(
        onTap: () {
          // Allow navigating backward or to validated steps
          if (stepIndex <= current || (stepIndex == 2 && _controller.hasCatalogueImage)) {
            _controller.goToStep(stepIndex);
          }
        },
        child: Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? WardrobeTheme.electricCyan : WardrobeTheme.borderSubtle,
                  width: isActive ? 1.5 : 1.0,
                ),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? WardrobeTheme.textPrimary : WardrobeTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: WardrobeTheme.spatialSurface,
        border: Border(bottom: BorderSide(color: WardrobeTheme.borderSubtle)),
      ),
      child: Row(
        children: [
          _buildStepIndicatorItem(0, '1. Prepare'),
          Container(width: 16, height: 1, color: WardrobeTheme.borderSubtle),
          _buildStepIndicatorItem(1, '2. Studio'),
          Container(width: 16, height: 1, color: WardrobeTheme.borderSubtle),
          _buildStepIndicatorItem(2, '3. JSON'),
          Container(width: 16, height: 1, color: WardrobeTheme.borderSubtle),
          _buildStepIndicatorItem(3, '4. Review'),
        ],
      ),
    );
  }

  Widget _buildCurrentStageView() {
    switch (_controller.currentStep) {
      case 0:
        return ImportStage1Prepare(controller: _controller);
      case 1:
        return ImportStage2Catalogue(controller: _controller);
      case 2:
        return ImportStage3Json(controller: _controller);
      case 3:
      default:
        return ImportStage4Review(
          controller: _controller,
          onRegistered: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: WardrobeTheme.elevatedSurface,
                content: Text(
                  'Garment ${_controller.registeredGarment?.id ?? ""} registered successfully in My Wardrobe!',
                  style: TextStyle(color: WardrobeTheme.textPrimary, fontWeight: FontWeight.w600),
                ),
              ),
            );
            Navigator.of(context).pop(true);
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WardrobeTheme.voidBg,
      appBar: AppBar(
        backgroundColor: WardrobeTheme.voidBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: WardrobeTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Catalogue & Metadata Import',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: WardrobeTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'ChatGPT-Assisted Import Workflow',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: WardrobeTheme.electricCyan,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: WardrobeTheme.textMuted, size: 20),
            tooltip: 'Clear Draft',
            onPressed: () {
              _controller.clearAll();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: WardrobeTheme.elevatedSurface,
                  content: Text('Import draft cleared.', style: TextStyle(color: WardrobeTheme.textPrimary)),
                ),
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Column(
            children: [
              _buildStepIndicator(),
              Expanded(child: _buildCurrentStageView()),
              // Bottom Stepping Controls (only on Steps 0, 1, 2; Step 3 has register button)
              if (_controller.currentStep < 3)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: WardrobeTheme.elevatedSurface,
                    border: Border(top: BorderSide(color: WardrobeTheme.borderSubtle)),
                  ),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_controller.currentStep > 0)
                          OutlinedButton.icon(
                            onPressed: () => _controller.previousStep(),
                            icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                            label: const Text('Back'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: WardrobeTheme.textSecondary,
                              side: BorderSide(color: WardrobeTheme.border),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        ElevatedButton.icon(
                          onPressed: _handleNext,
                          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                          label: Text(
                            _controller.currentStep == 2 ? 'Review Garment' : 'Continue',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WardrobeTheme.electricViolet,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

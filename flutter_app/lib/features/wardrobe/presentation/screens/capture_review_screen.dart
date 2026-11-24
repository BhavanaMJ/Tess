import 'package:flutter/material.dart';
import '../../domain/entities/garment_candidate.dart';
import '../controllers/wardrobe_capture_controller.dart';
import '../theme/wardrobe_theme.dart';
import '../widgets/garment_attribute_editor.dart';
import '../widgets/garment_candidate_card.dart';

/// Screen displaying detected garment candidates for independent user review, editing, and batch approval.
class CaptureReviewScreen extends StatefulWidget {
  final WardrobeCaptureController controller;

  const CaptureReviewScreen({
    super.key,
    required this.controller,
  });

  @override
  State<CaptureReviewScreen> createState() => _CaptureReviewScreenState();
}

class _CaptureReviewScreenState extends State<CaptureReviewScreen> {
  void _openAttributeEditor(GarmentCandidate candidate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WardrobeTheme.elevatedSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return GarmentAttributeEditor(
          candidate: candidate,
          onSave: (updated) {
            widget.controller.updateCandidate(updated);
          },
        );
      },
    );
  }

  Future<void> _handleConfirm() async {
    final res = await widget.controller.confirmSelectedGarments();
    if (!mounted) return;

    if (res != null && res['success'] == true) {
      final count = res['registered_count'] ?? widget.controller.includedCount;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: WardrobeTheme.elevatedSurface,
          content: Text(
            'Successfully registered $count garments to My Wardrobe!',
            style: TextStyle(
                color: WardrobeTheme.textPrimary, fontWeight: FontWeight.w600),
          ),
        ),
      );
      // Return back to wardrobe overview / inventory
      Navigator.of(context).popUntil((route) => route.isFirst);
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
        title: Text(
          'Review Detected Clothes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: WardrobeTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final candidates = widget.controller.candidates;
          final total = widget.controller.totalDetectedCount;
          final included = widget.controller.includedCount;
          final isConfirming = widget.controller.isConfirming;
          final error = widget.controller.errorMessage;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Telemetry Header Bar
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: WardrobeTheme.spatialSurface,
                  border: Border(
                      bottom: BorderSide(color: WardrobeTheme.borderSubtle)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: WardrobeTheme.electricViolet
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$total DETECTED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: WardrobeTheme.softViolet,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$included selected for wardrobe',
                          style: TextStyle(
                              fontSize: 13, color: WardrobeTheme.textSecondary),
                        ),
                      ],
                    ),
                    if (total > 0 && included < total)
                      TextButton(
                        onPressed: () {
                          for (final c in candidates) {
                            if (!c.isIncluded) {
                              widget.controller.toggleCandidateInclusion(c.id);
                            }
                          }
                        },
                        child: Text(
                          'Select All',
                          style: TextStyle(
                              color: WardrobeTheme.electricCyan, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),

              if (error != null) ...[
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: WardrobeTheme.statusCritical.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: WardrobeTheme.statusCritical
                            .withValues(alpha: 0.3)),
                  ),
                  child: Text(error,
                      style: TextStyle(
                          fontSize: 12, color: WardrobeTheme.statusCritical)),
                ),
              ],

              // Candidate List
              Expanded(
                child: candidates.isEmpty
                    ? Center(
                        child: Text(
                          'No garment candidates available.',
                          style: TextStyle(color: WardrobeTheme.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: candidates.length,
                        itemBuilder: (ctx, i) {
                          final cand = candidates[i];
                          return GarmentCandidateCard(
                            candidate: cand,
                            onToggleInclude: () => widget.controller
                                .toggleCandidateInclusion(cand.id),
                            onEdit: () => _openAttributeEditor(cand),
                          );
                        },
                      ),
              ),

              // Bottom Confirmation Action Bar
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: WardrobeTheme.elevatedSurface,
                  border: Border(
                      top: BorderSide(color: WardrobeTheme.borderSubtle)),
                ),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed:
                        isConfirming || included == 0 ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WardrobeTheme.electricViolet,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          WardrobeTheme.electricViolet.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isConfirming
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Register $included ${included == 1 ? "Garment" : "Garments"} in Wardrobe',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
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

import 'package:flutter/material.dart';
import '../../domain/entities/garment_candidate.dart';
import '../theme/wardrobe_theme.dart';
import 'garment_image_placeholder.dart';

/// Card widget presenting an individual detected garment candidate during Smart Capture review.
/// Includes studio catalogue photo, confidence tags, uncertainty notes, and include/exclude control.
class GarmentCandidateCard extends StatelessWidget {
  final GarmentCandidate candidate;
  final VoidCallback onToggleInclude;
  final VoidCallback onEdit;
  final String? qualityState;

  const GarmentCandidateCard({
    super.key,
    required this.candidate,
    required this.onToggleInclude,
    required this.onEdit,
    this.qualityState,
  });

  Widget _buildQualityBadge(String? state) {
    if (state == null) return const SizedBox.shrink();

    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (state.toUpperCase()) {
      case 'FULL_AI_PROCESSING':
        bg = WardrobeTheme.electricViolet.withValues(alpha: 0.2);
        fg = WardrobeTheme.softViolet;
        label = 'Multimodal AI';
        icon = Icons.auto_awesome;
        break;
      case 'LOCAL_NEURAL_PROCESSING':
        bg = WardrobeTheme.electricCyan.withValues(alpha: 0.15);
        fg = WardrobeTheme.electricCyan;
        label = 'Neural Matting & CIELAB';
        icon = Icons.memory;
        break;
      case 'LIMITED_PROCESSING':
        bg = WardrobeTheme.statusWarning.withValues(alpha: 0.15);
        fg = WardrobeTheme.statusWarning;
        label = 'Geometric & Color Analysis';
        icon = Icons.tune;
        break;
      case 'NEEDS_MANUAL_REVIEW':
        bg = WardrobeTheme.statusWarning.withValues(alpha: 0.2);
        fg = WardrobeTheme.statusWarning;
        label = 'Needs Review';
        icon = Icons.warning_amber_rounded;
        break;
      default:
        bg = WardrobeTheme.statusCritical.withValues(alpha: 0.15);
        fg = WardrobeTheme.statusCritical;
        label = 'Review Required';
        icon = Icons.info_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(right: 6, bottom: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(String label, String? confidence) {
    if (confidence == null) return const SizedBox.shrink();

    Color bg;
    Color fg;
    String text;

    switch (confidence.toUpperCase()) {
      case 'HIGH':
        bg = WardrobeTheme.statusSuccess.withValues(alpha: 0.15);
        fg = WardrobeTheme.statusSuccess;
        text = '$label: High';
        break;
      case 'MEDIUM':
        bg = WardrobeTheme.statusWarning.withValues(alpha: 0.15);
        fg = WardrobeTheme.statusWarning;
        text = '$label: Medium';
        break;
      default:
        bg = WardrobeTheme.statusCritical.withValues(alpha: 0.15);
        fg = WardrobeTheme.statusCritical;
        text = '$label: Uncertain';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(right: 6, bottom: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIncluded = candidate.isIncluded;

    return Opacity(
      opacity: isIncluded ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: WardrobeTheme.spatialSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isIncluded
                ? WardrobeTheme.borderViolet
                : WardrobeTheme.borderSubtle,
            width: isIncluded ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Studio Photography Presentation
            Container(
              height: 200,
              decoration: const BoxDecoration(
                color: WardrobeTheme.studioBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GarmentImagePlaceholder(
                    imageUrl: candidate.displayImage,
                    category: candidate.mainCategory,
                    width: double.infinity,
                    height: 200,
                  ),
                  // Category tag
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: WardrobeTheme.spatialSurface
                            .withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: WardrobeTheme.border),
                      ),
                      child: Text(
                        candidate.mainCategory,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: WardrobeTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  // Include / Exclude Toggle switch
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: WardrobeTheme.spatialSurface
                            .withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              isIncluded ? 'Included' : 'Excluded',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isIncluded
                                    ? WardrobeTheme.statusSuccess
                                    : WardrobeTheme.textMuted,
                              ),
                            ),
                          ),
                          Switch(
                            value: isIncluded,
                            activeColor: WardrobeTheme.electricViolet,
                            onChanged: (_) => onToggleInclude(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Garment Attributes & Details
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          candidate.suggestedName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: WardrobeTheme.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_note_rounded,
                            color: WardrobeTheme.electricCyan, size: 22),
                        tooltip: 'Edit Attributes',
                        onPressed: onEdit,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Key attributes line
                  Text(
                    '${candidate.primaryColor} • ${candidate.pattern ?? "Solid"}${candidate.sleeveLength != null ? " • ${candidate.sleeveLength}" : ""}${candidate.fabricMaterial != null ? " • ${candidate.fabricMaterial}" : ""}',
                    style: TextStyle(
                        fontSize: 12, color: WardrobeTheme.textSecondary),
                  ),

                  const SizedBox(height: 10),

                  // Confidence badges
                  Wrap(
                    children: [
                      if (qualityState != null) _buildQualityBadge(qualityState),
                      _buildConfidenceBadge(
                          'Category', candidate.confidenceScores['category']),
                      _buildConfidenceBadge(
                          'Color', candidate.confidenceScores['primary_color']),
                      _buildConfidenceBadge(
                          'Pattern', candidate.confidenceScores['pattern']),
                      if (candidate.sleeveLength != null)
                        _buildConfidenceBadge('Sleeves',
                            candidate.confidenceScores['sleeve_length']),
                      if (candidate.fabricMaterial != null)
                        _buildConfidenceBadge('Fabric',
                            candidate.confidenceScores['fabric_material']),
                    ],
                  ),

                  if (candidate.uncertaintyNotes != null &&
                      candidate.uncertaintyNotes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            WardrobeTheme.statusWarning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: WardrobeTheme.statusWarning
                                .withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: WardrobeTheme.statusWarning, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              candidate.uncertaintyNotes!,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: WardrobeTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onEdit,
                      icon: Icon(Icons.tune_rounded,
                          size: 14, color: WardrobeTheme.electricCyan),
                      label: Text(
                        'Refine Details',
                        style: TextStyle(
                            color: WardrobeTheme.electricCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
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

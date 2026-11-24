import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../controllers/wardrobe_capture_controller.dart';
import '../theme/wardrobe_theme.dart';

/// Developer Diagnostic Workspace for Smart Capture.
/// Exposes 4-stage visual pipeline (original photo, binary segmentation mask,
/// transparent cutout, and studio catalogue card) alongside VLM telemetry and attributes.
class CaptureDiagnosticScreen extends StatefulWidget {
  final WardrobeCaptureController controller;
  final String? jobId;

  const CaptureDiagnosticScreen({
    super.key,
    required this.controller,
    this.jobId,
  });

  @override
  State<CaptureDiagnosticScreen> createState() => _CaptureDiagnosticScreenState();
}

class _CaptureDiagnosticScreenState extends State<CaptureDiagnosticScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _diagnosticData;

  @override
  void initState() {
    super.initState();
    _loadDiagnostic();
  }

  Future<void> _loadDiagnostic() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await widget.controller.getJobDiagnostic(widget.jobId);
      if (data == null) {
        setState(() {
          _error = 'Unable to retrieve diagnostic telemetry for this job.';
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _diagnosticData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load diagnostic telemetry: $e';
        _isLoading = false;
      });
    }
  }

  String _resolveUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      final base = AppConfig.resolveDefaultBackendUrl().replaceAll(RegExp(r'/+$'), '');
      return '$base$trimmed';
    }
    return trimmed;
  }

  Widget _buildStageCard({
    required String title,
    required String subtitle,
    required String? imageUrl,
    required IconData icon,
    bool isCheckerboard = false,
  }) {
    final fullUrl = _resolveUrl(imageUrl);

    return Container(
      decoration: BoxDecoration(
        color: WardrobeTheme.spatialSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WardrobeTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 14, color: WardrobeTheme.electricCyan),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: WardrobeTheme.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 9,
                          color: WardrobeTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: isCheckerboard
                  ? const Color(0xFF1E293B)
                  : WardrobeTheme.studioBackground,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
            ),
            clipBehavior: Clip.antiAlias,
            child: fullUrl.isNotEmpty
                ? Image.network(
                    fullUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, prog) {
                      if (prog == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: WardrobeTheme.electricViolet,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_rounded,
                              size: 28, color: WardrobeTheme.textMuted),
                          const SizedBox(height: 4),
                          Text('Not available',
                              style: TextStyle(
                                  fontSize: 10, color: WardrobeTheme.textMuted)),
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Text('No image reference',
                        style: TextStyle(
                            fontSize: 10, color: WardrobeTheme.textMuted)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityPill(String qualityState) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (qualityState.toUpperCase()) {
      case 'FULL_AI_PROCESSING':
        bg = WardrobeTheme.electricViolet.withValues(alpha: 0.2);
        fg = WardrobeTheme.softViolet;
        label = 'Full Multimodal AI';
        icon = Icons.auto_awesome;
        break;
      case 'LOCAL_NEURAL_PROCESSING':
        bg = WardrobeTheme.electricCyan.withValues(alpha: 0.15);
        fg = WardrobeTheme.electricCyan;
        label = 'Local Neural Matting & CIELAB';
        icon = Icons.memory;
        break;
      case 'LIMITED_PROCESSING':
        bg = WardrobeTheme.statusWarning.withValues(alpha: 0.15);
        fg = WardrobeTheme.statusWarning;
        label = 'Limited Geometric Analysis';
        icon = Icons.tune;
        break;
      case 'NEEDS_MANUAL_REVIEW':
        bg = WardrobeTheme.statusWarning.withValues(alpha: 0.2);
        fg = WardrobeTheme.statusWarning;
        label = 'Needs Manual Review';
        icon = Icons.warning_amber_rounded;
        break;
      default:
        bg = WardrobeTheme.statusCritical.withValues(alpha: 0.15);
        fg = WardrobeTheme.statusCritical;
        label = 'Processing Failed';
        icon = Icons.error_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _buildVlmStatusPill(String vlmStatus) {
    Color fg = WardrobeTheme.textSecondary;
    if (vlmStatus == 'SUCCESS') fg = WardrobeTheme.statusSuccess;
    if (vlmStatus == 'TIMED_OUT') fg = WardrobeTheme.statusWarning;
    if (vlmStatus == 'FAILED') fg = WardrobeTheme.statusCritical;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'VLM: $vlmStatus',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveJobId = widget.jobId ?? widget.controller.activeJob?.id ?? 'N/A';

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
              'Capture Diagnostics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: WardrobeTheme.textPrimary,
              ),
            ),
            Text(
              'Job: $effectiveJobId',
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: WardrobeTheme.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: WardrobeTheme.electricCyan),
            tooltip: 'Reload Diagnostics',
            onPressed: _loadDiagnostic,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: WardrobeTheme.electricViolet,
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 48, color: WardrobeTheme.statusCritical),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: WardrobeTheme.statusCritical, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadDiagnostic,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WardrobeTheme.spatialSurface,
                            foregroundColor: WardrobeTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final d = _diagnosticData!;
    final qualityState = d['quality_state']?.toString() ?? 'LOCAL_NEURAL_PROCESSING';
    final vlmStatus = d['vlm_status']?.toString() ?? 'OFFLINE_LOCAL';
    final latency = d['processing_time_ms'] ?? 0;
    final provider = d['provider_type']?.toString() ?? 'Unknown';
    final origRef = d['original_image_ref']?.toString();
    final maskRef = d['mask_image_ref']?.toString();
    final cutoutRef = d['cutout_image_ref']?.toString();
    final catRef = d['catalogue_image_ref']?.toString();
    final warnings = (d['warnings'] as List?)?.map((w) => w.toString()).toList() ?? [];
    final attrs = (d['extracted_attributes'] as Map<String, dynamic>?) ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quality & Telemetry Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: WardrobeTheme.spatialSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WardrobeTheme.borderViolet),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQualityPill(qualityState),
                    _buildVlmStatusPill(vlmStatus),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(color: WardrobeTheme.borderSubtle, height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Latency: ${latency}ms',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: WardrobeTheme.textSecondary),
                    ),
                    Text(
                      'Provider: $provider',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: WardrobeTheme.softViolet),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Warnings banner if any
          if (warnings.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: WardrobeTheme.statusWarning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: WardrobeTheme.statusWarning.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 16, color: WardrobeTheme.statusWarning),
                      const SizedBox(width: 6),
                      Text(
                        'Processing Warnings',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: WardrobeTheme.statusWarning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...warnings.map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Text('• $w',
                          style: TextStyle(
                              fontSize: 11, color: WardrobeTheme.textSecondary)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 4-Stage Pipeline Title
          Text(
            'IMAGE PIPELINE STAGES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: WardrobeTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),

          // 2x2 Grid for 4 Stages
          Row(
            children: [
              Expanded(
                child: _buildStageCard(
                  title: '1. Original Photo',
                  subtitle: 'User camera / gallery',
                  imageUrl: origRef,
                  icon: Icons.camera_alt_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStageCard(
                  title: '2. Binary Mask',
                  subtitle: 'U2-Net SOD boundary',
                  imageUrl: maskRef,
                  icon: Icons.contrast_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStageCard(
                  title: '3. Transparent Cutout',
                  subtitle: 'Garment isolated',
                  imageUrl: cutoutRef,
                  icon: Icons.layers_outlined,
                  isCheckerboard: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStageCard(
                  title: '4. Catalogue Card',
                  subtitle: 'Centered, auto-leveled',
                  imageUrl: catRef,
                  icon: Icons.checkroom_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Extracted Attributes Section
          Text(
            'EXTRACTED ATTRIBUTES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: WardrobeTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WardrobeTheme.spatialSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WardrobeTheme.borderSubtle),
            ),
            child: Column(
              children: [
                _buildAttributeRow('Garment Name', attrs['suggested_name'] ?? 'N/A'),
                _buildAttributeRow('Category', attrs['main_category'] ?? 'N/A'),
                _buildAttributeRow('Subcategory', attrs['subcategory'] ?? 'N/A'),
                _buildAttributeRow('Primary Color', attrs['primary_color'] ?? 'N/A'),
                _buildAttributeRow(
                    'Secondary Colors',
                    (attrs['secondary_colors'] as List?)?.join(', ') ?? 'None'),
                _buildAttributeRow('Pattern', attrs['pattern'] ?? 'Solid'),
                _buildAttributeRow('Fabric', attrs['fabric_material'] ?? 'Unspecified'),
                _buildAttributeRow('Sleeves', attrs['sleeve_length'] ?? 'Unspecified'),
                _buildAttributeRow('Neckline', attrs['neckline'] ?? 'Unspecified'),
                _buildAttributeRow('Fit', attrs['fit'] ?? 'Unspecified'),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAttributeRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: WardrobeTheme.textMuted),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: WardrobeTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../controllers/wardrobe_capture_controller.dart';
import '../theme/wardrobe_theme.dart';
import 'capture_review_screen.dart';

/// Screen displaying asynchronous job processing stages for garment detection and segmentation.
class CaptureProcessingScreen extends StatefulWidget {
  final WardrobeCaptureController controller;

  const CaptureProcessingScreen({
    super.key,
    required this.controller,
  });

  @override
  State<CaptureProcessingScreen> createState() =>
      _CaptureProcessingScreenState();
}

class _CaptureProcessingScreenState extends State<CaptureProcessingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startProcessing();
    });
  }

  Future<void> _startProcessing() async {
    final job = await widget.controller.startCaptureJob();
    if (mounted && job != null && (job.isAwaitingApproval || job.isCompleted)) {
      _navigateToReview();
    }
  }

  void _navigateToReview() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CaptureReviewScreen(
          controller: widget.controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WardrobeTheme.voidBg,
      appBar: AppBar(
        backgroundColor: WardrobeTheme.voidBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: WardrobeTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Processing Photograph',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: WardrobeTheme.textPrimary,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final job = widget.controller.activeJob;
          final error = widget.controller.errorMessage;
          final stage = job?.currentStage ?? 'Analyzing photograph...';
          final progress = (job?.progressPercent ?? 30) / 100.0;

          // Check if ready to transition to review
          if (job != null &&
              job.isAwaitingApproval &&
              !widget.controller.isProcessing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _navigateToReview();
            });
          }

          if (error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: WardrobeTheme.statusCritical
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.error_outline_rounded,
                          color: WardrobeTheme.statusCritical, size: 48),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Analysis Interrupted',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: WardrobeTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: WardrobeTheme.textSecondary,
                          height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your original photograph is safely preserved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11, color: WardrobeTheme.textMuted),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Back to Photo'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final ok = await widget.controller.retryCapture();
                            if (ok && mounted) _navigateToReview();
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Retry Analysis'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WardrobeTheme.electricViolet,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              WardrobeTheme.electricViolet),
                          backgroundColor: WardrobeTheme.spatialSurface,
                        ),
                      ),
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: WardrobeTheme.electricCyan,
                        size: 36,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    stage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: WardrobeTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Detecting garments, separating catalogue cards & extracting attributes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        color: WardrobeTheme.textMuted,
                        height: 1.3),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: WardrobeTheme.spatialSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: WardrobeTheme.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_outlined,
                            color: WardrobeTheme.softViolet, size: 16),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'TESS preserves your actual garments without AI redesigns.',
                            style: TextStyle(
                                fontSize: 11,
                                color: WardrobeTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tess_button.dart';
import '../../../shared/widgets/tess_card.dart';
import '../models/screen_analysis_model.dart';

/// ScreenAnalysisCard: Explicit user-consented screen capture, review, and Vision AI analysis.
class ScreenAnalysisCard extends StatefulWidget {
  final ScreenAnalysisModel? analysisResult;
  final bool isAnalyzing;
  final Function(String query, bool consentGranted) onAnalyze;

  const ScreenAnalysisCard({
    super.key,
    required this.analysisResult,
    required this.isAnalyzing,
    required this.onAnalyze,
  });

  @override
  State<ScreenAnalysisCard> createState() => _ScreenAnalysisCardState();
}

class _ScreenAnalysisCardState extends State<ScreenAnalysisCard> {
  late final TextEditingController _queryController;
  bool _consentGranted = false;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(
      text: 'Explain what is visible on the screen and any errors.',
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    widget.onAnalyze(_queryController.text.trim(), _consentGranted);
  }

  @override
  Widget build(BuildContext context) {
    return TessCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.violet.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.screenshot_monitor_rounded, color: AppColors.violet, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SCREEN CONTEXT UNDERSTANDING',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Vision AI analysis of user-authorized display context',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Query Input Field
          TextField(
            controller: _queryController,
            maxLines: 2,
            enabled: !widget.isAnalyzing,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'What should TESS explain or troubleshoot?',
              hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.bgSecondary,
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Explicit Consent Checkbox
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _consentGranted ? AppColors.cyan.withValues(alpha: 0.4) : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _consentGranted,
                  activeColor: AppColors.cyan,
                  onChanged: widget.isAnalyzing ? null : (val) => setState(() => _consentGranted = val ?? false),
                ),
                const Expanded(
                  child: Text(
                    'I authorize TESS to capture and analyze the current active display context.',
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          TessButton(
            label: widget.isAnalyzing ? 'Analyzing Screen Context...' : 'Authorize & Analyze Screen',
            icon: Icons.camera_alt_rounded,
            variant: _consentGranted ? TessButtonVariant.cyan : TessButtonVariant.secondary,
            onPressed: (_consentGranted && !widget.isAnalyzing) ? _handleSubmit : null,
          ),

          // Vision Analysis Results
          if (widget.analysisResult != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.insights_rounded, size: 14, color: AppColors.cyan),
                      const SizedBox(width: 6),
                      Text(
                        'VISION INTELLIGENCE (${widget.analysisResult!.resolutionDisplay})',
                        style: const TextStyle(
                          fontSize: 9,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: AppColors.cyan,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.analysisResult!.analysis,
                    style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.textPrimary),
                  ),
                  if (widget.analysisResult!.suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'RECOMMENDATIONS:',
                      style: TextStyle(fontSize: 9, fontFamily: 'monospace', color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    ...widget.analysisResult!.suggestions.map((sugg) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: AppColors.cyan, fontSize: 11)),
                            Expanded(
                              child: Text(
                                sugg,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

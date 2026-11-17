import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tess_button.dart';
import '../../../shared/widgets/tess_card.dart';
import '../models/speech_transcription_model.dart';

/// TranscriptReviewCard: Allows user inspection and inline editing of transcribed speech before submission.
class TranscriptReviewCard extends StatefulWidget {
  final SpeechTranscriptionModel transcription;
  final Function(String edited) onSaveEdit;
  final VoidCallback onSubmit;
  final VoidCallback onDiscard;
  final bool isSubmitting;

  const TranscriptReviewCard({
    super.key,
    required this.transcription,
    required this.onSaveEdit,
    required this.onSubmit,
    required this.onDiscard,
    this.isSubmitting = false,
  });

  @override
  State<TranscriptReviewCard> createState() => _TranscriptReviewCardState();
}

class _TranscriptReviewCardState extends State<TranscriptReviewCard> {
  late final TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.transcription.effectiveText);
  }

  @override
  void didUpdateWidget(covariant TranscriptReviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transcription.effectiveText != oldWidget.transcription.effectiveText && !_isEditing) {
      _controller.text = widget.transcription.effectiveText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveEdit() {
    widget.onSaveEdit(_controller.text.trim());
    setState(() => _isEditing = false);
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'WHISPER STT',
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: AppColors.cyan,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.transcription.isEdited)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.violet.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'EDITED',
                    style: TextStyle(fontSize: 8, fontFamily: 'monospace', color: AppColors.violet),
                  ),
                ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _isEditing ? Icons.check_rounded : Icons.edit_note_rounded,
                  size: 20,
                  color: AppColors.cyan,
                ),
                tooltip: _isEditing ? 'Save Edit' : 'Edit Transcript',
                onPressed: () {
                  if (_isEditing) {
                    _saveEdit();
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          if (_isEditing) ...[
            TextField(
              controller: _controller,
              maxLines: 4,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.bgSecondary,
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.cyan),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                widget.transcription.effectiveText,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TessButton(
                  label: 'Discard',
                  icon: Icons.delete_outline_rounded,
                  variant: TessButtonVariant.secondary,
                  onPressed: widget.isSubmitting ? null : widget.onDiscard,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TessButton(
                  label: widget.isSubmitting ? 'Sending...' : 'Submit to Chat',
                  icon: Icons.send_rounded,
                  variant: TessButtonVariant.cyan,
                  onPressed: widget.isSubmitting ? null : widget.onSubmit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

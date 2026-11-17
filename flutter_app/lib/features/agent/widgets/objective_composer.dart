import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tess_button.dart';
import '../../../shared/widgets/tess_card.dart';
import '../models/agent_objective_model.dart';

/// ObjectiveComposer: Natural language input bar for submitting agent objectives.
class ObjectiveComposer extends StatefulWidget {
  final Function(String objective) onSubmit;
  final bool isGenerating;
  final String? initialPrompt;

  const ObjectiveComposer({
    super.key,
    required this.onSubmit,
    this.isGenerating = false,
    this.initialPrompt,
  });

  @override
  State<ObjectiveComposer> createState() => _ObjectiveComposerState();
}

class _ObjectiveComposerState extends State<ObjectiveComposer> {
  late final TextEditingController _controller;
  String? _clientError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPrompt ?? '');
  }

  @override
  void didUpdateWidget(covariant ObjectiveComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPrompt != null && widget.initialPrompt != oldWidget.initialPrompt) {
      _controller.text = widget.initialPrompt!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    final model = AgentObjectiveModel(objective: text);
    final error = model.validationError;
    if (error != null) {
      setState(() => _clientError = error);
      return;
    }

    setState(() => _clientError = null);
    widget.onSubmit(text);
  }

  void _selectSuggestion(String suggestion) {
    setState(() {
      _controller.text = suggestion;
      _clientError = null;
    });
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
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.psychology_rounded, color: AppColors.cyan, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AGENT OBJECTIVE COMPOSER',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Describe the task you want TESS to plan and execute.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Suggestion Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AgentObjectiveModel.suggestions.map((suggestion) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: Text(
                      suggestion,
                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                    ),
                    backgroundColor: AppColors.bgSecondary,
                    side: BorderSide(color: AppColors.violet.withValues(alpha: 0.3)),
                    onPressed: widget.isGenerating ? null : () => _selectSuggestion(suggestion),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Input field
          TextField(
            controller: _controller,
            maxLines: 3,
            minLines: 2,
            enabled: !widget.isGenerating,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. Update my OpenProject worklog: 2 hours on task 1',
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.bgSecondary,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
              ),
            ),
          ),

          if (_clientError != null) ...[
            const SizedBox(height: 8),
            Text(
              _clientError!,
              style: const TextStyle(fontSize: 11, color: AppColors.danger),
            ),
          ],

          const SizedBox(height: 12),

          TessButton(
            label: widget.isGenerating ? 'Synthesizing Action Plan...' : 'Generate Action Plan',
            icon: widget.isGenerating ? Icons.hourglass_top_rounded : Icons.auto_awesome_rounded,
            variant: TessButtonVariant.cyan,
            onPressed: widget.isGenerating ? null : _handleSubmit,
          ),
        ],
      ),
    );
  }
}

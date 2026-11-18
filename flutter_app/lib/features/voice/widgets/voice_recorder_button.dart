import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

/// Animated microphone recording button with pulsing status and duration timer.
class VoiceRecorderButton extends StatefulWidget {
  final bool isRecording;
  final Duration duration;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const VoiceRecorderButton({
    super.key,
    required this.isRecording,
    required this.duration,
    required this.onStart,
    required this.onStop,
  });

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    if (widget.isRecording) {
      _animController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant VoiceRecorderButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _animController.repeat(reverse: true);
      } else {
        _animController.stop();
        _animController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing Mic Button
        GestureDetector(
          onTap: widget.isRecording ? widget.onStop : widget.onStart,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = widget.isRecording ? _pulseAnimation.value : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: widget.isRecording
                        ? null
                        : const LinearGradient(
                            colors: [AppColors.vibrantMint, AppColors.tessTeal],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: widget.isRecording ? AppColors.accentDanger : null,
                    boxShadow: [
                      BoxShadow(
                        color: (widget.isRecording ? AppColors.accentDanger : AppColors.vibrantMint)
                            .withOpacity(0.35),
                        blurRadius: widget.isRecording ? 24 : 14,
                        spreadRadius: widget.isRecording ? 4 : 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // Duration or Status Text
        if (widget.isRecording) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentDanger.withOpacity(0.12),
              borderRadius: AppRadius.radiusPill,
              border: Border.all(color: AppColors.accentDanger.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.accentDanger,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(widget.duration),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentDanger,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Text(
            'Tap to Speak Directive',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

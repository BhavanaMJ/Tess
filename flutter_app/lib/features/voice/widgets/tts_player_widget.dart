import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tess_card.dart';
import '../models/audio_playback_state.dart';

/// TTSPlayerWidget: Audio player controls for listening to synthesized assistant voice responses.
class TTSPlayerWidget extends StatelessWidget {
  final String text;
  final AudioPlaybackState playbackState;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onStop;

  const TTSPlayerWidget({
    super.key,
    required this.text,
    required this.playbackState,
    required this.onTogglePlayPause,
    required this.onStop,
  });

  String _formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return TessCard(
      borderColor: AppColors.violet.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.violet.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'TESS VOICE (TTS)',
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: AppColors.violet,
                  ),
                ),
              ),
              const Spacer(),
              if (playbackState.isPlaying)
                const Text(
                  'PLAYING AUDIO...',
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: 'monospace',
                    color: AppColors.cyan,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Response Text Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Progress Bar
          LinearProgressIndicator(
            value: playbackState.progress,
            backgroundColor: AppColors.bgSecondary,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
            minHeight: 4,
          ),

          const SizedBox(height: 6),

          // Timestamp & Controls Row
          Row(
            children: [
              Text(
                '${_formatTime(playbackState.position)} / ${_formatTime(playbackState.duration)}',
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),

              // Stop Button
              IconButton(
                icon: const Icon(Icons.stop_rounded, size: 22, color: AppColors.textMuted),
                tooltip: 'Stop Playback',
                onPressed: playbackState.isStopped ? null : onStop,
              ),

              // Play / Pause Button
              IconButton(
                icon: Icon(
                  playbackState.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                  size: 32,
                  color: AppColors.cyan,
                ),
                tooltip: playbackState.isPlaying ? 'Pause Audio' : 'Play Audio',
                onPressed: onTogglePlayPause,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

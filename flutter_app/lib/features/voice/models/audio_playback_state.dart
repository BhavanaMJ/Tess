enum AudioPlaybackStatus { stopped, loading, playing, paused, error }

/// Model capturing audio playback state and telemetry.
class AudioPlaybackState {
  final AudioPlaybackStatus status;
  final Duration position;
  final Duration duration;
  final String? errorMessage;

  const AudioPlaybackState({
    this.status = AudioPlaybackStatus.stopped,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.errorMessage,
  });

  bool get isPlaying => status == AudioPlaybackStatus.playing;
  bool get isPaused => status == AudioPlaybackStatus.paused;
  bool get isStopped => status == AudioPlaybackStatus.stopped;
  bool get isLoading => status == AudioPlaybackStatus.loading;
  bool get hasError => status == AudioPlaybackStatus.error;

  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  AudioPlaybackState copyWith({
    AudioPlaybackStatus? status,
    Duration? position,
    Duration? duration,
    String? errorMessage,
  }) {
    return AudioPlaybackState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

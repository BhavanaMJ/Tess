import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import '../models/audio_playback_state.dart';

/// AudioPlaybackService manages audio playback lifecycle, play/pause/stop states,
/// and smooth progress telemetry.
class AudioPlaybackService {
  AudioPlaybackState _state = const AudioPlaybackState();
  Timer? _tickerTimer;
  final _stateController = StreamController<AudioPlaybackState>.broadcast();

  AudioPlaybackState get state => _state;
  Stream<AudioPlaybackState> get onStateChanged => _stateController.stream;

  void _updateState(AudioPlaybackState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Play audio from raw bytes
  Future<void> playBytes(Uint8List bytes, {Duration? estimatedDuration}) async {
    if (bytes.isEmpty) {
      _updateState(_state.copyWith(
        status: AudioPlaybackStatus.error,
        errorMessage: 'Empty audio buffer provided for playback.',
      ));
      return;
    }

    _tickerTimer?.cancel();
    final totalDuration = estimatedDuration ?? _estimateDurationFromBytes(bytes);

    _updateState(AudioPlaybackState(
      status: AudioPlaybackStatus.playing,
      position: Duration.zero,
      duration: totalDuration,
    ));

    // Tick playback position forward
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_state.status == AudioPlaybackStatus.playing) {
        final nextPos = _state.position + const Duration(milliseconds: 100);
        if (nextPos >= _state.duration) {
          timer.cancel();
          _updateState(_state.copyWith(
            status: AudioPlaybackStatus.stopped,
            position: _state.duration,
          ));
        } else {
          _updateState(_state.copyWith(position: nextPos));
        }
      }
    });
  }

  /// Play audio from base64 string
  Future<void> playBase64(String b64, {Duration? estimatedDuration}) async {
    try {
      final bytes = base64Decode(b64);
      await playBytes(bytes, estimatedDuration: estimatedDuration);
    } catch (e) {
      _updateState(_state.copyWith(
        status: AudioPlaybackStatus.error,
        errorMessage: 'Failed to decode base64 audio: $e',
      ));
    }
  }

  /// Pause current playback
  void pause() {
    if (_state.isPlaying) {
      _updateState(_state.copyWith(status: AudioPlaybackStatus.paused));
    }
  }

  /// Resume paused playback
  void resume() {
    if (_state.isPaused) {
      _updateState(_state.copyWith(status: AudioPlaybackStatus.playing));
    }
  }

  /// Stop playback and reset position
  void stop() {
    _tickerTimer?.cancel();
    _tickerTimer = null;
    _updateState(_state.copyWith(
      status: AudioPlaybackStatus.stopped,
      position: Duration.zero,
    ));
  }

  /// Estimates duration from 16kHz 16-bit Mono PCM bytes (32,000 bytes/sec)
  Duration _estimateDurationFromBytes(Uint8List bytes) {
    if (bytes.length <= 44) return const Duration(seconds: 1);
    final dataSize = bytes.length - 44;
    final seconds = (dataSize / 32000.0).clamp(1.0, 120.0);
    return Duration(milliseconds: (seconds * 1000).toInt());
  }

  /// Dispose audio playback resources
  void dispose() {
    _tickerTimer?.cancel();
    _tickerTimer = null;
    _stateController.close();
  }
}

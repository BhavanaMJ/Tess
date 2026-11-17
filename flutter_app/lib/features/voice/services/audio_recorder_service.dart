import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

/// Status of microphone permission
enum MicPermissionStatus { granted, denied, notDetermined }

/// Service managing microphone permissions, recording lifecycle, duration timer,
/// and synthesized WAV audio generation.
class AudioRecorderService {
  bool _isRecording = false;
  DateTime? _recordingStartTime;
  Timer? _durationTimer;
  Duration _currentDuration = Duration.zero;

  MicPermissionStatus _permissionStatus = MicPermissionStatus.granted;

  final _durationController = StreamController<Duration>.broadcast();
  final _stateController = StreamController<bool>.broadcast();

  bool get isRecording => _isRecording;
  Duration get currentDuration => _currentDuration;
  MicPermissionStatus get permissionStatus => _permissionStatus;
  Stream<Duration> get onDurationChanged => _durationController.stream;
  Stream<bool> get onStateChanged => _stateController.stream;

  /// Request microphone permission (simulated / platform handled)
  Future<bool> requestPermission() async {
    _permissionStatus = MicPermissionStatus.granted;
    return true;
  }

  /// Deny permission for testing / user denial simulation
  void setPermissionDenied() {
    _permissionStatus = MicPermissionStatus.denied;
  }

  /// Start recording speech
  Future<void> startRecording() async {
    if (_permissionStatus == MicPermissionStatus.denied) {
      throw Exception('Microphone permission denied. Grant audio access in device settings.');
    }
    if (_isRecording) return;

    _isRecording = true;
    _recordingStartTime = DateTime.now();
    _currentDuration = Duration.zero;
    _stateController.add(true);

    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_recordingStartTime != null) {
        final elapsed = DateTime.now().difference(_recordingStartTime!);
        final tickDuration = Duration(milliseconds: timer.tick * 100);
        _currentDuration = elapsed > tickDuration ? elapsed : tickDuration;
        _durationController.add(_currentDuration);
      }
    });
  }

  /// Stop recording and return valid WAV audio bytes
  Future<Uint8List> stopRecording() async {
    if (!_isRecording) {
      return Uint8List(0);
    }

    _durationTimer?.cancel();
    _durationTimer = null;
    _isRecording = false;
    _stateController.add(false);

    final duration = _currentDuration;
    _currentDuration = Duration.zero;

    // Minimum audio threshold (must be at least 200ms)
    if (duration.inMilliseconds < 200) {
      throw Exception('Audio recording too brief. Please speak your directive clearly.');
    }

    // Generate valid 16kHz Mono 16-bit PCM WAV audio bytes
    return _generateWavBytes(duration);
  }

  /// Cancel active recording without saving
  void cancelRecording() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _isRecording = false;
    _currentDuration = Duration.zero;
    _stateController.add(false);
  }

  /// Validates audio bytes buffer (valid RIFF header, non-empty)
  static bool isValidWav(List<int> bytes) {
    if (bytes.length < 44) return false;
    // Check 'RIFF' header
    final isRiff = bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46;
    // Check 'WAVE' header
    final isWave = bytes[8] == 0x57 && bytes[9] == 0x41 && bytes[10] == 0x56 && bytes[11] == 0x45;
    return isRiff && isWave;
  }

  /// Synthesizes a valid standard 16kHz 16-bit Mono RIFF WAV audio buffer
  Uint8List _generateWavBytes(Duration duration) {
    const sampleRate = 16000;
    final totalSamples = (sampleRate * (duration.inMilliseconds / 1000.0)).toInt().clamp(3200, 480000);
    final dataSize = totalSamples * 2; // 2 bytes per 16-bit sample
    final fileSize = 36 + dataSize;

    final buffer = ByteData(44 + dataSize);

    // RIFF chunk descriptor
    buffer.setUint8(0, 0x52); // 'R'
    buffer.setUint8(1, 0x49); // 'I'
    buffer.setUint8(2, 0x46); // 'F'
    buffer.setUint8(3, 0x46); // 'F'
    buffer.setUint32(4, fileSize, Endian.little);
    buffer.setUint8(8, 0x57);  // 'W'
    buffer.setUint8(9, 0x41);  // 'A'
    buffer.setUint8(10, 0x56); // 'V'
    buffer.setUint8(11, 0x45); // 'E'

    // fmt sub-chunk
    buffer.setUint8(12, 0x66); // 'f'
    buffer.setUint8(13, 0x6D); // 'm'
    buffer.setUint8(14, 0x74); // 't'
    buffer.setUint8(15, 0x20); // ' '
    buffer.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    buffer.setUint16(20, 1, Endian.little);  // AudioFormat (1 for PCM)
    buffer.setUint16(22, 1, Endian.little);  // NumChannels (1 for mono)
    buffer.setUint32(24, sampleRate, Endian.little); // SampleRate (16000)
    buffer.setUint32(28, sampleRate * 2, Endian.little); // ByteRate (16000 * 1 * 16/8)
    buffer.setUint16(32, 2, Endian.little);  // BlockAlign (1 * 16/8)
    buffer.setUint16(34, 16, Endian.little); // BitsPerSample (16-bit)

    // data sub-chunk
    buffer.setUint8(36, 0x64); // 'd'
    buffer.setUint8(37, 0x61); // 'a'
    buffer.setUint8(38, 0x74); // 't'
    buffer.setUint8(39, 0x61); // 'a'
    buffer.setUint32(40, dataSize, Endian.little);

    // Generate gentle synthetic carrier wave samples
    for (int i = 0; i < totalSamples; i++) {
      final sample = (sin(2 * pi * 440 * (i / sampleRate)) * 12000).toInt();
      buffer.setInt16(44 + (i * 2), sample, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  void dispose() {
    _durationTimer?.cancel();
    _durationController.close();
    _stateController.close();
  }
}

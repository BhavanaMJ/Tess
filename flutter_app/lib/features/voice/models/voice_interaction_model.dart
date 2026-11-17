import 'dart:convert';
import 'dart:typed_data';

/// Model representing a full voice interaction cycle (Speech -> AI Reasoning -> Speech).
class VoiceInteractionModel {
  final String transcript;
  final String responseText;
  final String audioBase64;
  final DateTime timestamp;

  VoiceInteractionModel({
    required this.transcript,
    required this.responseText,
    required this.audioBase64,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toUtc();

  factory VoiceInteractionModel.fromJson(Map<String, dynamic> json) {
    return VoiceInteractionModel(
      transcript: json['transcript']?.toString() ?? '',
      responseText: json['response_text']?.toString() ?? '',
      audioBase64: json['audio_base64']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transcript': transcript,
      'response_text': responseText,
      'audio_base64': audioBase64,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  Uint8List get audioBytes {
    if (audioBase64.isEmpty) return Uint8List(0);
    try {
      return base64Decode(audioBase64);
    } catch (_) {
      return Uint8List(0);
    }
  }

  bool get hasAudio => audioBase64.isNotEmpty;
}


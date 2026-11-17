import 'dart:typed_data';
import '../../../core/network/api_client.dart';
import '../models/voice_interaction_model.dart';

/// VoiceApiService interacts with the FastAPI backend for Speech-to-Text (Whisper),
/// Text-to-Speech (pyttsx3/WAV), and complete Voice Interaction loops.
class VoiceApiService {
  final ApiClient _apiClient;

  VoiceApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Submits an audio recording to FastAPI STT endpoint (/api/v1/voice/transcribe)
  Future<String> transcribeAudio(
    List<int> audioBytes, {
    String filename = 'recording.wav',
  }) async {
    if (audioBytes.isEmpty) {
      throw ApiException(statusCode: 400, message: 'Audio payload cannot be empty');
    }

    final response = await _apiClient.postMultipart(
      '/api/v1/voice/transcribe',
      fileBytes: audioBytes,
      filename: filename,
      fieldName: 'file',
    );

    if (response is Map && response.containsKey('transcript')) {
      return response['transcript'].toString();
    }
    throw ApiException(statusCode: 500, message: 'Invalid response from speech recognition engine');
  }

  /// Synthesizes text into audio bytes via FastAPI TTS endpoint (/api/v1/voice/synthesize)
  Future<Uint8List> synthesizeSpeech(String text) async {
    if (text.trim().isEmpty) {
      throw ApiException(statusCode: 400, message: 'Text to synthesize cannot be empty');
    }

    final audioBytes = await _apiClient.postForBytes(
      '/api/v1/voice/synthesize',
      body: {'text': text},
    );

    if (audioBytes.isNotEmpty) {
      return audioBytes;
    }
    throw ApiException(statusCode: 500, message: 'Empty audio buffer returned from synthesizer');
  }

  /// Full conversational voice loop (/api/v1/voice/interact)
  Future<VoiceInteractionModel> voiceInteract(
    List<int> audioBytes, {
    String filename = 'audio.wav',
  }) async {
    if (audioBytes.isEmpty) {
      throw ApiException(statusCode: 400, message: 'Audio payload cannot be empty');
    }

    final response = await _apiClient.postMultipart(
      '/api/v1/voice/interact',
      fileBytes: audioBytes,
      filename: filename,
      fieldName: 'file',
    );

    if (response is Map<String, dynamic>) {
      return VoiceInteractionModel.fromJson(response);
    }
    throw ApiException(statusCode: 500, message: 'Failed to process conversational voice cycle');
  }
}


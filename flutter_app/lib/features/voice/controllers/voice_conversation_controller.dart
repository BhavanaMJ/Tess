import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../chat/services/chat_service.dart';
import '../models/audio_playback_state.dart';
import '../models/speech_transcription_model.dart';
import '../models/voice_interaction_model.dart';
import '../services/audio_playback_service.dart';
import '../services/audio_recorder_service.dart';
import '../services/voice_api_service.dart';

/// VoiceConversationController orchestrates the voice loop:
/// Record Speech -> Transcribe -> Human Review/Edit -> Submit to Chat -> TTS Playback.
class VoiceConversationController extends ChangeNotifier {
  final AudioRecorderService recorder;
  final VoiceApiService voiceApi;
  final AudioPlaybackService playback;
  final ChatService chatService;

  String? conversationId;

  bool _isTranscribing = false;
  bool _isSubmitting = false;
  bool _isSynthesizing = false;
  String? _errorMessage;

  SpeechTranscriptionModel? _transcription;
  String? _aiResponseText;
  Uint8List? _aiAudioBytes;

  StreamSubscription? _durationSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _playbackSub;

  VoiceConversationController({
    AudioRecorderService? recorder,
    VoiceApiService? voiceApi,
    AudioPlaybackService? playback,
    ChatService? chatService,
    this.conversationId,
  })  : recorder = recorder ?? AudioRecorderService(),
        voiceApi = voiceApi ?? VoiceApiService(),
        playback = playback ?? AudioPlaybackService(),
        chatService = chatService ?? ChatService() {
    _durationSub = this.recorder.onDurationChanged.listen((_) => notifyListeners());
    _stateSub = this.recorder.onStateChanged.listen((_) => notifyListeners());
    _playbackSub = this.playback.onStateChanged.listen((_) => notifyListeners());
  }

  bool get isRecording => recorder.isRecording;
  Duration get recordingDuration => recorder.currentDuration;
  bool get isTranscribing => _isTranscribing;
  bool get isSubmitting => _isSubmitting;
  bool get isSynthesizing => _isSynthesizing;
  String? get errorMessage => _errorMessage;

  SpeechTranscriptionModel? get transcription => _transcription;
  String? get aiResponseText => _aiResponseText;
  Uint8List? get aiAudioBytes => _aiAudioBytes;
  AudioPlaybackState get playbackState => playback.state;

  /// Start recording user voice
  Future<void> startRecording() async {
    _errorMessage = null;
    notifyListeners();
    try {
      await recorder.startRecording();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Stop recording, upload to STT, and allow human transcript inspection
  Future<void> stopRecordingAndTranscribe() async {
    try {
      final bytes = await recorder.stopRecording();
      if (bytes.isEmpty) return;

      _isTranscribing = true;
      _errorMessage = null;
      notifyListeners();

      final transcript = await voiceApi.transcribeAudio(bytes);
      _transcription = SpeechTranscriptionModel.fromApi(transcript, duration: recorder.currentDuration);
      _isTranscribing = false;
      notifyListeners();
    } catch (e) {
      _isTranscribing = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// User reviews and updates transcript before dispatch
  void editTranscript(String editedText) {
    if (_transcription != null) {
      _transcription = _transcription!.copyWith(editedTranscript: editedText);
      notifyListeners();
    } else {
      _transcription = SpeechTranscriptionModel.fromApi(editedText);
      notifyListeners();
    }
  }

  /// Submit reviewed transcript to existing Chat conversation thread
  Future<void> submitTranscriptToChat() async {
    if (_transcription == null || _transcription!.isEmpty) return;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Ensure conversation ID exists
      if (conversationId == null || conversationId!.isEmpty) {
        final conv = await chatService.createConversation(title: 'Voice Directive Session');
        conversationId = conv.id;
      }

      // 2. Submit text to chat endpoint
      final response = await chatService.sendMessage(
        conversationId: conversationId!,
        message: _transcription!.effectiveText,
      );
      _aiResponseText = response;
      _isSubmitting = false;
      notifyListeners();

      // 3. Synthesize speech for AI response
      await synthesizeResponseSpeech();
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Synthesize TTS audio for assistant response
  Future<void> synthesizeResponseSpeech() async {
    if (_aiResponseText == null || _aiResponseText!.isEmpty) return;

    _isSynthesizing = true;
    notifyListeners();

    try {
      final audioBytes = await voiceApi.synthesizeSpeech(_aiResponseText!);
      _aiAudioBytes = audioBytes;
      _isSynthesizing = false;
      notifyListeners();

      // Automatically play response
      await playback.playBytes(audioBytes);
    } catch (e) {
      _isSynthesizing = false;
      // Non-fatal warning: text still displayed
      debugPrint('[VoiceController] TTS synthesis warning: $e');
      notifyListeners();
    }
  }

  /// Complete single-tap conversational voice interaction (/api/v1/voice/interact)
  Future<VoiceInteractionModel?> completeVoiceCycle() async {
    try {
      final bytes = await recorder.stopRecording();
      if (bytes.isEmpty) return null;

      _isTranscribing = true;
      _isSubmitting = true;
      _errorMessage = null;
      notifyListeners();

      final result = await voiceApi.voiceInteract(bytes);
      _transcription = SpeechTranscriptionModel.fromApi(result.transcript);
      _aiResponseText = result.responseText;
      _aiAudioBytes = result.audioBytes;

      _isTranscribing = false;
      _isSubmitting = false;
      notifyListeners();

      if (result.hasAudio) {
        await playback.playBytes(result.audioBytes);
      }
      return result;
    } catch (e) {
      _isTranscribing = false;
      _isSubmitting = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Play or Pause TTS playback
  void togglePlayPause() {
    if (playback.state.isPlaying) {
      playback.pause();
    } else if (playback.state.isPaused) {
      playback.resume();
    } else if (_aiAudioBytes != null) {
      playback.playBytes(_aiAudioBytes!);
    }
  }

  /// Stop TTS playback
  void stopPlayback() {
    playback.stop();
  }

  /// Reset current voice draft
  void reset() {
    recorder.cancelRecording();
    playback.stop();
    _transcription = null;
    _aiResponseText = null;
    _aiAudioBytes = null;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _stateSub?.cancel();
    _playbackSub?.cancel();
    recorder.dispose();
    playback.dispose();
    super.dispose();
  }
}

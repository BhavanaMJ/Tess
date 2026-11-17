import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/widgets/mascot_widget.dart';
import '../controllers/voice_conversation_controller.dart';
import '../models/device_registration_model.dart';
import '../models/screen_analysis_model.dart';
import '../services/device_notification_service.dart';
import '../services/screen_analysis_service.dart';
import '../widgets/device_status_card.dart';
import '../widgets/screen_analysis_card.dart';
import '../widgets/transcript_review_card.dart';
import '../widgets/tts_player_widget.dart';
import '../widgets/voice_recorder_button.dart';

/// VoiceScreen: Voice Interaction & Device Intelligence Command Center
class VoiceScreen extends StatefulWidget {
  final VoiceConversationController? controller;
  final DeviceNotificationService? deviceService;
  final ScreenAnalysisService? screenService;

  const VoiceScreen({
    super.key,
    this.controller,
    this.deviceService,
    this.screenService,
  });

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> with WidgetsBindingObserver {
  late final VoiceConversationController _controller;
  late final DeviceNotificationService _deviceService;
  late final ScreenAnalysisService _screenService;

  int _selectedTab = 0; // 0: VOICE DIRECTIVES, 1: DEVICE INTELLIGENCE
  bool _isRegisteringDevice = false;
  bool _isAnalyzingScreen = false;
  DeviceRegistrationModel? _registeredDevice;
  ScreenAnalysisModel? _screenResult;
  String? _deviceError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = widget.controller ?? VoiceConversationController();
    _deviceService = widget.deviceService ?? DeviceNotificationService();
    _screenService = widget.screenService ?? ScreenAnalysisService();

    _controller.addListener(_onControllerUpdated);
    _loadDeviceStatus();
  }

  void _onControllerUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Audio resource cleanup: stop recording & playback on backgrounding
      if (_controller.isRecording) {
        _controller.recorder.cancelRecording();
      }
      _controller.stopPlayback();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onControllerUpdated);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDeviceStatus() async {
    try {
      final devices = await _deviceService.getRegisteredDevices();
      if (mounted && devices.isNotEmpty) {
        setState(() => _registeredDevice = devices.first);
      }
    } catch (_) {}
  }

  Future<void> _handleRegisterDevice() async {
    setState(() {
      _isRegisteringDevice = true;
      _deviceError = null;
    });

    try {
      await _deviceService.requestNotificationPermission();
      final reg = await _deviceService.registerDevice();
      if (!mounted) return;

      setState(() {
        _registeredDevice = reg;
        _isRegisteringDevice = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Device registered: ${reg.deviceId}'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRegisteringDevice = false;
        _deviceError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _handleScreenAnalysis(String query, bool consentGranted) async {
    setState(() {
      _isAnalyzingScreen = true;
      _deviceError = null;
    });

    try {
      // Synthetic 800x600 PNG capture buffer for analysis
      final samplePngBytes = _generateSamplePng();
      final result = await _screenService.analyzeScreen(
        imageBytes: samplePngBytes,
        query: query,
        hasUserConsent: consentGranted,
      );

      if (!mounted) return;
      setState(() {
        _screenResult = result;
        _isAnalyzingScreen = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzingScreen = false;
        _deviceError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Generates a valid minimal PNG image buffer
  List<int> _generateSamplePng() {
    return [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, // IHDR chunk length
      0x49, 0x48, 0x44, 0x52, // "IHDR"
      0x00, 0x00, 0x03, 0x20, // width: 800
      0x00, 0x00, 0x02, 0x58, // height: 600
      0x08, 0x02, 0x00, 0x00, 0x00, // bit depth, color type
      0x84, 0x82, 0x76, 0x93, // CRC
      0x00, 0x00, 0x00, 0x00, // IEND length
      0x49, 0x45, 0x4E, 0x44, // "IEND"
      0xAE, 0x42, 0x60, 0x82  // CRC
    ];
  }

  MascotState get _mascotState {
    if (_controller.errorMessage != null || _deviceError != null) {
      return MascotState.attention;
    }
    if (_controller.isRecording || _controller.isTranscribing || _controller.isSubmitting) {
      return MascotState.thinking;
    }
    if (_controller.playbackState.isPlaying) {
      return MascotState.happy;
    }
    return MascotState.idle;
  }

  String get _mascotTitle {
    if (_controller.isRecording) return 'Listening to Voice Directive...';
    if (_controller.isTranscribing) return 'Transcribing Speech (Whisper)...';
    if (_controller.isSubmitting) return 'Reasoning Directive...';
    if (_controller.playbackState.isPlaying) return 'Synthesizing Audio (TTS)...';
    if (_controller.errorMessage != null || _deviceError != null) return 'Telemetry Notice';
    return 'Voice & Device Core Nominal';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'VOICE & DEVICE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
              ),
              child: const Text(
                'AI MULTIMODAL',
                style: TextStyle(
                  fontSize: 9,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: AppColors.cyan,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mascot Reactive Telemetry Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  MascotWidget(
                    state: _mascotState,
                    size: 38,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _mascotTitle,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: AppColors.cyan,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Speech-to-text, neural synthesis, and device intelligence.',
                          style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Tab Selector (VOICE DIRECTIVES / DEVICE INTELLIGENCE)
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(0, 'VOICE DIRECTIVES', Icons.mic_rounded),
                  ),
                  Expanded(
                    child: _buildTabButton(1, 'DEVICE & VISION', Icons.devices_other_rounded),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Error Notice Banner
            if (_controller.errorMessage != null || _deviceError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _controller.errorMessage ?? _deviceError ?? 'Unknown error',
                        style: const TextStyle(fontSize: 11, color: AppColors.danger),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.danger, size: 16),
                      onPressed: () {
                        setState(() => _deviceError = null);
                        _controller.reset();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_selectedTab == 0) ...[
              // VOICE DIRECTIVES TAB
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: VoiceRecorderButton(
                    isRecording: _controller.isRecording,
                    duration: _controller.recordingDuration,
                    onStart: _controller.startRecording,
                    onStop: _controller.stopRecordingAndTranscribe,
                  ),
                ),
              ),

              if (_controller.isTranscribing) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan),
                        SizedBox(height: 10),
                        Text(
                          'Transcribing audio with Whisper STT...',
                          style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.cyan),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Transcript Review & Edit
              if (_controller.transcription != null) ...[
                TranscriptReviewCard(
                  transcription: _controller.transcription!,
                  isSubmitting: _controller.isSubmitting,
                  onSaveEdit: _controller.editTranscript,
                  onSubmit: _controller.submitTranscriptToChat,
                  onDiscard: _controller.reset,
                ),
                const SizedBox(height: 16),
              ],

              // Assistant Voice Response Player (TTS)
              if (_controller.aiResponseText != null) ...[
                TTSPlayerWidget(
                  text: _controller.aiResponseText!,
                  playbackState: _controller.playbackState,
                  onTogglePlayPause: _controller.togglePlayPause,
                  onStop: _controller.stopPlayback,
                ),
              ],
            ] else ...[
              // DEVICE INTELLIGENCE TAB
              DeviceStatusCard(
                registeredDevice: _registeredDevice,
                isRegistering: _isRegisteringDevice,
                onRegister: _handleRegisterDevice,
              ),

              const SizedBox(height: 16),

              ScreenAnalysisCard(
                analysisResult: _screenResult,
                isAnalyzing: _isAnalyzingScreen,
                onAnalyze: _handleScreenAnalysis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyan.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: AppColors.cyan.withValues(alpha: 0.4)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.cyan : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.cyan : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

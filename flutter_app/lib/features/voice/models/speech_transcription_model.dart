/// Model representing speech-to-text recognition output with edit capability.
class SpeechTranscriptionModel {
  final String originalTranscript;
  final String? editedTranscript;
  final Duration duration;
  final DateTime createdAt;

  SpeechTranscriptionModel({
    required this.originalTranscript,
    this.editedTranscript,
    this.duration = Duration.zero,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toUtc();

  factory SpeechTranscriptionModel.fromApi(String transcript, {Duration? duration}) {
    return SpeechTranscriptionModel(
      originalTranscript: transcript,
      duration: duration ?? Duration.zero,
    );
  }

  SpeechTranscriptionModel copyWith({
    String? originalTranscript,
    String? editedTranscript,
    Duration? duration,
  }) {
    return SpeechTranscriptionModel(
      originalTranscript: originalTranscript ?? this.originalTranscript,
      editedTranscript: editedTranscript ?? this.editedTranscript,
      duration: duration ?? this.duration,
      createdAt: createdAt,
    );
  }

  bool get isEdited => editedTranscript != null && editedTranscript != originalTranscript;

  String get effectiveText => (editedTranscript ?? originalTranscript).trim();

  bool get isEmpty => effectiveText.isEmpty;
}


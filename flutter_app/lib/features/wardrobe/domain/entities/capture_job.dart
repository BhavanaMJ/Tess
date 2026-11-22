import 'garment_candidate.dart';

/// Represents an asynchronous AI Smart Capture processing job.
class CaptureJob {
  final String id;
  final String userId;
  final String originalImageRef;
  final String status;
  final String currentStage;
  final int progressPercent;
  final int totalDetected;
  final String providerType;
  final String? errorMessage;
  final List<GarmentCandidate> candidates;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CaptureJob({
    required this.id,
    required this.userId,
    required this.originalImageRef,
    required this.status,
    required this.currentStage,
    this.progressPercent = 0,
    this.totalDetected = 0,
    this.providerType = 'DEVELOPMENT_LOCAL',
    this.errorMessage,
    this.candidates = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get isCompleted => status == 'COMPLETED';
  bool get isAwaitingApproval => status == 'AWAITING_APPROVAL';
  bool get isFailed => status == 'FAILED';
  bool get isProcessing => !isCompleted && !isAwaitingApproval && !isFailed;

  CaptureJob copyWith({
    String? id,
    String? userId,
    String? originalImageRef,
    String? status,
    String? currentStage,
    int? progressPercent,
    int? totalDetected,
    String? providerType,
    String? errorMessage,
    List<GarmentCandidate>? candidates,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CaptureJob(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      originalImageRef: originalImageRef ?? this.originalImageRef,
      status: status ?? this.status,
      currentStage: currentStage ?? this.currentStage,
      progressPercent: progressPercent ?? this.progressPercent,
      totalDetected: totalDetected ?? this.totalDetected,
      providerType: providerType ?? this.providerType,
      errorMessage: errorMessage ?? this.errorMessage,
      candidates: candidates ?? this.candidates,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

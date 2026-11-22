import '../../domain/entities/capture_job.dart';
import 'garment_candidate_model.dart';

class CaptureJobModel {
  final String id;
  final String userId;
  final String originalImageRef;
  final String status;
  final String currentStage;
  final int progressPercent;
  final int totalDetected;
  final String providerType;
  final String? errorMessage;
  final List<GarmentCandidateModel> candidates;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CaptureJobModel({
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

  factory CaptureJobModel.fromJson(Map<String, dynamic> json) {
    List<GarmentCandidateModel> cList = [];
    if (json['candidates'] is List) {
      cList = (json['candidates'] as List)
          .map((item) => GarmentCandidateModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return CaptureJobModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      originalImageRef: json['original_image_ref']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      currentStage: json['current_stage']?.toString() ?? 'Validating photograph',
      progressPercent: (json['progress_percent'] as num?)?.toInt() ?? 0,
      totalDetected: (json['total_detected'] as num?)?.toInt() ?? cList.length,
      providerType: json['provider_type']?.toString() ?? 'DEVELOPMENT_LOCAL',
      errorMessage: json['error_message']?.toString(),
      candidates: cList,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'original_image_ref': originalImageRef,
      'status': status,
      'current_stage': currentStage,
      'progress_percent': progressPercent,
      'total_detected': totalDetected,
      'provider_type': providerType,
      'error_message': errorMessage,
      'candidates': candidates.map((c) => c.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  CaptureJob toDomain() {
    return CaptureJob(
      id: id,
      userId: userId,
      originalImageRef: originalImageRef,
      status: status,
      currentStage: currentStage,
      progressPercent: progressPercent,
      totalDetected: totalDetected,
      providerType: providerType,
      errorMessage: errorMessage,
      candidates: candidates.map((c) => c.toDomain()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory CaptureJobModel.fromDomain(CaptureJob entity) {
    return CaptureJobModel(
      id: entity.id,
      userId: entity.userId,
      originalImageRef: entity.originalImageRef,
      status: entity.status,
      currentStage: entity.currentStage,
      progressPercent: entity.progressPercent,
      totalDetected: entity.totalDetected,
      providerType: entity.providerType,
      errorMessage: entity.errorMessage,
      candidates: entity.candidates.map((c) => GarmentCandidateModel.fromDomain(c)).toList(),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}


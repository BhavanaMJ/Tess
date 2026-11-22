import '../../domain/entities/garment_candidate.dart';

class GarmentCandidateModel {
  final String id;
  final String jobId;
  final String suggestedName;
  final String mainCategory;
  final String? subcategory;
  final String primaryColor;
  final List<String> secondaryColors;
  final String? pattern;
  final String? fabricMaterial;
  final String? sleeveLength;
  final String? neckline;
  final String? fit;
  final String? silhouette;
  final String? garmentLength;
  final String? size;
  final String? brand;
  final Map<String, String> confidenceScores;
  final Map<String, dynamic>? boundingBox;
  final String? processedImageRef;
  final String? originalCropRef;
  final bool isIncluded;
  final bool isApproved;
  final String? registeredGarmentId;
  final String? uncertaintyNotes;

  const GarmentCandidateModel({
    required this.id,
    required this.jobId,
    required this.suggestedName,
    required this.mainCategory,
    this.subcategory,
    required this.primaryColor,
    this.secondaryColors = const [],
    this.pattern,
    this.fabricMaterial,
    this.sleeveLength,
    this.neckline,
    this.fit,
    this.silhouette,
    this.garmentLength,
    this.size,
    this.brand,
    this.confidenceScores = const {},
    this.boundingBox,
    this.processedImageRef,
    this.originalCropRef,
    this.isIncluded = true,
    this.isApproved = false,
    this.registeredGarmentId,
    this.uncertaintyNotes,
  });

  factory GarmentCandidateModel.fromJson(Map<String, dynamic> json) {
    Map<String, String> confMap = {};
    if (json['confidence_scores'] is Map) {
      (json['confidence_scores'] as Map).forEach((k, v) {
        confMap[k.toString()] = v.toString();
      });
    }

    return GarmentCandidateModel(
      id: json['id']?.toString() ?? '',
      jobId: json['job_id']?.toString() ?? '',
      suggestedName: json['suggested_name']?.toString() ?? 'Detected Garment',
      mainCategory: json['main_category']?.toString() ?? 'Tops',
      subcategory: json['subcategory']?.toString(),
      primaryColor: json['primary_color']?.toString() ?? 'Unknown',
      secondaryColors: (json['secondary_colors'] as List?)?.map((e) => e.toString()).toList() ?? [],
      pattern: json['pattern']?.toString(),
      fabricMaterial: json['fabric_material']?.toString(),
      sleeveLength: json['sleeve_length']?.toString(),
      neckline: json['neckline']?.toString(),
      fit: json['fit']?.toString(),
      silhouette: json['silhouette']?.toString(),
      garmentLength: json['garment_length']?.toString(),
      size: json['size']?.toString(),
      brand: json['brand']?.toString(),
      confidenceScores: confMap,
      boundingBox: json['bounding_box'] is Map<String, dynamic> ? json['bounding_box'] : null,
      processedImageRef: json['processed_image_ref']?.toString(),
      originalCropRef: json['original_crop_ref']?.toString(),
      isIncluded: json['is_included'] ?? true,
      isApproved: json['is_approved'] ?? false,
      registeredGarmentId: json['registered_garment_id']?.toString(),
      uncertaintyNotes: json['uncertainty_notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'suggested_name': suggestedName,
      'main_category': mainCategory,
      'subcategory': subcategory,
      'primary_color': primaryColor,
      'secondary_colors': secondaryColors,
      'pattern': pattern,
      'fabric_material': fabricMaterial,
      'sleeve_length': sleeveLength,
      'neckline': neckline,
      'fit': fit,
      'silhouette': silhouette,
      'garment_length': garmentLength,
      'size': size,
      'brand': brand,
      'confidence_scores': confidenceScores,
      'bounding_box': boundingBox,
      'processed_image_ref': processedImageRef,
      'original_crop_ref': originalCropRef,
      'is_included': isIncluded,
      'is_approved': isApproved,
      'registered_garment_id': registeredGarmentId,
      'uncertainty_notes': uncertaintyNotes,
    };
  }

  GarmentCandidate toDomain() {
    return GarmentCandidate(
      id: id,
      jobId: jobId,
      suggestedName: suggestedName,
      mainCategory: mainCategory,
      subcategory: subcategory,
      primaryColor: primaryColor,
      secondaryColors: secondaryColors,
      pattern: pattern,
      fabricMaterial: fabricMaterial,
      sleeveLength: sleeveLength,
      neckline: neckline,
      fit: fit,
      silhouette: silhouette,
      garmentLength: garmentLength,
      size: size,
      brand: brand,
      confidenceScores: confidenceScores,
      boundingBox: boundingBox,
      processedImageRef: processedImageRef,
      originalCropRef: originalCropRef,
      isIncluded: isIncluded,
      isApproved: isApproved,
      registeredGarmentId: registeredGarmentId,
      uncertaintyNotes: uncertaintyNotes,
    );
  }

  factory GarmentCandidateModel.fromDomain(GarmentCandidate entity) {
    return GarmentCandidateModel(
      id: entity.id,
      jobId: entity.jobId,
      suggestedName: entity.suggestedName,
      mainCategory: entity.mainCategory,
      subcategory: entity.subcategory,
      primaryColor: entity.primaryColor,
      secondaryColors: entity.secondaryColors,
      pattern: entity.pattern,
      fabricMaterial: entity.fabricMaterial,
      sleeveLength: entity.sleeveLength,
      neckline: entity.neckline,
      fit: entity.fit,
      silhouette: entity.silhouette,
      garmentLength: entity.garmentLength,
      size: entity.size,
      brand: entity.brand,
      confidenceScores: entity.confidenceScores,
      boundingBox: entity.boundingBox,
      processedImageRef: entity.processedImageRef,
      originalCropRef: entity.originalCropRef,
      isIncluded: entity.isIncluded,
      isApproved: entity.isApproved,
      registeredGarmentId: entity.registeredGarmentId,
      uncertaintyNotes: entity.uncertaintyNotes,
    );
  }
}


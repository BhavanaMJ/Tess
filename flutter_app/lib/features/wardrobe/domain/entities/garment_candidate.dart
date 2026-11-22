/// Represents an individually detected and segmented garment candidate awaiting user review.
class GarmentCandidate {
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

  const GarmentCandidate({
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

  String get displayImage => processedImageRef ?? originalCropRef ?? '';

  GarmentCandidate copyWith({
    String? id,
    String? jobId,
    String? suggestedName,
    String? mainCategory,
    String? subcategory,
    String? primaryColor,
    List<String>? secondaryColors,
    String? pattern,
    String? fabricMaterial,
    String? sleeveLength,
    String? neckline,
    String? fit,
    String? silhouette,
    String? garmentLength,
    String? size,
    String? brand,
    Map<String, String>? confidenceScores,
    Map<String, dynamic>? boundingBox,
    String? processedImageRef,
    String? originalCropRef,
    bool? isIncluded,
    bool? isApproved,
    String? registeredGarmentId,
    String? uncertaintyNotes,
  }) {
    return GarmentCandidate(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      suggestedName: suggestedName ?? this.suggestedName,
      mainCategory: mainCategory ?? this.mainCategory,
      subcategory: subcategory ?? this.subcategory,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColors: secondaryColors ?? this.secondaryColors,
      pattern: pattern ?? this.pattern,
      fabricMaterial: fabricMaterial ?? this.fabricMaterial,
      sleeveLength: sleeveLength ?? this.sleeveLength,
      neckline: neckline ?? this.neckline,
      fit: fit ?? this.fit,
      silhouette: silhouette ?? this.silhouette,
      garmentLength: garmentLength ?? this.garmentLength,
      size: size ?? this.size,
      brand: brand ?? this.brand,
      confidenceScores: confidenceScores ?? this.confidenceScores,
      boundingBox: boundingBox ?? this.boundingBox,
      processedImageRef: processedImageRef ?? this.processedImageRef,
      originalCropRef: originalCropRef ?? this.originalCropRef,
      isIncluded: isIncluded ?? this.isIncluded,
      isApproved: isApproved ?? this.isApproved,
      registeredGarmentId: registeredGarmentId ?? this.registeredGarmentId,
      uncertaintyNotes: uncertaintyNotes ?? this.uncertaintyNotes,
    );
  }
}


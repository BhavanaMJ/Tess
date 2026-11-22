import 'laundry_status.dart';

/// Foundational Garment Domain Entity for TESS Clothes Organizer.
/// Supports detailed metadata, multi-stage image references, and lifecycle state.
class Garment {
  final String id; // e.g. "CLO-001"
  final String userId;
  final String name;
  final String mainCategory;
  final String? subcategory;

  // Multi-tier photography references
  final String? originalImageRef;
  final String? processedImageRef;
  final String? thumbnailRef;

  // Visual & Material attributes
  final String primaryColor;
  final List<String> secondaryColors;
  final String? pattern;
  final String? fabricMaterial;
  final String? neckline;
  final String? sleeveLength; // e.g. "3/4 sleeves", "Sleeveless", "Full"
  final String? fit;
  final String? silhouette;
  final String? garmentLength;
  final String? size;
  final String? brand;

  // Metadata & Economics
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final List<String> occasions;
  final List<String> seasons;

  // Operational State
  final LaundryStatus? laundryStatus; // null if unassigned/unknown
  final bool isFavorite;
  final String? notes;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Garment({
    required this.id,
    required this.userId,
    required this.name,
    required this.mainCategory,
    this.subcategory,
    this.originalImageRef,
    this.processedImageRef,
    this.thumbnailRef,
    required this.primaryColor,
    this.secondaryColors = const [],
    this.pattern,
    this.fabricMaterial,
    this.neckline,
    this.sleeveLength,
    this.fit,
    this.silhouette,
    this.garmentLength,
    this.size,
    this.brand,
    this.purchaseDate,
    this.purchasePrice,
    this.occasions = const [],
    this.seasons = const [],
    this.laundryStatus,
    this.isFavorite = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// True if laundry status has been confirmed by user
  bool get hasConfirmedLaundryStatus => laundryStatus != null;

  /// Returns preferred display image reference (processed catalogue image first, then original)
  String? get displayImageRef => processedImageRef ?? thumbnailRef ?? originalImageRef;

  Garment copyWith({
    String? id,
    String? userId,
    String? name,
    String? mainCategory,
    String? subcategory,
    String? originalImageRef,
    String? processedImageRef,
    String? thumbnailRef,
    String? primaryColor,
    List<String>? secondaryColors,
    String? pattern,
    String? fabricMaterial,
    String? neckline,
    String? sleeveLength,
    String? fit,
    String? silhouette,
    String? garmentLength,
    String? size,
    String? brand,
    DateTime? purchaseDate,
    double? purchasePrice,
    List<String>? occasions,
    List<String>? seasons,
    LaundryStatus? laundryStatus,
    bool? isFavorite,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Garment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      mainCategory: mainCategory ?? this.mainCategory,
      subcategory: subcategory ?? this.subcategory,
      originalImageRef: originalImageRef ?? this.originalImageRef,
      processedImageRef: processedImageRef ?? this.processedImageRef,
      thumbnailRef: thumbnailRef ?? this.thumbnailRef,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColors: secondaryColors ?? this.secondaryColors,
      pattern: pattern ?? this.pattern,
      fabricMaterial: fabricMaterial ?? this.fabricMaterial,
      neckline: neckline ?? this.neckline,
      sleeveLength: sleeveLength ?? this.sleeveLength,
      fit: fit ?? this.fit,
      silhouette: silhouette ?? this.silhouette,
      garmentLength: garmentLength ?? this.garmentLength,
      size: size ?? this.size,
      brand: brand ?? this.brand,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      occasions: occasions ?? this.occasions,
      seasons: seasons ?? this.seasons,
      laundryStatus: laundryStatus ?? this.laundryStatus,
      isFavorite: isFavorite ?? this.isFavorite,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


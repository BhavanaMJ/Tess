import '../../domain/entities/garment.dart';
import '../../domain/entities/laundry_status.dart';

/// Data Transfer Object and Model for Garment Entity.
/// Matches FastAPI snake_case JSON schema and PostgreSQL table definitions.
class GarmentModel {
  final String id;
  final String userId;
  final String name;
  final String mainCategory;
  final String? subcategory;
  final String? originalImageRef;
  final String? processedImageRef;
  final String? thumbnailRef;
  final String primaryColor;
  final List<String> secondaryColors;
  final String? pattern;
  final String? fabricMaterial;
  final String? neckline;
  final String? sleeveLength;
  final String? fit;
  final String? silhouette;
  final String? garmentLength;
  final String? size;
  final String? brand;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final List<String> occasions;
  final List<String> seasons;
  final String? laundryStatus; // Raw string: 'CLEAN', 'WORN', etc. or null
  final bool isFavorite;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GarmentModel({
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

  factory GarmentModel.fromJson(Map<String, dynamic> json) {
    return GarmentModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Garment',
      mainCategory: json['main_category'] as String? ?? 'Tops',
      subcategory: json['subcategory'] as String?,
      originalImageRef: json['original_image_ref'] as String?,
      processedImageRef: json['processed_image_ref'] as String?,
      thumbnailRef: json['thumbnail_ref'] as String?,
      primaryColor: json['primary_color'] as String? ?? 'Unknown',
      secondaryColors: (json['secondary_colors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      pattern: json['pattern'] as String?,
      fabricMaterial: json['fabric_material'] as String?,
      neckline: json['neckline'] as String?,
      sleeveLength: json['sleeve_length'] as String?,
      fit: json['fit'] as String?,
      silhouette: json['silhouette'] as String?,
      garmentLength: json['garment_length'] as String?,
      size: json['size'] as String?,
      brand: json['brand'] as String?,
      purchaseDate: json['purchase_date'] != null
          ? DateTime.tryParse(json['purchase_date'].toString())
          : null,
      purchasePrice: (json['purchase_price'] as num?)?.toDouble(),
      occasions: (json['occasions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      seasons: (json['seasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      laundryStatus: json['laundry_status'] as String?,
      isFavorite: json['is_favorite'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'main_category': mainCategory,
      'subcategory': subcategory,
      'original_image_ref': originalImageRef,
      'processed_image_ref': processedImageRef,
      'thumbnail_ref': thumbnailRef,
      'primary_color': primaryColor,
      'secondary_colors': secondaryColors,
      'pattern': pattern,
      'fabric_material': fabricMaterial,
      'neckline': neckline,
      'sleeve_length': sleeveLength,
      'fit': fit,
      'silhouette': silhouette,
      'garment_length': garmentLength,
      'size': size,
      'brand': brand,
      'purchase_date': purchaseDate?.toIso8601String(),
      'purchase_price': purchasePrice,
      'occasions': occasions,
      'seasons': seasons,
      'laundry_status': laundryStatus,
      'is_favorite': isFavorite,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Converts this DTO to domain entity
  Garment toDomain() {
    return Garment(
      id: id,
      userId: userId,
      name: name,
      mainCategory: mainCategory,
      subcategory: subcategory,
      originalImageRef: originalImageRef,
      processedImageRef: processedImageRef,
      thumbnailRef: thumbnailRef,
      primaryColor: primaryColor,
      secondaryColors: secondaryColors,
      pattern: pattern,
      fabricMaterial: fabricMaterial,
      neckline: neckline,
      sleeveLength: sleeveLength,
      fit: fit,
      silhouette: silhouette,
      garmentLength: garmentLength,
      size: size,
      brand: brand,
      purchaseDate: purchaseDate,
      purchasePrice: purchasePrice,
      occasions: occasions,
      seasons: seasons,
      laundryStatus: LaundryStatus.fromString(laundryStatus),
      isFavorite: isFavorite,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Creates a model from domain entity
  factory GarmentModel.fromDomain(Garment garment) {
    return GarmentModel(
      id: garment.id,
      userId: garment.userId,
      name: garment.name,
      mainCategory: garment.mainCategory,
      subcategory: garment.subcategory,
      originalImageRef: garment.originalImageRef,
      processedImageRef: garment.processedImageRef,
      thumbnailRef: garment.thumbnailRef,
      primaryColor: garment.primaryColor,
      secondaryColors: garment.secondaryColors,
      pattern: garment.pattern,
      fabricMaterial: garment.fabricMaterial,
      neckline: garment.neckline,
      sleeveLength: garment.sleeveLength,
      fit: garment.fit,
      silhouette: garment.silhouette,
      garmentLength: garment.garmentLength,
      size: garment.size,
      brand: garment.brand,
      purchaseDate: garment.purchaseDate,
      purchasePrice: garment.purchasePrice,
      occasions: garment.occasions,
      seasons: garment.seasons,
      laundryStatus: garment.laundryStatus?.value,
      isFavorite: garment.isFavorite,
      notes: garment.notes,
      createdAt: garment.createdAt,
      updatedAt: garment.updatedAt,
    );
  }
}

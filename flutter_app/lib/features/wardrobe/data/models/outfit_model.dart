import '../../domain/entities/laundry_status.dart';
import '../../domain/entities/outfit.dart';
import '../../domain/entities/outfit_item.dart';

class OutfitItemModel {
  final String garmentId;
  final String name;
  final String mainCategory;
  final String primaryColor;
  final List<String> secondaryColors;
  final String? pattern;
  final String? originalImageRef;
  final String? processedImageRef;
  final String? thumbnailRef;
  final String? laundryStatus;
  final bool isEligible;
  final String? unavailabilityReason;

  const OutfitItemModel({
    required this.garmentId,
    required this.name,
    required this.mainCategory,
    required this.primaryColor,
    this.secondaryColors = const [],
    this.pattern,
    this.originalImageRef,
    this.processedImageRef,
    this.thumbnailRef,
    this.laundryStatus,
    this.isEligible = true,
    this.unavailabilityReason,
  });

  factory OutfitItemModel.fromJson(Map<String, dynamic> json) {
    return OutfitItemModel(
      garmentId: json['garment_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Garment',
      mainCategory: json['main_category'] as String? ?? 'Tops',
      primaryColor: json['primary_color'] as String? ?? 'Unknown',
      secondaryColors: (json['secondary_colors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      pattern: json['pattern'] as String?,
      originalImageRef: json['original_image_ref'] as String?,
      processedImageRef: json['processed_image_ref'] as String?,
      thumbnailRef: json['thumbnail_ref'] as String?,
      laundryStatus: json['laundry_status'] as String?,
      isEligible: json['is_eligible'] as bool? ?? true,
      unavailabilityReason: json['unavailability_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'garment_id': garmentId,
      'name': name,
      'main_category': mainCategory,
      'primary_color': primaryColor,
      'secondary_colors': secondaryColors,
      'pattern': pattern,
      'original_image_ref': originalImageRef,
      'processed_image_ref': processedImageRef,
      'thumbnail_ref': thumbnailRef,
      'laundry_status': laundryStatus,
      'is_eligible': isEligible,
      'unavailability_reason': unavailabilityReason,
    };
  }

  OutfitItem toDomain() {
    LaundryStatus? ls;
    if (laundryStatus != null) {
      try {
        ls = LaundryStatus.values.firstWhere(
          (e) => e.value.toUpperCase() == laundryStatus!.toUpperCase(),
        );
      } catch (_) {
        ls = null;
      }
    }
    return OutfitItem(
      garmentId: garmentId,
      name: name,
      mainCategory: mainCategory,
      primaryColor: primaryColor,
      secondaryColors: secondaryColors,
      pattern: pattern,
      originalImageRef: originalImageRef,
      processedImageRef: processedImageRef,
      thumbnailRef: thumbnailRef,
      laundryStatus: ls,
      isEligible: isEligible,
      unavailabilityReason: unavailabilityReason,
    );
  }
}

class OutfitModel {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String occasion;
  final String? notes;
  final bool isFavourite;
  final String creationSource;
  final String? stylingExplanation;
  final int wearCount;
  final String? lastWornDate;
  final List<OutfitItemModel> items;
  final List<String> garmentIds;
  final bool isAvailable;
  final List<String> unavailableReasons;
  final String createdAt;
  final String updatedAt;

  const OutfitModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.occasion,
    this.notes,
    this.isFavourite = false,
    this.creationSource = 'MANUAL',
    this.stylingExplanation,
    this.wearCount = 0,
    this.lastWornDate,
    this.items = const [],
    this.garmentIds = const [],
    this.isAvailable = true,
    this.unavailableReasons = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory OutfitModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((e) => OutfitItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final rawGids = json['garment_ids'] as List<dynamic>? ?? [];
    final gidsList = rawGids.map((e) => e.toString()).toList();
    final rawUnavail = json['unavailable_reasons'] as List<dynamic>? ?? [];
    final unavailList = rawUnavail.map((e) => e.toString()).toList();

    return OutfitModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Look',
      description: json['description'] as String?,
      occasion: json['occasion'] as String? ?? 'Casual',
      notes: json['notes'] as String?,
      isFavourite: json['is_favourite'] as bool? ?? false,
      creationSource: json['creation_source'] as String? ?? 'MANUAL',
      stylingExplanation: json['styling_explanation'] as String?,
      wearCount: json['wear_count'] as int? ?? 0,
      lastWornDate: json['last_worn_date'] as String?,
      items: itemsList,
      garmentIds: gidsList,
      isAvailable: json['is_available'] as bool? ?? true,
      unavailableReasons: unavailList,
      createdAt:
          json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt:
          json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'occasion': occasion,
      'notes': notes,
      'is_favourite': isFavourite,
      'creation_source': creationSource,
      'styling_explanation': stylingExplanation,
      'wear_count': wearCount,
      'last_worn_date': lastWornDate,
      'items': items.map((e) => e.toJson()).toList(),
      'garment_ids': garmentIds,
      'is_available': isAvailable,
      'unavailable_reasons': unavailableReasons,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Outfit toDomain() {
    return Outfit(
      id: id,
      userId: userId,
      name: name,
      description: description,
      occasion: occasion,
      notes: notes,
      isFavourite: isFavourite,
      creationSource: OutfitSource.fromString(creationSource),
      stylingExplanation: stylingExplanation,
      wearCount: wearCount,
      lastWornDate:
          lastWornDate != null ? DateTime.tryParse(lastWornDate!) : null,
      items: items.map((e) => e.toDomain()).toList(),
      garmentIds: garmentIds,
      isAvailable: isAvailable,
      unavailableReasons: unavailableReasons,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now(),
    );
  }
}

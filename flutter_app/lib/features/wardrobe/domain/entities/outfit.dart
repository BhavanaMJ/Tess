import 'outfit_item.dart';

enum OutfitSource {
  automatic,
  guided,
  manual;

  String get value {
    switch (this) {
      case OutfitSource.automatic:
        return 'AUTOMATIC';
      case OutfitSource.guided:
        return 'GUIDED';
      case OutfitSource.manual:
        return 'MANUAL';
    }
  }

  static OutfitSource fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'AUTOMATIC':
        return OutfitSource.automatic;
      case 'GUIDED':
        return OutfitSource.guided;
      default:
        return OutfitSource.manual;
    }
  }
}

/// Domain Entity representing a complete Outfit in the TESS Digital Lookbook.
class Outfit {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String occasion;
  final String? notes;
  final bool isFavourite;
  final OutfitSource creationSource;
  final String? stylingExplanation;
  final int wearCount;
  final DateTime? lastWornDate;
  final List<OutfitItem> items;
  final List<String> garmentIds;
  final bool isAvailable;
  final List<String> unavailableReasons;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Outfit({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.occasion,
    this.notes,
    this.isFavourite = false,
    this.creationSource = OutfitSource.manual,
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

  Outfit copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? occasion,
    String? notes,
    bool? isFavourite,
    OutfitSource? creationSource,
    String? stylingExplanation,
    int? wearCount,
    DateTime? lastWornDate,
    List<OutfitItem>? items,
    List<String>? garmentIds,
    bool? isAvailable,
    List<String>? unavailableReasons,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Outfit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      occasion: occasion ?? this.occasion,
      notes: notes ?? this.notes,
      isFavourite: isFavourite ?? this.isFavourite,
      creationSource: creationSource ?? this.creationSource,
      stylingExplanation: stylingExplanation ?? this.stylingExplanation,
      wearCount: wearCount ?? this.wearCount,
      lastWornDate: lastWornDate ?? this.lastWornDate,
      items: items ?? this.items,
      garmentIds: garmentIds ?? this.garmentIds,
      isAvailable: isAvailable ?? this.isAvailable,
      unavailableReasons: unavailableReasons ?? this.unavailableReasons,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


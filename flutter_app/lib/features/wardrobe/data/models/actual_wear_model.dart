import '../../domain/entities/actual_wear_record.dart';
import '../../domain/entities/outfit.dart';
import 'outfit_model.dart';

class ActualWearModel extends ActualWearRecord {
  const ActualWearModel({
    required super.id,
    required super.userId,
    required super.outfitId,
    required super.outfitName,
    required super.outfit,
    super.planId,
    required super.actualWornDate,
    required super.wornAt,
    super.garmentsUpdated = const [],
    super.wearCount = 1,
    super.notes,
    required super.createdAt,
  });

  factory ActualWearModel.fromJson(Map<String, dynamic> json) {
    return ActualWearModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      outfitId: json['outfit_id'] as String? ?? '',
      outfitName: json['outfit_name'] as String? ?? 'Worn Outfit',
      outfit: json['outfit'] != null
          ? OutfitModel.fromJson(json['outfit'] as Map<String, dynamic>).toDomain()
          : Outfit(
              id: json['outfit_id'] as String? ?? '',
              userId: json['user_id'] as String? ?? '',
              name: json['outfit_name'] as String? ?? 'Outfit',
              occasion: 'Casual',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
      planId: json['plan_id'] as String?,
      actualWornDate: json['actual_worn_date'] as String? ?? '',
      wornAt: json['worn_at'] != null
          ? DateTime.tryParse(json['worn_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      garmentsUpdated: (json['garments_updated'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      wearCount: json['wear_count'] as int? ?? 1,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'outfit_id': outfitId,
      'outfit_name': outfitName,
      'plan_id': planId,
      'actual_worn_date': actualWornDate,
      'worn_at': wornAt.toIso8601String(),
      'garments_updated': garmentsUpdated,
      'wear_count': wearCount,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

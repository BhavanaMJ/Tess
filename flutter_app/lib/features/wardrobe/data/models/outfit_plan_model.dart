import '../../domain/entities/outfit.dart';
import '../../domain/entities/outfit_plan.dart';
import 'outfit_model.dart';

class OutfitPlanModel extends OutfitPlan {
  const OutfitPlanModel({
    required super.id,
    required super.userId,
    required super.outfitId,
    required super.outfitName,
    required super.outfit,
    required super.plannedDate,
    required super.occasion,
    super.notes,
    super.isWorn = false,
    super.isAvailable = true,
    super.repetitionWarning,
    required super.createdAt,
    required super.updatedAt,
  });

  factory OutfitPlanModel.fromJson(Map<String, dynamic> json) {
    return OutfitPlanModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      outfitId: json['outfit_id'] as String? ?? '',
      outfitName: json['outfit_name'] as String? ?? 'Planned Outfit',
      outfit: json['outfit'] != null
          ? OutfitModel.fromJson(json['outfit'] as Map<String, dynamic>).toDomain()
          : Outfit(
              id: json['outfit_id'] as String? ?? '',
              userId: json['user_id'] as String? ?? '',
              name: json['outfit_name'] as String? ?? 'Outfit',
              occasion: json['occasion'] as String? ?? 'Casual',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
      plannedDate: json['planned_date'] as String? ?? '',
      occasion: json['occasion'] as String? ?? 'Casual',
      notes: json['notes'] as String?,
      isWorn: json['is_worn'] as bool? ?? false,
      isAvailable: json['is_available'] as bool? ?? true,
      repetitionWarning: json['repetition_warning'] as String?,
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
      'outfit_id': outfitId,
      'outfit_name': outfitName,
      'planned_date': plannedDate,
      'occasion': occasion,
      'notes': notes,
      'is_worn': isWorn,
      'is_available': isAvailable,
      'repetition_warning': repetitionWarning,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

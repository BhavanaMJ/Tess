import 'outfit.dart';

class OutfitPlan {
  final String id;
  final String userId;
  final String outfitId;
  final String outfitName;
  final Outfit outfit;
  final String plannedDate; // YYYY-MM-DD
  final String occasion;
  final String? notes;
  final bool isWorn;
  final bool isAvailable;
  final String? repetitionWarning;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OutfitPlan({
    required this.id,
    required this.userId,
    required this.outfitId,
    required this.outfitName,
    required this.outfit,
    required this.plannedDate,
    required this.occasion,
    this.notes,
    this.isWorn = false,
    this.isAvailable = true,
    this.repetitionWarning,
    required this.createdAt,
    required this.updatedAt,
  });

  OutfitPlan copyWith({
    String? id,
    String? userId,
    String? outfitId,
    String? outfitName,
    Outfit? outfit,
    String? plannedDate,
    String? occasion,
    String? notes,
    bool? isWorn,
    bool? isAvailable,
    String? repetitionWarning,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OutfitPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      outfitId: outfitId ?? this.outfitId,
      outfitName: outfitName ?? this.outfitName,
      outfit: outfit ?? this.outfit,
      plannedDate: plannedDate ?? this.plannedDate,
      occasion: occasion ?? this.occasion,
      notes: notes ?? this.notes,
      isWorn: isWorn ?? this.isWorn,
      isAvailable: isAvailable ?? this.isAvailable,
      repetitionWarning: repetitionWarning ?? this.repetitionWarning,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


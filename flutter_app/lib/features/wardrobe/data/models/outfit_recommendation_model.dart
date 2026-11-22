import '../../domain/entities/outfit_recommendation.dart';
import 'outfit_model.dart';

class OutfitRecommendationModel {
  final String id;
  final String name;
  final String occasion;
  final List<OutfitItemModel> garments;
  final List<String> garmentIds;
  final String explanation;
  final bool isAvailable;
  final String combinationFingerprint;

  const OutfitRecommendationModel({
    required this.id,
    required this.name,
    required this.occasion,
    required this.garments,
    required this.garmentIds,
    required this.explanation,
    this.isAvailable = true,
    required this.combinationFingerprint,
  });

  factory OutfitRecommendationModel.fromJson(Map<String, dynamic> json) {
    final rawGarments = json['garments'] as List<dynamic>? ?? [];
    final garmentsList = rawGarments
        .map((e) => OutfitItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final rawGids = json['garment_ids'] as List<dynamic>? ?? [];
    final gidsList = rawGids.map((e) => e.toString()).toList();

    return OutfitRecommendationModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Curated Outfit',
      occasion: json['occasion'] as String? ?? 'Casual',
      garments: garmentsList,
      garmentIds: gidsList,
      explanation: json['explanation'] as String? ?? '',
      isAvailable: json['is_available'] as bool? ?? true,
      combinationFingerprint: json['combination_fingerprint'] as String? ?? '',
    );
  }

  OutfitRecommendation toDomain() {
    return OutfitRecommendation(
      id: id,
      name: name,
      occasion: occasion,
      garments: garments.map((e) => e.toDomain()).toList(),
      garmentIds: garmentIds,
      explanation: explanation,
      isAvailable: isAvailable,
      combinationFingerprint: combinationFingerprint,
    );
  }
}

import 'outfit_item.dart';

/// Represents an AI or heuristic styling suggestion with explanations and availability.
class OutfitRecommendation {
  final String id;
  final String name;
  final String occasion;
  final List<OutfitItem> garments;
  final List<String> garmentIds;
  final String explanation;
  final bool isAvailable;
  final String combinationFingerprint;

  const OutfitRecommendation({
    required this.id,
    required this.name,
    required this.occasion,
    required this.garments,
    required this.garmentIds,
    required this.explanation,
    this.isAvailable = true,
    required this.combinationFingerprint,
  });
}


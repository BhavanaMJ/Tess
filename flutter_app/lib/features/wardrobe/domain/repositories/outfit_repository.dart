import '../entities/outfit.dart';
import '../entities/outfit_recommendation.dart';

abstract class OutfitRepository {
  Future<List<Outfit>> getOutfits({
    String? occasion,
    bool favouriteOnly = false,
    String? search,
  });

  Future<Outfit> getOutfit(String id);

  Future<Outfit> createOutfit({
    required String name,
    String? description,
    required String occasion,
    String? notes,
    bool isFavourite = false,
    OutfitSource creationSource = OutfitSource.manual,
    String? stylingExplanation,
    required List<String> garmentIds,
  });

  Future<Outfit> updateOutfit(
    String id, {
    String? name,
    String? description,
    String? occasion,
    String? notes,
    bool? isFavourite,
    String? stylingExplanation,
    List<String>? garmentIds,
  });

  Future<void> deleteOutfit(String id);

  Future<List<OutfitRecommendation>> generateRecommendations({
    String? occasion,
    bool excludeWorn = true,
    String? colorPalette,
    String? comfortPreference,
    bool favoritesOnly = false,
    int limit = 5,
  });

  Future<List<OutfitRecommendation>> generateGuidedStyling(
    String seedGarmentId, {
    String? occasion,
    bool excludeWorn = true,
    int limit = 3,
  });

  Future<Map<String, dynamic>> validateOutfit(List<String> garmentIds);

  Future<Map<String, dynamic>> wearOutfit(
    String id, {
    String? notes,
    String? idempotencyKey,
  });
}

import '../entities/insights_period.dart';
import '../entities/wardrobe_insights.dart';
import '../entities/cost_per_wear.dart';
import '../entities/capsule_insight.dart';
import '../entities/style_memory.dart';

/// Domain Repository contract for Wardrobe Insights and Style Intelligence.
abstract class InsightsRepository {
  Future<WardrobeOverview> getOverview({
    AnalyticsPeriod period = AnalyticsPeriod.days30,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<CategoryDistribution>> getCategoryDistribution();

  Future<List<GarmentUsage>> getMostWorn({
    AnalyticsPeriod period = AnalyticsPeriod.allTime,
    int limit = 5,
  });

  Future<List<GarmentUsage>> getLeastWorn({
    AnalyticsPeriod period = AnalyticsPeriod.allTime,
    int limit = 5,
  });

  Future<List<GarmentUsage>> getNeglected({
    int thresholdDays = 60,
    int limit = 10,
  });

  Future<List<ColourDistribution>> getColourAnalysis();

  Future<List<CategoryUsage>> getCategoryUsage({
    AnalyticsPeriod period = AnalyticsPeriod.days30,
  });

  Future<List<OutfitRepetition>> getOutfitRepetition({
    int limit = 10,
  });

  Future<CostPerWearSummary> getCostPerWear();

  Future<List<WardrobeRecommendation>> getRecommendations();

  Future<CapsuleWardrobeSummary> getCapsuleIntelligence();

  Future<StyleMemory> getStyleMemory();

  Future<StyleMemory> updateStyleMemory({
    String? stylePersona,
    List<String>? preferredColors,
    List<String>? preferredCategories,
    List<String>? preferredOccasions,
    String? notes,
  });
}

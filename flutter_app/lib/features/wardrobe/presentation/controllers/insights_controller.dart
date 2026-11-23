import 'package:flutter/foundation.dart';
import '../../domain/entities/insights_period.dart';
import '../../domain/entities/wardrobe_insights.dart';
import '../../domain/entities/cost_per_wear.dart';
import '../../domain/entities/capsule_insight.dart';
import '../../domain/entities/style_memory.dart';
import '../../domain/repositories/insights_repository.dart';

class InsightsController extends ChangeNotifier {
  final InsightsRepository _repository;

  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.days30;
  bool _isLoading = false;
  String? _errorMessage;

  WardrobeOverview? _overview;
  List<CategoryDistribution> _categoryDistribution = [];
  List<GarmentUsage> _mostWorn = [];
  List<GarmentUsage> _leastWorn = [];
  List<GarmentUsage> _neglected = [];
  List<ColourDistribution> _colourDistribution = [];
  List<CategoryUsage> _categoryUsage = [];
  List<OutfitRepetition> _outfitRepetition = [];
  CostPerWearSummary? _costPerWearSummary;
  List<WardrobeRecommendation> _recommendations = [];
  CapsuleWardrobeSummary? _capsuleSummary;
  StyleMemory? _styleMemory;

  InsightsController({required InsightsRepository repository})
      : _repository = repository;

  // Getters
  AnalyticsPeriod get selectedPeriod => _selectedPeriod;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  WardrobeOverview? get overview => _overview;
  List<CategoryDistribution> get categoryDistribution => _categoryDistribution;
  List<GarmentUsage> get mostWorn => _mostWorn;
  List<GarmentUsage> get leastWorn => _leastWorn;
  List<GarmentUsage> get neglected => _neglected;
  List<ColourDistribution> get colourDistribution => _colourDistribution;
  List<CategoryUsage> get categoryUsage => _categoryUsage;
  List<OutfitRepetition> get outfitRepetition => _outfitRepetition;
  CostPerWearSummary? get costPerWearSummary => _costPerWearSummary;
  List<WardrobeRecommendation> get recommendations => _recommendations;
  CapsuleWardrobeSummary? get capsuleSummary => _capsuleSummary;
  StyleMemory? get styleMemory => _styleMemory;

  /// Loads full dashboard analytics for the current period.
  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getOverview(period: _selectedPeriod),
        _repository.getCategoryDistribution(),
        _repository.getMostWorn(period: _selectedPeriod, limit: 5),
        _repository.getLeastWorn(period: _selectedPeriod, limit: 5),
        _repository.getNeglected(thresholdDays: 60, limit: 6),
        _repository.getColourAnalysis(),
        _repository.getRecommendations(),
        _repository.getCapsuleIntelligence(),
        _repository.getStyleMemory(),
      ]);

      _overview = results[0] as WardrobeOverview;
      _categoryDistribution = results[1] as List<CategoryDistribution>;
      _mostWorn = results[2] as List<GarmentUsage>;
      _leastWorn = results[3] as List<GarmentUsage>;
      _neglected = results[4] as List<GarmentUsage>;
      _colourDistribution = results[5] as List<ColourDistribution>;
      _recommendations = results[6] as List<WardrobeRecommendation>;
      _capsuleSummary = results[7] as CapsuleWardrobeSummary;
      _styleMemory = results[8] as StyleMemory;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load insights: $e';
      notifyListeners();
    }
  }

  /// Changes the time window filter and reloads period-dependent analytics.
  Future<void> selectPeriod(AnalyticsPeriod period) async {
    if (_selectedPeriod == period && _overview != null) return;
    _selectedPeriod = period;
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getOverview(period: _selectedPeriod),
        _repository.getMostWorn(period: _selectedPeriod, limit: 5),
        _repository.getLeastWorn(period: _selectedPeriod, limit: 5),
        _repository.getCategoryUsage(period: _selectedPeriod),
      ]);

      _overview = results[0] as WardrobeOverview;
      _mostWorn = results[1] as List<GarmentUsage>;
      _leastWorn = results[2] as List<GarmentUsage>;
      _categoryUsage = results[3] as List<CategoryUsage>;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to switch period: $e';
      notifyListeners();
    }
  }

  /// Loads detailed Cost-Per-Wear analytics for the dedicated screen.
  Future<void> loadCostPerWear() async {
    _isLoading = true;
    notifyListeners();
    try {
      _costPerWearSummary = await _repository.getCostPerWear();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load cost-per-wear: $e';
      notifyListeners();
    }
  }

  /// Loads outfit repetition breakdown.
  Future<void> loadOutfitRepetition() async {
    _isLoading = true;
    notifyListeners();
    try {
      _outfitRepetition = await _repository.getOutfitRepetition();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load outfit repetitions: $e';
      notifyListeners();
    }
  }

  /// Updates personal style persona and memory.
  Future<bool> updateStyleMemory({
    String? stylePersona,
    List<String>? preferredColors,
    List<String>? preferredCategories,
    List<String>? preferredOccasions,
    String? notes,
  }) async {
    try {
      _styleMemory = await _repository.updateStyleMemory(
        stylePersona: stylePersona,
        preferredColors: preferredColors,
        preferredCategories: preferredCategories,
        preferredOccasions: preferredOccasions,
        notes: notes,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update style memory: $e';
      notifyListeners();
      return false;
    }
  }
}

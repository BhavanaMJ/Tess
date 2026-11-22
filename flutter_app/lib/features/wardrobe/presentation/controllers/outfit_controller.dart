import 'package:flutter/foundation.dart';
import '../../domain/entities/outfit.dart';
import '../../domain/entities/outfit_recommendation.dart';
import '../../domain/repositories/outfit_repository.dart';

class OutfitController extends ChangeNotifier {
  final OutfitRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;

  List<Outfit> _savedOutfits = [];
  List<OutfitRecommendation> _recommendations = [];
  List<OutfitRecommendation> _guidedRecommendations = [];

  String? _selectedSeedGarmentId;
  String _selectedOccasion = 'Casual';
  bool _excludeWorn = true;
  bool _favoritesOnly = false;
  String? _searchQuery;

  // Manual builder state
  final List<String> _manualSelectedGarmentIds = [];
  Map<String, dynamic>? _manualValidationResult;

  OutfitController({required OutfitRepository repository})
      : _repository = repository;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Outfit> get savedOutfits => _savedOutfits;
  List<OutfitRecommendation> get recommendations => _recommendations;
  List<OutfitRecommendation> get guidedRecommendations =>
      _guidedRecommendations;
  String? get selectedSeedGarmentId => _selectedSeedGarmentId;
  String get selectedOccasion => _selectedOccasion;
  bool get excludeWorn => _excludeWorn;
  bool get favoritesOnly => _favoritesOnly;
  String? get searchQuery => _searchQuery;
  List<String> get manualSelectedGarmentIds => _manualSelectedGarmentIds;
  Map<String, dynamic>? get manualValidationResult => _manualValidationResult;

  void setOccasion(String occasion) {
    _selectedOccasion = occasion;
    notifyListeners();
  }

  void setExcludeWorn(bool val) {
    _excludeWorn = val;
    notifyListeners();
  }

  void setFavoritesOnly(bool val) {
    _favoritesOnly = val;
    notifyListeners();
  }

  void setSearchQuery(String? q) {
    _searchQuery = q;
    loadSavedOutfits();
  }

  void setSeedGarmentId(String? gid) {
    _selectedSeedGarmentId = gid;
    _guidedRecommendations = [];
    notifyListeners();
  }

  // --- 1. LOAD SAVED OUTFITS ---
  Future<void> loadSavedOutfits({String? occasion, bool? favOnly}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _savedOutfits = await _repository.getOutfits(
        occasion:
            occasion ?? (_selectedOccasion == 'All' ? null : _selectedOccasion),
        favouriteOnly: favOnly ?? _favoritesOnly,
        search: _searchQuery,
      );
    } catch (e) {
      _errorMessage = 'Failed to load saved outfits: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- 2. GENERATE AUTOMATIC RECOMMENDATIONS ---
  Future<void> generateRecommendations({String? occasion}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final occ =
        occasion ?? (_selectedOccasion == 'All' ? 'Casual' : _selectedOccasion);
    try {
      _recommendations = await _repository.generateRecommendations(
        occasion: occ,
        excludeWorn: _excludeWorn,
        favoritesOnly: _favoritesOnly,
        limit: 5,
      );
    } catch (e) {
      _errorMessage = 'Stylist encountered an error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- 3. GENERATE GUIDED STYLING ---
  Future<void> generateGuidedStyling(String seedGarmentId,
      {String? occasion}) async {
    _selectedSeedGarmentId = seedGarmentId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final occ =
        occasion ?? (_selectedOccasion == 'All' ? 'Casual' : _selectedOccasion);
    try {
      _guidedRecommendations = await _repository.generateGuidedStyling(
        seedGarmentId,
        occasion: occ,
        excludeWorn: _excludeWorn,
        limit: 3,
      );
    } catch (e) {
      _errorMessage = 'Failed to style garment: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- 4. MANUAL BUILDER HELPERS ---
  void toggleGarmentSelection(String garmentId) {
    if (_manualSelectedGarmentIds.contains(garmentId)) {
      _manualSelectedGarmentIds.remove(garmentId);
    } else {
      _manualSelectedGarmentIds.add(garmentId);
    }
    validateManualSelection();
  }

  void clearManualSelection() {
    _manualSelectedGarmentIds.clear();
    _manualValidationResult = null;
    notifyListeners();
  }

  Future<void> validateManualSelection() async {
    if (_manualSelectedGarmentIds.isEmpty) {
      _manualValidationResult = null;
      notifyListeners();
      return;
    }
    try {
      _manualValidationResult =
          await _repository.validateOutfit(_manualSelectedGarmentIds);
    } catch (e) {
      _manualValidationResult = {
        'is_valid': true,
        'is_wearable': true,
        'conflicts': <String>[],
      };
    }
    notifyListeners();
  }

  // --- 5. SAVE OUTFIT ---
  Future<Outfit?> saveOutfit({
    required String name,
    String? description,
    required String occasion,
    String? notes,
    bool isFavourite = false,
    OutfitSource creationSource = OutfitSource.manual,
    String? stylingExplanation,
    required List<String> garmentIds,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final saved = await _repository.createOutfit(
        name: name,
        description: description,
        occasion: occasion,
        notes: notes,
        isFavourite: isFavourite,
        creationSource: creationSource,
        stylingExplanation: stylingExplanation,
        garmentIds: garmentIds,
      );
      _savedOutfits.insert(0, saved);
      return saved;
    } catch (e) {
      _errorMessage = 'Failed to save outfit: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- 6. UPDATE OUTFIT ---
  Future<Outfit?> updateOutfit(
    String id, {
    String? name,
    String? description,
    String? occasion,
    String? notes,
    bool? isFavourite,
    String? stylingExplanation,
    List<String>? garmentIds,
  }) async {
    try {
      final updated = await _repository.updateOutfit(
        id,
        name: name,
        description: description,
        occasion: occasion,
        notes: notes,
        isFavourite: isFavourite,
        stylingExplanation: stylingExplanation,
        garmentIds: garmentIds,
      );
      final idx = _savedOutfits.indexWhere((o) => o.id == id);
      if (idx != -1) {
        _savedOutfits[idx] = updated;
        notifyListeners();
      }
      return updated;
    } catch (e) {
      _errorMessage = 'Failed to update outfit: $e';
      notifyListeners();
      return null;
    }
  }

  // --- 7. TOGGLE FAVOURITE ---
  Future<void> toggleFavourite(Outfit outfit) async {
    final nextFav = !outfit.isFavourite;
    await updateOutfit(outfit.id, isFavourite: nextFav);
  }

  // --- 8. DELETE OUTFIT ---
  Future<bool> deleteOutfit(String id) async {
    try {
      await _repository.deleteOutfit(id);
      _savedOutfits.removeWhere((o) => o.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete outfit: $e';
      notifyListeners();
      return false;
    }
  }

  // --- 9. WEAR THIS OUTFIT (PHASE 4 LAUNDRY INTEGRATION) ---
  Future<bool> wearOutfit(String id,
      {String? notes, String? idempotencyKey}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.wearOutfit(
        id,
        notes: notes,
        idempotencyKey: idempotencyKey,
      );
      // Reload outfit list so wear_count and live garment laundry statuses update
      await loadSavedOutfits();
      return true;
    } catch (e) {
      _errorMessage = 'Cannot wear outfit: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

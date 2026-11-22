import 'package:flutter/material.dart';
import '../../data/fixtures/initial_inventory.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/garment.dart';
import '../../domain/entities/laundry_status.dart';
import '../../domain/repositories/wardrobe_repository.dart';

/// Presentation Controller for Clothes Organizer state.
/// Exposes reactive state to widgets via ChangeNotifier.
class WardrobeController extends ChangeNotifier {
  final WardrobeRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  List<Garment> _garments = [];
  List<WardrobeCategory> _categories = [];
  String? _selectedCategory;
  LaundryStatus? _selectedLaundryStatus;

  WardrobeController({required WardrobeRepository repository})
      : _repository = repository;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Garment> get garments => _garments;
  List<WardrobeCategory> get categories => _categories;
  String? get selectedCategory => _selectedCategory;
  LaundryStatus? get selectedLaundryStatus => _selectedLaundryStatus;

  // Filtered view
  List<Garment> get filteredGarments {
    return _garments.where((g) {
      if (_selectedCategory != null &&
          g.mainCategory.toLowerCase() != _selectedCategory!.toLowerCase()) {
        return false;
      }
      if (_selectedLaundryStatus != null &&
          g.laundryStatus != _selectedLaundryStatus) {
        return false;
      }
      return true;
    }).toList();
  }

  // Metrics
  int get totalGarmentsCount => _garments.length;
  int get cleanCount => _garments.where((g) => g.laundryStatus == LaundryStatus.clean).length;
  int get wornCount => _garments.where((g) => g.laundryStatus == LaundryStatus.worn).length;
  int get inLaundryCount => _garments.where((g) =>
      g.laundryStatus == LaundryStatus.washing ||
      g.laundryStatus == LaundryStatus.drying).length;
  int get unassignedCount => _garments.where((g) => g.laundryStatus == null).length;

  Future<void> loadInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getCategories(),
        _repository.getGarments(),
      ]);

      _categories = results[0] as List<WardrobeCategory>;
      _garments = results[1] as List<Garment>;
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    if (_selectedCategory == category) {
      _selectedCategory = null;
    } else {
      _selectedCategory = category;
    }
    notifyListeners();
  }

  void setLaundryFilter(LaundryStatus? status) {
    if (_selectedLaundryStatus == status) {
      _selectedLaundryStatus = null;
    } else {
      _selectedLaundryStatus = status;
    }
    notifyListeners();
  }

  Future<void> toggleFavorite(String garmentId) async {
    try {
      final updated = await _repository.toggleFavorite(garmentId);
      final index = _garments.indexWhere((g) => g.id == garmentId);
      if (index != -1) {
        _garments[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to toggle favorite: $e';
      notifyListeners();
    }
  }

  Future<void> updateLaundryStatus(String garmentId, LaundryStatus status) async {
    try {
      final updated = await _repository.updateLaundryStatus(garmentId, status);
      final index = _garments.indexWhere((g) => g.id == garmentId);
      if (index != -1) {
        _garments[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update laundry status: $e';
      notifyListeners();
    }
  }

  Future<int> importInitialInventory(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final initialItems = InitialInventoryFixture.getInitialGarments(userId);
      final count = await _repository.importInitialInventory(initialItems);
      _garments = await _repository.getGarments();
      _isLoading = false;
      notifyListeners();
      return count;
    } catch (e) {
      _errorMessage = 'Import failed: $e';
      _isLoading = false;
      notifyListeners();
      return 0;
    }
  }
}

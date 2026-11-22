import 'package:flutter/material.dart';
import '../../data/fixtures/initial_inventory.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/garment.dart';
import '../../domain/entities/laundry_status.dart';
import '../../domain/entities/wardrobe_stats.dart';
import '../../domain/repositories/wardrobe_repository.dart';

/// Presentation Controller for Digital Wardrobe state.
/// Coordinates reactive inventory, multi-factor filtering, search, sorting, and telemetry.
class WardrobeController extends ChangeNotifier {
  final WardrobeRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  List<Garment> _garments = [];
  List<WardrobeCategory> _categories = [];
  WardrobeStats _stats = const WardrobeStats();

  // Filters & Search
  String _searchQuery = '';
  String? _selectedCategory;
  LaundryStatus? _selectedLaundryStatus;
  String? _selectedColor;
  String? _selectedSleeveLength;
  bool _favoritesOnly = false;

  // Sorting
  String _sortBy = 'created_at'; // 'created_at', 'name', 'updated_at'
  String _sortOrder = 'desc'; // 'desc', 'asc'

  WardrobeController({required WardrobeRepository repository})
      : _repository = repository;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Garment> get garments => _garments;
  List<WardrobeCategory> get categories => _categories;
  WardrobeStats get stats => _stats;

  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  LaundryStatus? get selectedLaundryStatus => _selectedLaundryStatus;
  String? get selectedColor => _selectedColor;
  String? get selectedSleeveLength => _selectedSleeveLength;
  bool get favoritesOnly => _favoritesOnly;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;

  int get activeFilterCount {
    int count = 0;
    if (_selectedCategory != null) count++;
    if (_selectedLaundryStatus != null) count++;
    if (_selectedColor != null) count++;
    if (_selectedSleeveLength != null) count++;
    if (_favoritesOnly) count++;
    return count;
  }

  // Filtered & sorted view
  List<Garment> get filteredGarments {
    var list = _garments.where((g) {
      if (_selectedCategory != null &&
          g.mainCategory.toLowerCase() != _selectedCategory!.toLowerCase()) {
        return false;
      }
      if (_selectedLaundryStatus != null &&
          g.laundryStatus != _selectedLaundryStatus) {
        return false;
      }
      if (_selectedColor != null &&
          g.primaryColor.toLowerCase() != _selectedColor!.toLowerCase()) {
        return false;
      }
      if (_selectedSleeveLength != null &&
          g.sleeveLength?.toLowerCase() != _selectedSleeveLength!.toLowerCase()) {
        return false;
      }
      if (_favoritesOnly && !g.isFavorite) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matches = g.name.toLowerCase().contains(q) ||
            g.id.toLowerCase().contains(q) ||
            g.mainCategory.toLowerCase().contains(q) ||
            (g.subcategory != null && g.subcategory!.toLowerCase().contains(q)) ||
            g.primaryColor.toLowerCase().contains(q) ||
            (g.brand != null && g.brand!.toLowerCase().contains(q)) ||
            (g.pattern != null && g.pattern!.toLowerCase().contains(q));
        if (!matches) return false;
      }
      return true;
    }).toList();

    // In-memory sorting
    final isDesc = _sortOrder == 'desc';
    if (_sortBy == 'name') {
      list.sort((a, b) => isDesc ? b.name.compareTo(a.name) : a.name.compareTo(b.name));
    } else if (_sortBy == 'updated_at') {
      list.sort((a, b) => isDesc ? b.updatedAt.compareTo(a.updatedAt) : a.updatedAt.compareTo(b.updatedAt));
    } else {
      list.sort((a, b) => isDesc ? b.createdAt.compareTo(a.createdAt) : a.createdAt.compareTo(b.createdAt));
    }

    return list;
  }

  // Telemetry counts
  int get totalGarmentsCount => _stats.totalGarments > 0 ? _stats.totalGarments : _garments.length;
  int get cleanCount => _stats.cleanCount > 0
      ? _stats.cleanCount
      : _garments.where((g) => g.laundryStatus == LaundryStatus.clean).length;
  int get inLaundryCount => _stats.inLaundryCount > 0
      ? _stats.inLaundryCount
      : _garments.where((g) =>
          g.laundryStatus == LaundryStatus.washing ||
          g.laundryStatus == LaundryStatus.drying).length;
  int get unassignedCount => _stats.unassignedCount > 0
      ? _stats.unassignedCount
      : _garments.where((g) => g.laundryStatus == null).length;

  Future<void> loadInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getCategories(),
        _repository.getGarments(
          category: _selectedCategory,
          laundryStatus: _selectedLaundryStatus,
          favoritesOnly: _favoritesOnly ? true : null,
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
        ),
        _repository.getStats(),
      ]);

      _categories = results[0] as List<WardrobeCategory>;
      _garments = results[1] as List<Garment>;
      _stats = results[2] as WardrobeStats;
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _selectedCategory = (_selectedCategory == category) ? null : category;
    notifyListeners();
  }

  void setLaundryFilter(LaundryStatus? status) {
    _selectedLaundryStatus = (_selectedLaundryStatus == status) ? null : status;
    notifyListeners();
  }

  void setColorFilter(String? color) {
    _selectedColor = (_selectedColor == color) ? null : color;
    notifyListeners();
  }

  void setSleeveLengthFilter(String? sleeve) {
    _selectedSleeveLength = (_selectedSleeveLength == sleeve) ? null : sleeve;
    notifyListeners();
  }

  void toggleFavoritesOnly() {
    _favoritesOnly = !_favoritesOnly;
    notifyListeners();
  }

  void setSort(String sortBy, String sortOrder) {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    notifyListeners();
  }

  void clearAllFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedLaundryStatus = null;
    _selectedColor = null;
    _selectedSleeveLength = null;
    _favoritesOnly = false;
    notifyListeners();
  }

  Future<Garment> addGarment(Garment garment) async {
    _isLoading = true;
    notifyListeners();

    try {
      final created = await _repository.saveGarment(garment);
      _garments.insert(0, created);
      _stats = await _repository.getStats();
      _isLoading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _errorMessage = 'Failed to create garment: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<Garment> updateGarment(Garment garment) async {
    try {
      final updated = await _repository.updateGarment(garment);
      final index = _garments.indexWhere((g) => g.id == garment.id);
      if (index != -1) {
        _garments[index] = updated;
      }
      _stats = await _repository.getStats();
      notifyListeners();
      return updated;
    } catch (e) {
      _errorMessage = 'Failed to update garment: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> deleteGarment(String id, {bool hardDelete = false}) async {
    try {
      final success = await _repository.deleteGarment(id, hardDelete: hardDelete);
      if (success) {
        _garments.removeWhere((g) => g.id == id);
        _stats = await _repository.getStats();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to delete garment: $e';
      notifyListeners();
      return false;
    }
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
      }
      _stats = await _repository.getStats();
      notifyListeners();
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
      _stats = await _repository.getStats();
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

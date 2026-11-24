import 'package:flutter/foundation.dart';
import '../../domain/entities/wishlist_item.dart';
import '../../domain/entities/wardrobe_gap.dart';
import '../../domain/entities/purchase_assessment.dart';
import '../../domain/entities/wishlist_summary.dart';
import '../../domain/repositories/wishlist_repository.dart';

class WishlistController extends ChangeNotifier {
  final WishlistRepository _repository;

  WishlistController({required WishlistRepository repository})
      : _repository = repository;

  List<WishlistItem> _items = [];
  WishlistSummary? _summary;
  List<WardrobeGap> _gaps = [];
  PurchaseAssessment? _currentAssessment;
  List<GarmentMatch> _matchingGarments = [];

  bool _isLoading = false;
  String? _errorMessage;

  PurchasePriority? _selectedPriorityFilter;
  WishlistStatus? _selectedStatusFilter;
  String? _selectedCategoryFilter;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';

  // Getters
  List<WishlistItem> get items => _items;
  WishlistSummary? get summary => _summary;
  List<WardrobeGap> get gaps => _gaps;
  PurchaseAssessment? get currentAssessment => _currentAssessment;
  List<GarmentMatch> get matchingGarments => _matchingGarments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  PurchasePriority? get selectedPriorityFilter => _selectedPriorityFilter;
  WishlistStatus? get selectedStatusFilter => _selectedStatusFilter;
  String? get selectedCategoryFilter => _selectedCategoryFilter;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;

  List<WishlistItem> get filteredItems {
    return _items.where((item) {
      if (_selectedPriorityFilter != null &&
          item.purchasePriority != _selectedPriorityFilter) {
        return false;
      }
      if (_selectedStatusFilter != null &&
          item.status != _selectedStatusFilter) {
        return false;
      }
      if (_selectedCategoryFilter != null &&
          _selectedCategoryFilter!.isNotEmpty &&
          item.category.toLowerCase() !=
              _selectedCategoryFilter!.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  // Actions
  Future<void> loadDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getWishlist(
          status: _selectedStatusFilter,
          priority: _selectedPriorityFilter,
          category: _selectedCategoryFilter,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
        ),
        _repository.getSummary(),
        _repository.getWardrobeGaps(),
      ]);

      _items = results[0] as List<WishlistItem>;
      _summary = results[1] as WishlistSummary;
      _gaps = results[2] as List<WardrobeGap>;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load wishlist: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setPriorityFilter(PurchasePriority? priority) async {
    _selectedPriorityFilter = priority;
    notifyListeners();
    await _reloadItemsOnly();
  }

  Future<void> setStatusFilter(WishlistStatus? status) async {
    _selectedStatusFilter = status;
    notifyListeners();
    await _reloadItemsOnly();
  }

  Future<void> setCategoryFilter(String? category) async {
    _selectedCategoryFilter = category;
    notifyListeners();
    await _reloadItemsOnly();
  }

  Future<void> setSorting(String sortBy, {String sortOrder = 'desc'}) async {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    notifyListeners();
    await _reloadItemsOnly();
  }

  Future<void> _reloadItemsOnly() async {
    try {
      _items = await _repository.getWishlist(
        status: _selectedStatusFilter,
        priority: _selectedPriorityFilter,
        category: _selectedCategoryFilter,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to filter items: $e';
      notifyListeners();
    }
  }

  Future<WishlistItem?> createItem({
    required String name,
    required String category,
    String? subcategory,
    String? referenceImagePath,
    double? expectedPrice,
    String expectedCurrency = 'INR',
    PurchasePriority purchasePriority = PurchasePriority.medium,
    String? occasion,
    String? desiredColour,
    String? desiredPattern,
    String? description,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final created = await _repository.createWishlistItem(
        name: name,
        category: category,
        subcategory: subcategory,
        referenceImagePath: referenceImagePath,
        expectedPrice: expectedPrice,
        expectedCurrency: expectedCurrency,
        purchasePriority: purchasePriority,
        occasion: occasion,
        desiredColour: desiredColour,
        desiredPattern: desiredPattern,
        description: description,
        notes: notes,
      );

      _items.insert(0, created);
      _summary = await _repository.getSummary();
      _isLoading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _errorMessage = 'Failed to create wishlist item: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateItem(WishlistItem item) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updated = await _repository.updateWishlistItem(item);
      final idx = _items.indexWhere((i) => i.id == updated.id);
      if (idx != -1) {
        _items[idx] = updated;
      }
      _summary = await _repository.getSummary();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update item: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.deleteWishlistItem(id);
      if (success) {
        _items.removeWhere((i) => i.id == id);
        _summary = await _repository.getSummary();
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Failed to delete item: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(
    String id,
    WishlistStatus status, {
    double? actualPrice,
    String? actualCurrency,
    DateTime? purchasedAt,
  }) async {
    try {
      final updated = await _repository.updateStatus(
        id,
        status,
        actualPrice: actualPrice,
        actualCurrency: actualCurrency,
        purchasedAt: purchasedAt,
      );
      final idx = _items.indexWhere((i) => i.id == id);
      if (idx != -1) {
        _items[idx] = updated;
      }
      _summary = await _repository.getSummary();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update status: $e';
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> convertToWardrobe(
    String id, {
    double? actualPrice,
    String? actualCurrency,
    DateTime? purchaseDate,
    String? laundryStatus,
    String? garmentNameOverride,
    String? primaryColor,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _repository.convertToWardrobe(
        id,
        actualPrice: actualPrice,
        actualCurrency: actualCurrency,
        purchaseDate: purchaseDate,
        laundryStatus: laundryStatus,
        garmentNameOverride: garmentNameOverride,
        primaryColor: primaryColor,
      );

      // Refresh item and summary
      final updated = await _repository.getWishlistItem(id);
      if (updated != null) {
        final idx = _items.indexWhere((i) => i.id == id);
        if (idx != -1) {
          _items[idx] = updated;
        }
      }
      _summary = await _repository.getSummary();
      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e) {
      _errorMessage = 'Failed to convert item to wardrobe: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> assessItem(String id) async {
    _isLoading = true;
    _currentAssessment = null;
    notifyListeners();

    try {
      _currentAssessment = await _repository.assessWishlistItem(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to assess item: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> findMatches(String category, {String? subcategory, String? desiredColour}) async {
    try {
      _matchingGarments = await _repository.matchExistingGarments(
        category,
        subcategory: subcategory,
        desiredColour: desiredColour,
      );
      notifyListeners();
    } catch (e) {
      _matchingGarments = [];
      notifyListeners();
    }
  }
}

import 'package:flutter/foundation.dart';
import '../../domain/entities/garment.dart';
import '../../domain/entities/laundry_batch.dart';
import '../../domain/entities/laundry_history_entry.dart';
import '../../domain/entities/laundry_stats.dart';
import '../../domain/entities/laundry_status.dart';
import '../../domain/repositories/laundry_repository.dart';

class LaundryController extends ChangeNotifier {
  final LaundryRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;

  LaundryStats _stats = const LaundryStats();
  List<LaundryBatch> _batches = [];
  List<Garment> _currentStatusItems = [];
  final Map<String, List<LaundryHistoryEntry>> _garmentHistory = {};

  LaundryController({required LaundryRepository repository})
      : _repository = repository;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LaundryStats get stats => _stats;
  List<LaundryBatch> get batches => _batches;
  List<LaundryBatch> get activeBatches =>
      _batches.where((b) => b.isActive).toList();
  List<Garment> get currentStatusItems => _currentStatusItems;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final s = await _repository.getLaundryStats();
      final b = await _repository.getBatches();
      _stats = s;
      _batches = b;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load laundry data: $e';
      notifyListeners();
    }
  }

  Future<void> loadItemsByStatus(String? status,
      {String? category, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final items = await _repository.getLaundryItems(
        status: status,
        category: category,
        search: search,
      );
      _currentStatusItems = items;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load garments: $e';
      notifyListeners();
    }
  }

  Future<bool> updateGarmentStatus(String garmentId, LaundryStatus? newStatus,
      {String? notes}) async {
    try {
      final updated = await _repository.updateGarmentLaundryStatus(
        garmentId,
        newStatus,
        notes: notes,
      );

      // Update in currentStatusItems if present
      final idx = _currentStatusItems.indexWhere((g) => g.id == garmentId);
      if (idx != -1) {
        _currentStatusItems[idx] = updated;
      }

      // Refresh stats in background
      _repository.getLaundryStats().then((s) {
        _stats = s;
        notifyListeners();
      }).catchError((_) {});

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update laundry status: $e';
      notifyListeners();
      return false;
    }
  }

  Future<LaundryBatch?> createBatch(List<String> garmentIds,
      {String? name, String? notes}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final batch = await _repository.createBatch(
        garmentIds,
        name: name,
        initialStatus: 'WASHING',
        notes: notes,
      );
      _batches.insert(0, batch);

      // Refresh stats
      final s = await _repository.getLaundryStats();
      _stats = s;

      _isLoading = false;
      notifyListeners();
      return batch;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to create laundry batch: $e';
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> advanceBatch(String batchId, String newStatus,
      {String? notes}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.advanceBatchStatus(
        batchId,
        newStatus,
        notes: notes,
      );

      // Reload batch
      final updatedBatch = await _repository.getBatch(batchId);
      if (updatedBatch != null) {
        final idx = _batches.indexWhere((b) => b.id == batchId);
        if (idx != -1) {
          _batches[idx] = updatedBatch;
        }
      }

      // Refresh stats
      final s = await _repository.getLaundryStats();
      _stats = s;

      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to advance batch: $e';
      notifyListeners();
      return null;
    }
  }

  Future<List<LaundryHistoryEntry>> loadGarmentHistory(String garmentId) async {
    try {
      final history = await _repository.getGarmentLaundryHistory(garmentId);
      _garmentHistory[garmentId] = history;
      notifyListeners();
      return history;
    } catch (e) {
      debugPrint('[LaundryController] loadGarmentHistory error: $e');
      return [];
    }
  }

  List<LaundryHistoryEntry> getHistoryForGarment(String garmentId) {
    return _garmentHistory[garmentId] ?? [];
  }
}

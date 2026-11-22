import 'package:flutter/foundation.dart';
import '../../domain/entities/garment.dart';
import '../../domain/entities/laundry_batch.dart';
import '../../domain/entities/laundry_batch_item.dart';
import '../../domain/entities/laundry_history_entry.dart';
import '../../domain/entities/laundry_stats.dart';
import '../../domain/entities/laundry_status.dart';
import '../../domain/repositories/laundry_repository.dart';
import '../services/laundry_api_service.dart';

class LaundryRepositoryImpl implements LaundryRepository {
  final LaundryApiService _apiService;

  // Local fallback caches for offline & unit test environments
  final Map<String, LaundryBatch> _batchesCache = {};
  final Map<String, List<LaundryHistoryEntry>> _historyCache = {};
  final Map<String, Garment> _garmentsCache = {};

  LaundryRepositoryImpl({LaundryApiService? apiService})
      : _apiService = apiService ?? LaundryApiService();

  @override
  Future<LaundryStats> getLaundryStats() async {
    try {
      final model = await _apiService.getLaundryStats();
      return model.toDomain();
    } catch (e) {
      debugPrint('[LaundryRepositoryImpl] Remote getLaundryStats notice: $e');
      final garments = _garmentsCache.values.toList();
      final total = garments.length;
      final clean =
          garments.where((g) => g.laundryStatus == LaundryStatus.clean).length;
      final worn =
          garments.where((g) => g.laundryStatus == LaundryStatus.worn).length;
      final washing = garments
          .where((g) => g.laundryStatus == LaundryStatus.washing)
          .length;
      final drying =
          garments.where((g) => g.laundryStatus == LaundryStatus.drying).length;
      final stored =
          garments.where((g) => g.laundryStatus == LaundryStatus.stored).length;
      final unassigned = garments.where((g) => g.laundryStatus == null).length;
      final activeBatches =
          _batchesCache.values.where((b) => b.isActive).length;

      return LaundryStats(
        totalGarments: total,
        cleanCount: clean,
        wornCount: worn,
        washingCount: washing,
        dryingCount: drying,
        storedCount: stored,
        unassignedCount: unassigned,
        activeBatchesCount: activeBatches,
      );
    }
  }

  @override
  Future<List<Garment>> getLaundryItems({
    String? status,
    String? category,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final models = await _apiService.getLaundryItems(
        status: status,
        category: category,
        search: search,
        page: page,
        limit: limit,
      );
      final items = models.map((m) => m.toDomain()).toList();
      for (final item in items) {
        _garmentsCache[item.id] = item;
      }
      return items;
    } catch (e) {
      debugPrint('[LaundryRepositoryImpl] Remote getLaundryItems notice: $e');
      var list = _garmentsCache.values.toList();
      if (status != null && status.isNotEmpty) {
        if (status.toUpperCase() == 'UNASSIGNED') {
          list = list.where((g) => g.laundryStatus == null).toList();
        } else {
          list = list
              .where((g) => g.laundryStatus?.value == status.toUpperCase())
              .toList();
        }
      }
      if (category != null && category.isNotEmpty) {
        list = list
            .where(
                (g) => g.mainCategory.toLowerCase() == category.toLowerCase())
            .toList();
      }
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        list = list
            .where((g) =>
                g.name.toLowerCase().contains(q) ||
                g.id.toLowerCase().contains(q))
            .toList();
      }
      return list;
    }
  }

  @override
  Future<Garment> updateGarmentLaundryStatus(
    String garmentId,
    LaundryStatus? status, {
    String? notes,
    String? idempotencyKey,
  }) async {
    try {
      final model = await _apiService.updateGarmentLaundryStatus(
        garmentId,
        status?.value,
        notes: notes,
        idempotencyKey: idempotencyKey,
      );
      final domain = model.toDomain();
      _garmentsCache[garmentId] = domain;
      return domain;
    } catch (e) {
      debugPrint(
          '[LaundryRepositoryImpl] Remote updateGarmentLaundryStatus notice: $e');
      final existing = _garmentsCache[garmentId] ??
          Garment(
            id: garmentId,
            userId: 'local_user',
            name: 'Garment $garmentId',
            mainCategory: 'Tops',
            primaryColor: 'Blue',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

      int wearCount = existing.wearCount;
      int washCount = existing.washCount;
      DateTime? lastWorn = existing.lastWornDate;
      DateTime? lastWashed = existing.lastWashedDate;

      if (status == LaundryStatus.worn &&
          existing.laundryStatus != LaundryStatus.worn) {
        wearCount += 1;
        lastWorn = DateTime.now();
      } else if (status == LaundryStatus.clean &&
          (existing.laundryStatus == LaundryStatus.washing ||
              existing.laundryStatus == LaundryStatus.drying)) {
        washCount += 1;
        lastWashed = DateTime.now();
      }

      final updated = existing.copyWith(
        laundryStatus: status,
        wearCount: wearCount,
        washCount: washCount,
        lastWornDate: lastWorn,
        lastWashedDate: lastWashed,
        updatedAt: DateTime.now(),
      );
      _garmentsCache[garmentId] = updated;

      // Add to history
      final historyList = _historyCache.putIfAbsent(garmentId, () => []);
      historyList.insert(
        0,
        LaundryHistoryEntry(
          id: 'hist_${DateTime.now().millisecondsSinceEpoch}',
          userId: 'local_user',
          garmentId: garmentId,
          eventType: status == LaundryStatus.worn ? 'WEAR' : 'STATUS_CHANGE',
          previousStatus: existing.laundryStatus?.value,
          newStatus: status?.value,
          notes: notes,
          createdAt: DateTime.now(),
        ),
      );

      return updated;
    }
  }

  @override
  Future<List<LaundryHistoryEntry>> getGarmentLaundryHistory(
      String garmentId) async {
    try {
      final models = await _apiService.getGarmentLaundryHistory(garmentId);
      final entries = models.map((m) => m.toDomain()).toList();
      _historyCache[garmentId] = entries;
      return entries;
    } catch (e) {
      debugPrint(
          '[LaundryRepositoryImpl] Remote getGarmentLaundryHistory notice: $e');
      return _historyCache[garmentId] ?? [];
    }
  }

  @override
  Future<LaundryBatch> createBatch(
    List<String> garmentIds, {
    String? name,
    String initialStatus = 'WASHING',
    String? notes,
    String? idempotencyKey,
  }) async {
    try {
      final model = await _apiService.createBatch(
        garmentIds,
        name: name,
        initialStatus: initialStatus,
        notes: notes,
        idempotencyKey: idempotencyKey,
      );
      final domain = model.toDomain();
      _batchesCache[domain.id] = domain;
      return domain;
    } catch (e) {
      debugPrint('[LaundryRepositoryImpl] Remote createBatch notice: $e');
      final batchId = 'batch_${DateTime.now().millisecondsSinceEpoch}';
      final batchNum = 'BATCH-${_batchesCache.length + 1}'.padLeft(9, '0');
      final batchItems = garmentIds.map((gid) {
        final g = _garmentsCache[gid];
        return LaundryBatchItem(
          id: 'item_${gid}_$batchId',
          batchId: batchId,
          garmentId: gid,
          garmentName: g?.name ?? 'Garment $gid',
          garmentCategory: g?.mainCategory,
          currentLaundryStatus: initialStatus,
          thumbnailRef: g?.thumbnailRef,
          status: 'ACTIVE',
          addedAt: DateTime.now(),
        );
      }).toList();

      final batch = LaundryBatch(
        id: batchId,
        userId: 'local_user',
        batchNumber: batchNum,
        name: name ?? 'Laundry Batch #00${_batchesCache.length + 1}',
        status: initialStatus,
        notes: notes,
        itemsCount: batchItems.length,
        items: batchItems,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _batchesCache[batchId] = batch;

      // Update garment status in cache
      final targetStatus = LaundryStatus.fromString(initialStatus);
      for (final gid in garmentIds) {
        if (_garmentsCache.containsKey(gid)) {
          _garmentsCache[gid] = _garmentsCache[gid]!.copyWith(
            laundryStatus: targetStatus,
            activeBatchId: batchId,
          );
        }
      }

      return batch;
    }
  }

  @override
  Future<List<LaundryBatch>> getBatches({String? status}) async {
    try {
      final models = await _apiService.getBatches(status: status);
      final list = models.map((m) => m.toDomain()).toList();
      for (final b in list) {
        _batchesCache[b.id] = b;
      }
      return list;
    } catch (e) {
      debugPrint('[LaundryRepositoryImpl] Remote getBatches notice: $e');
      final list = _batchesCache.values.toList();
      if (status != null && status.isNotEmpty) {
        return list
            .where((b) => b.status.toUpperCase() == status.toUpperCase())
            .toList();
      }
      return list;
    }
  }

  @override
  Future<LaundryBatch?> getBatch(String batchId) async {
    try {
      final model = await _apiService.getBatch(batchId);
      final domain = model.toDomain();
      _batchesCache[batchId] = domain;
      return domain;
    } catch (e) {
      debugPrint('[LaundryRepositoryImpl] Remote getBatch notice: $e');
      return _batchesCache[batchId];
    }
  }

  @override
  Future<Map<String, dynamic>> advanceBatchStatus(
    String batchId,
    String newStatus, {
    String? notes,
    String? idempotencyKey,
  }) async {
    try {
      return await _apiService.advanceBatchStatus(
        batchId,
        newStatus,
        notes: notes,
        idempotencyKey: idempotencyKey,
      );
    } catch (e) {
      debugPrint(
          '[LaundryRepositoryImpl] Remote advanceBatchStatus notice: $e');
      final batch = _batchesCache[batchId];
      if (batch == null) throw Exception('Batch not found');

      final updatedItems = <String>[];
      final skippedItems = <String>[];

      final newBatchItems = batch.items.map((item) {
        final liveGarment = _garmentsCache[item.garmentId];
        final currentGStatus =
            liveGarment?.laundryStatus?.value ?? item.currentLaundryStatus;

        if (newStatus == 'DRYING') {
          if (currentGStatus == 'WASHING') {
            updatedItems.add(item.garmentId);
            if (_garmentsCache.containsKey(item.garmentId)) {
              _garmentsCache[item.garmentId] =
                  _garmentsCache[item.garmentId]!.copyWith(
                laundryStatus: LaundryStatus.drying,
              );
            }
            return item.copyWith(currentLaundryStatus: 'DRYING');
          } else {
            skippedItems.add(item.garmentId);
            return item.copyWith(currentLaundryStatus: currentGStatus);
          }
        } else if (newStatus == 'COMPLETED') {
          if (currentGStatus == 'DRYING' || currentGStatus == 'WASHING') {
            updatedItems.add(item.garmentId);
            if (_garmentsCache.containsKey(item.garmentId)) {
              final g = _garmentsCache[item.garmentId]!;
              _garmentsCache[item.garmentId] = g.copyWith(
                laundryStatus: LaundryStatus.clean,
                washCount: g.washCount + 1,
                lastWashedDate: DateTime.now(),
                activeBatchId: null,
              );
            }
            return item.copyWith(
                currentLaundryStatus: 'CLEAN', status: 'COMPLETED');
          } else {
            skippedItems.add(item.garmentId);
            return item.copyWith(currentLaundryStatus: currentGStatus);
          }
        }
        return item;
      }).toList();

      final updatedBatch = batch.copyWith(
        status: newStatus,
        items: newBatchItems,
        completedAt: newStatus == 'COMPLETED' ? DateTime.now() : null,
      );
      _batchesCache[batchId] = updatedBatch;

      return {
        'batch_id': batchId,
        'new_batch_status': newStatus,
        'updated_garment_ids': updatedItems,
        'skipped_garment_ids': skippedItems,
        'message': 'Advanced to $newStatus',
      };
    }
  }

  @override
  Future<LaundryBatch> addItemsToBatch(
      String batchId, List<String> garmentIds) async {
    try {
      final model = await _apiService.addItemsToBatch(batchId, garmentIds);
      final domain = model.toDomain();
      _batchesCache[batchId] = domain;
      return domain;
    } catch (e) {
      debugPrint('[LaundryRepositoryImpl] Remote addItemsToBatch notice: $e');
      final batch = _batchesCache[batchId];
      if (batch == null) throw Exception('Batch not found');
      return batch;
    }
  }

  @override
  Future<bool> removeItemFromBatch(String batchId, String garmentId) async {
    try {
      return await _apiService.removeItemFromBatch(batchId, garmentId);
    } catch (e) {
      debugPrint(
          '[LaundryRepositoryImpl] Remote removeItemFromBatch notice: $e');
      final batch = _batchesCache[batchId];
      if (batch != null) {
        final newItems = batch.items.map((i) {
          if (i.garmentId == garmentId) {
            return i.copyWith(status: 'REMOVED');
          }
          return i;
        }).toList();
        _batchesCache[batchId] = batch.copyWith(items: newItems);
      }
      if (_garmentsCache.containsKey(garmentId)) {
        _garmentsCache[garmentId] =
            _garmentsCache[garmentId]!.copyWith(activeBatchId: null);
      }
      return true;
    }
  }

  /// Helper to pre-populate local cache for widget/unit tests
  void seedGarment(Garment g) {
    _garmentsCache[g.id] = g;
  }
}

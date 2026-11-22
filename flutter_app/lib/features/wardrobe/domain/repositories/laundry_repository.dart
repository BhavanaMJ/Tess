import '../entities/garment.dart';
import '../entities/laundry_batch.dart';
import '../entities/laundry_history_entry.dart';
import '../entities/laundry_stats.dart';
import '../entities/laundry_status.dart';

abstract class LaundryRepository {
  Future<LaundryStats> getLaundryStats();
  Future<List<Garment>> getLaundryItems({
    String? status,
    String? category,
    String? search,
    int page = 1,
    int limit = 50,
  });
  Future<Garment> updateGarmentLaundryStatus(
    String garmentId,
    LaundryStatus? status, {
    String? notes,
    String? idempotencyKey,
  });
  Future<List<LaundryHistoryEntry>> getGarmentLaundryHistory(String garmentId);
  Future<LaundryBatch> createBatch(
    List<String> garmentIds, {
    String? name,
    String initialStatus = 'WASHING',
    String? notes,
    String? idempotencyKey,
  });
  Future<List<LaundryBatch>> getBatches({String? status});
  Future<LaundryBatch?> getBatch(String batchId);
  Future<Map<String, dynamic>> advanceBatchStatus(
    String batchId,
    String newStatus, {
    String? notes,
    String? idempotencyKey,
  });
  Future<LaundryBatch> addItemsToBatch(String batchId, List<String> garmentIds);
  Future<bool> removeItemFromBatch(String batchId, String garmentId);
}

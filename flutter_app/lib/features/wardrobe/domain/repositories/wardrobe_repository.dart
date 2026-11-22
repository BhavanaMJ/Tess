import '../entities/category.dart';
import '../entities/garment.dart';
import '../entities/laundry_status.dart';
import '../entities/wardrobe_stats.dart';

/// Repository contract for Wardrobe operations.
/// Defines pure domain business interfaces independent of concrete API/Database implementations.
abstract class WardrobeRepository {
  /// Fetches all garments belonging to the authenticated user with optional filtering/search/sorting
  Future<List<Garment>> getGarments({
    String? category,
    LaundryStatus? laundryStatus,
    bool? favoritesOnly,
    String? search,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? limit,
  });

  /// Fetches a single garment by unique ID
  Future<Garment?> getGarmentById(String id);

  /// Saves a new garment
  Future<Garment> saveGarment(Garment garment);

  /// Updates an existing garment
  Future<Garment> updateGarment(Garment garment);

  /// Deletes a garment (soft archive by default)
  Future<bool> deleteGarment(String id, {bool hardDelete = false});

  /// Updates laundry status for a specific garment
  Future<Garment> updateLaundryStatus(String id, LaundryStatus status);

  /// Toggles favorite flag for a garment
  Future<Garment> toggleFavorite(String id);

  /// Retrieves wardrobe categories (built-in and custom)
  Future<List<WardrobeCategory>> getCategories();

  /// Retrieves operational telemetry statistics from backend
  Future<WardrobeStats> getStats();

  /// Bulk imports an initial inventory batch (e.g. initial 18 garments) idempotently
  Future<int> importInitialInventory(List<Garment> garments);
}

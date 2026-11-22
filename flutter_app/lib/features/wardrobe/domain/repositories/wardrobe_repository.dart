import '../entities/category.dart';
import '../entities/garment.dart';
import '../entities/laundry_status.dart';

/// Repository contract for Wardrobe operations.
/// Defines pure domain business interfaces independent of concrete API/Database implementations.
abstract class WardrobeRepository {
  /// Fetches all garments belonging to the authenticated user
  Future<List<Garment>> getGarments({
    String? category,
    LaundryStatus? laundryStatus,
    bool? favoritesOnly,
  });

  /// Fetches a single garment by unique ID
  Future<Garment?> getGarmentById(String id);

  /// Saves or updates a garment
  Future<Garment> saveGarment(Garment garment);

  /// Deletes a garment (soft or hard archive)
  Future<bool> deleteGarment(String id);

  /// Updates laundry status for a specific garment
  Future<Garment> updateLaundryStatus(String id, LaundryStatus status);

  /// Toggles favorite flag for a garment
  Future<Garment> toggleFavorite(String id);

  /// Retrieves wardrobe categories (built-in and custom)
  Future<List<WardrobeCategory>> getCategories();

  /// Bulk imports an initial inventory batch (e.g. initial 18 garments)
  Future<int> importInitialInventory(List<Garment> garments);
}

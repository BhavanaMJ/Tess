import '../entities/wishlist_item.dart';
import '../entities/wardrobe_gap.dart';
import '../entities/purchase_assessment.dart';
import '../entities/wishlist_summary.dart';

abstract class WishlistRepository {
  Future<List<WishlistItem>> getWishlist({
    WishlistStatus? status,
    PurchasePriority? priority,
    String? category,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  });

  Future<WishlistItem?> getWishlistItem(String id);

  Future<WishlistItem> createWishlistItem({
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
  });

  Future<WishlistItem> updateWishlistItem(WishlistItem item);

  Future<bool> deleteWishlistItem(String id);

  Future<WishlistItem> updateStatus(
    String id,
    WishlistStatus status, {
    double? actualPrice,
    String? actualCurrency,
    DateTime? purchasedAt,
  });

  Future<WishlistSummary> getSummary();

  Future<String> uploadReferenceImage(List<int> bytes, String filename);

  Future<Map<String, dynamic>> convertToWardrobe(
    String id, {
    double? actualPrice,
    String? actualCurrency,
    DateTime? purchaseDate,
    String? laundryStatus,
    String? garmentNameOverride,
    String? primaryColor,
  });

  Future<List<WardrobeGap>> getWardrobeGaps();

  Future<List<GarmentMatch>> matchExistingGarments(
    String category, {
    String? subcategory,
    String? desiredColour,
  });

  Future<PurchaseAssessment> assessWishlistItem(String id);
}

import '../../domain/entities/wishlist_summary.dart';

class WishlistSummaryModel extends WishlistSummary {
  const WishlistSummaryModel({
    required super.totalItems,
    required super.highPriorityCount,
    required super.shortlistedCount,
    required super.purchasedCount,
    required super.consideringCount,
    required super.notInterestedCount,
    super.estimatedWishlistValue = const {},
    super.purchasedTotalValue = const {},
    required super.unpricedItemsCount,
  });

  factory WishlistSummaryModel.fromJson(Map<String, dynamic> json) {
    final estMap = <String, double>{};
    if (json['estimated_wishlist_value'] != null) {
      (json['estimated_wishlist_value'] as Map<String, dynamic>).forEach((k, v) {
        if (v != null) estMap[k] = (v as num).toDouble();
      });
    }

    final purMap = <String, double>{};
    if (json['purchased_total_value'] != null) {
      (json['purchased_total_value'] as Map<String, dynamic>).forEach((k, v) {
        if (v != null) purMap[k] = (v as num).toDouble();
      });
    }

    return WishlistSummaryModel(
      totalItems: (json['total_items'] as num).toInt(),
      highPriorityCount: (json['high_priority_count'] as num).toInt(),
      shortlistedCount: (json['shortlisted_count'] as num).toInt(),
      purchasedCount: (json['purchased_count'] as num).toInt(),
      consideringCount: (json['considering_count'] as num).toInt(),
      notInterestedCount: (json['not_interested_count'] as num).toInt(),
      estimatedWishlistValue: estMap,
      purchasedTotalValue: purMap,
      unpricedItemsCount: (json['unpriced_items_count'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_items': totalItems,
      'high_priority_count': highPriorityCount,
      'shortlisted_count': shortlistedCount,
      'purchased_count': purchasedCount,
      'considering_count': consideringCount,
      'not_interested_count': notInterestedCount,
      'estimated_wishlist_value': estimatedWishlistValue,
      'purchased_total_value': purchasedTotalValue,
      'unpriced_items_count': unpricedItemsCount,
    };
  }
}

/// Summary statistics and financial totals across the user's wardrobe wishlist.
class WishlistSummary {
  final int totalItems;
  final int highPriorityCount;
  final int shortlistedCount;
  final int purchasedCount;
  final int consideringCount;
  final int notInterestedCount;
  final Map<String, double> estimatedWishlistValue;
  final Map<String, double> purchasedTotalValue;
  final int unpricedItemsCount;

  const WishlistSummary({
    required this.totalItems,
    required this.highPriorityCount,
    required this.shortlistedCount,
    required this.purchasedCount,
    required this.consideringCount,
    required this.notInterestedCount,
    this.estimatedWishlistValue = const {},
    this.purchasedTotalValue = const {},
    required this.unpricedItemsCount,
  });

  /// Primary estimated value in INR or first available currency
  double get primaryEstimatedValue =>
      estimatedWishlistValue['INR'] ??
      (estimatedWishlistValue.isNotEmpty ? estimatedWishlistValue.values.first : 0.0);

  String get primaryCurrency =>
      estimatedWishlistValue.containsKey('INR')
          ? 'INR'
          : (estimatedWishlistValue.isNotEmpty ? estimatedWishlistValue.keys.first : 'INR');
}

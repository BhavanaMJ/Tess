/// Purchase Priority for Wishlist items
enum PurchasePriority {
  high,
  medium,
  low;

  static PurchasePriority fromString(String val) {
    switch (val.toUpperCase()) {
      case 'HIGH':
        return PurchasePriority.high;
      case 'LOW':
        return PurchasePriority.low;
      case 'MEDIUM':
      default:
        return PurchasePriority.medium;
    }
  }

  String get displayName {
    switch (this) {
      case PurchasePriority.high:
        return 'High';
      case PurchasePriority.medium:
        return 'Medium';
      case PurchasePriority.low:
        return 'Low';
    }
  }

  String get apiValue {
    switch (this) {
      case PurchasePriority.high:
        return 'HIGH';
      case PurchasePriority.medium:
        return 'MEDIUM';
      case PurchasePriority.low:
        return 'LOW';
    }
  }
}

/// Purchase Status for Wishlist items
enum WishlistStatus {
  considering,
  shortlisted,
  purchased,
  notInterested;

  static WishlistStatus fromString(String val) {
    switch (val.toUpperCase()) {
      case 'SHORTLISTED':
        return WishlistStatus.shortlisted;
      case 'PURCHASED':
        return WishlistStatus.purchased;
      case 'NOT_INTERESTED':
        return WishlistStatus.notInterested;
      case 'CONSIDERING':
      default:
        return WishlistStatus.considering;
    }
  }

  String get displayName {
    switch (this) {
      case WishlistStatus.considering:
        return 'Considering';
      case WishlistStatus.shortlisted:
        return 'Shortlisted';
      case WishlistStatus.purchased:
        return 'Purchased';
      case WishlistStatus.notInterested:
        return 'Not Interested';
    }
  }

  String get apiValue {
    switch (this) {
      case WishlistStatus.considering:
        return 'CONSIDERING';
      case WishlistStatus.shortlisted:
        return 'SHORTLISTED';
      case WishlistStatus.purchased:
        return 'PURCHASED';
      case WishlistStatus.notInterested:
        return 'NOT_INTERESTED';
    }
  }
}

/// Domain entity representing an item saved in the user's wardrobe wishlist.
class WishlistItem {
  final String id;
  final String userId;
  final String name;
  final String category;
  final String? subcategory;
  final String? referenceImagePath;
  final double? expectedPrice;
  final String expectedCurrency;
  final PurchasePriority purchasePriority;
  final String? occasion;
  final String? desiredColour;
  final String? desiredPattern;
  final String? description;
  final String? notes;
  final WishlistStatus status;
  final DateTime? purchasedAt;
  final double? actualPurchasePrice;
  final String? actualPurchaseCurrency;
  final String? convertedGarmentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WishlistItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.subcategory,
    this.referenceImagePath,
    this.expectedPrice,
    this.expectedCurrency = 'INR',
    this.purchasePriority = PurchasePriority.medium,
    this.occasion,
    this.desiredColour,
    this.desiredPattern,
    this.description,
    this.notes,
    this.status = WishlistStatus.considering,
    this.purchasedAt,
    this.actualPurchasePrice,
    this.actualPurchaseCurrency,
    this.convertedGarmentId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPurchased => status == WishlistStatus.purchased;
  bool get isConverted => convertedGarmentId != null;

  WishlistItem copyWith({
    String? id,
    String? userId,
    String? name,
    String? category,
    String? subcategory,
    String? referenceImagePath,
    double? expectedPrice,
    String? expectedCurrency,
    PurchasePriority? purchasePriority,
    String? occasion,
    String? desiredColour,
    String? desiredPattern,
    String? description,
    String? notes,
    WishlistStatus? status,
    DateTime? purchasedAt,
    double? actualPurchasePrice,
    String? actualPurchaseCurrency,
    String? convertedGarmentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      referenceImagePath: referenceImagePath ?? this.referenceImagePath,
      expectedPrice: expectedPrice ?? this.expectedPrice,
      expectedCurrency: expectedCurrency ?? this.expectedCurrency,
      purchasePriority: purchasePriority ?? this.purchasePriority,
      occasion: occasion ?? this.occasion,
      desiredColour: desiredColour ?? this.desiredColour,
      desiredPattern: desiredPattern ?? this.desiredPattern,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      actualPurchasePrice: actualPurchasePrice ?? this.actualPurchasePrice,
      actualPurchaseCurrency: actualPurchaseCurrency ?? this.actualPurchaseCurrency,
      convertedGarmentId: convertedGarmentId ?? this.convertedGarmentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

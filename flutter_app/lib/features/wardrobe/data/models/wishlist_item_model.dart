import '../../domain/entities/wishlist_item.dart';

class WishlistItemModel extends WishlistItem {
  const WishlistItemModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.category,
    super.subcategory,
    super.referenceImagePath,
    super.expectedPrice,
    super.expectedCurrency = 'INR',
    super.purchasePriority = PurchasePriority.medium,
    super.occasion,
    super.desiredColour,
    super.desiredPattern,
    super.description,
    super.notes,
    super.status = WishlistStatus.considering,
    super.purchasedAt,
    super.actualPurchasePrice,
    super.actualPurchaseCurrency,
    super.convertedGarmentId,
    required super.createdAt,
    required super.updatedAt,
  });

  factory WishlistItemModel.fromJson(Map<String, dynamic> json) {
    return WishlistItemModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      referenceImagePath: json['reference_image_path'] as String?,
      expectedPrice: json['expected_price'] != null
          ? (json['expected_price'] as num).toDouble()
          : null,
      expectedCurrency: json['expected_currency'] as String? ?? 'INR',
      purchasePriority: PurchasePriority.fromString(
        json['purchase_priority'] as String? ?? 'MEDIUM',
      ),
      occasion: json['occasion'] as String?,
      desiredColour: json['desired_colour'] as String?,
      desiredPattern: json['desired_pattern'] as String?,
      description: json['description'] as String?,
      notes: json['notes'] as String?,
      status: WishlistStatus.fromString(
        json['status'] as String? ?? 'CONSIDERING',
      ),
      purchasedAt: json['purchased_at'] != null
          ? DateTime.parse(json['purchased_at'] as String)
          : null,
      actualPurchasePrice: json['actual_purchase_price'] != null
          ? (json['actual_purchase_price'] as num).toDouble()
          : null,
      actualPurchaseCurrency: json['actual_purchase_currency'] as String?,
      convertedGarmentId: json['converted_garment_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'reference_image_path': referenceImagePath,
      'expected_price': expectedPrice,
      'expected_currency': expectedCurrency,
      'purchase_priority': purchasePriority.apiValue,
      'occasion': occasion,
      'desired_colour': desiredColour,
      'desired_pattern': desiredPattern,
      'description': description,
      'notes': notes,
      'status': status.apiValue,
      'purchased_at': purchasedAt?.toIso8601String(),
      'actual_purchase_price': actualPurchasePrice,
      'actual_purchase_currency': actualPurchaseCurrency,
      'converted_garment_id': convertedGarmentId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

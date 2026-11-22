import '../../domain/entities/category.dart';

/// Data Model for WardrobeCategory serialization.
class WardrobeCategoryModel {
  final String id;
  final String name;
  final String? iconName;
  final String? parentCategoryId;
  final List<String> subcategories;
  final int orderIndex;

  const WardrobeCategoryModel({
    required this.id,
    required this.name,
    this.iconName,
    this.parentCategoryId,
    this.subcategories = const [],
    this.orderIndex = 0,
  });

  factory WardrobeCategoryModel.fromJson(Map<String, dynamic> json) {
    return WardrobeCategoryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'General',
      iconName: json['icon_name'] as String?,
      parentCategoryId: json['parent_category_id'] as String?,
      subcategories: (json['subcategories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'parent_category_id': parentCategoryId,
      'subcategories': subcategories,
      'order_index': orderIndex,
    };
  }

  WardrobeCategory toDomain() {
    return WardrobeCategory(
      id: id,
      name: name,
      iconName: iconName,
      parentCategoryId: parentCategoryId,
      subcategories: subcategories,
      orderIndex: orderIndex,
    );
  }

  factory WardrobeCategoryModel.fromDomain(WardrobeCategory category) {
    return WardrobeCategoryModel(
      id: category.id,
      name: category.name,
      iconName: category.iconName,
      parentCategoryId: category.parentCategoryId,
      subcategories: category.subcategories,
      orderIndex: category.orderIndex,
    );
  }
}

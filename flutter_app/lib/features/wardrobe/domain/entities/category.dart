/// Hierarchical Wardrobe Category Entity.
/// Supports standard root categories and customizable subcategories.
class WardrobeCategory {
  final String id;
  final String name;
  final String? iconName;
  final String? parentCategoryId;
  final List<String> subcategories;
  final int orderIndex;

  const WardrobeCategory({
    required this.id,
    required this.name,
    this.iconName,
    this.parentCategoryId,
    this.subcategories = const [],
    this.orderIndex = 0,
  });

  /// Standard default wardrobe categories specified by product requirements
  static const List<WardrobeCategory> defaultCategories = [
    WardrobeCategory(
      id: 'cat_tops',
      name: 'Tops',
      iconName: 'checkroom',
      subcategories: ['T-Shirts', 'Shirts', 'Blouses', 'Tunics', 'Crop Tops', 'Polos', 'Tanks'],
      orderIndex: 1,
    ),
    WardrobeCategory(
      id: 'cat_bottoms',
      name: 'Bottoms',
      iconName: 'dry_cleaning',
      subcategories: ['Jeans', 'Trousers', 'Pants', 'Leggings', 'Cargo Pants', 'Shorts', 'Skirts'],
      orderIndex: 2,
    ),
    WardrobeCategory(
      id: 'cat_ethnic',
      name: 'Ethnic wear',
      iconName: 'style',
      subcategories: ['Kurtas', 'Kurta Sets', 'Sarees', 'Dupattas', 'Lehengas', 'Anarkalis'],
      orderIndex: 3,
    ),
    WardrobeCategory(
      id: 'cat_dresses',
      name: 'Dresses',
      iconName: 'woman',
      subcategories: ['Midi Dresses', 'Maxi Dresses', 'Mini Dresses', 'Jumpsuits', 'Gowns'],
      orderIndex: 4,
    ),
    WardrobeCategory(
      id: 'cat_outerwear',
      name: 'Outerwear',
      iconName: 'accessibility_new',
      subcategories: ['Jackets', 'Denim Jackets', 'Coats', 'Cardigans', 'Shrugs', 'Blazers', 'Hoodies'],
      orderIndex: 5,
    ),
    WardrobeCategory(
      id: 'cat_activewear',
      name: 'Activewear',
      iconName: 'fitness_center',
      subcategories: ['Sports Bras', 'Gym Leggings', 'Track Pants', 'Athletic Tees', 'Shorts'],
      orderIndex: 6,
    ),
    WardrobeCategory(
      id: 'cat_innerwear',
      name: 'Innerwear',
      iconName: 'favorite_border',
      subcategories: ['Briefs', 'Bras', 'Camisoles', 'Shapewear', 'Thermal Wear'],
      orderIndex: 7,
    ),
    WardrobeCategory(
      id: 'cat_sleepwear',
      name: 'Sleepwear',
      iconName: 'bedtime',
      subcategories: ['Pyjamas', 'Nightgowns', 'Lounge Pants', 'Sleep Sets', 'Robes'],
      orderIndex: 8,
    ),
    WardrobeCategory(
      id: 'cat_footwear',
      name: 'Footwear',
      iconName: 'roller_skating',
      subcategories: ['Sneakers', 'Flats', 'Heels', 'Boots', 'Sandals', 'Loafers', 'Slippers'],
      orderIndex: 9,
    ),
    WardrobeCategory(
      id: 'cat_accessories',
      name: 'Accessories',
      iconName: 'watch',
      subcategories: ['Bags', 'Belts', 'Scarves', 'Jewelry', 'Sunglasses', 'Hats', 'Dupattas'],
      orderIndex: 10,
    ),
  ];
}


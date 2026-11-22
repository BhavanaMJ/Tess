import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tess/features/wardrobe/data/models/wardrobe_stats_model.dart';
import 'package:tess/features/wardrobe/domain/entities/category.dart';
import 'package:tess/features/wardrobe/domain/entities/garment.dart';
import 'package:tess/features/wardrobe/domain/entities/laundry_status.dart';
import 'package:tess/features/wardrobe/domain/entities/wardrobe_stats.dart';
import 'package:tess/features/wardrobe/domain/repositories/wardrobe_repository.dart';
import 'package:tess/features/wardrobe/presentation/controllers/wardrobe_controller.dart';
import 'package:tess/features/wardrobe/presentation/screens/garment_form_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/wardrobe_detail_screen.dart';

class MockWardrobeRepository implements WardrobeRepository {
  final Map<String, Garment> items = {};

  @override
  Future<List<Garment>> getGarments({
    String? category,
    LaundryStatus? laundryStatus,
    bool? favoritesOnly,
    String? search,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? limit,
  }) async {
    var list = items.values.toList();
    if (category != null) {
      list = list.where((g) => g.mainCategory.toLowerCase() == category.toLowerCase()).toList();
    }
    if (laundryStatus != null) {
      list = list.where((g) => g.laundryStatus == laundryStatus).toList();
    }
    if (favoritesOnly == true) {
      list = list.where((g) => g.isFavorite).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((g) => g.name.toLowerCase().contains(q) || g.primaryColor.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  Future<Garment?> getGarmentById(String id) async => items[id];

  @override
  Future<Garment> saveGarment(Garment garment) async {
    items[garment.id] = garment;
    return garment;
  }

  @override
  Future<Garment> updateGarment(Garment garment) async {
    items[garment.id] = garment;
    return garment;
  }

  @override
  Future<bool> deleteGarment(String id, {bool hardDelete = false}) async {
    items.remove(id);
    return true;
  }

  @override
  Future<Garment> updateLaundryStatus(String id, LaundryStatus status) async {
    final g = items[id]!;
    final updated = g.copyWith(laundryStatus: status);
    items[id] = updated;
    return updated;
  }

  @override
  Future<Garment> toggleFavorite(String id) async {
    final g = items[id]!;
    final updated = g.copyWith(isFavorite: !g.isFavorite);
    items[id] = updated;
    return updated;
  }

  @override
  Future<List<WardrobeCategory>> getCategories() async {
    return WardrobeCategory.defaultCategories;
  }

  @override
  Future<WardrobeStats> getStats() async {
    return WardrobeStats.fromGarments(items.values.toList());
  }

  @override
  Future<int> importInitialInventory(List<Garment> garments) async {
    for (final g in garments) {
      items[g.id] = g;
    }
    return garments.length;
  }
}

void main() {
  Widget buildTestApp(Widget child) {
    return MaterialApp(
      home: child,
      theme: ThemeData.dark(),
    );
  }

  group('Phase 2: WardrobeStats Entity & Model Tests', () {
    test('WardrobeStats correctly calculates counts from garments list', () {
      final now = DateTime.now();
      final garments = [
        Garment(
          id: '1',
          userId: 'u',
          name: 'Item 1',
          mainCategory: 'Tops',
          primaryColor: 'Blue',
          laundryStatus: LaundryStatus.clean,
          createdAt: now,
          updatedAt: now,
        ),
        Garment(
          id: '2',
          userId: 'u',
          name: 'Item 2',
          mainCategory: 'Bottoms',
          primaryColor: 'Black',
          laundryStatus: LaundryStatus.washing,
          createdAt: now,
          updatedAt: now,
        ),
        Garment(
          id: '3',
          userId: 'u',
          name: 'Item 3',
          mainCategory: 'Tops',
          primaryColor: 'White',
          laundryStatus: null, // unassigned
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final stats = WardrobeStats.fromGarments(garments);
      expect(stats.totalGarments, equals(3));
      expect(stats.cleanCount, equals(1));
      expect(stats.inLaundryCount, equals(1)); // washing counts towards inLaundry
      expect(stats.unassignedCount, equals(1));
    });

    test('WardrobeStatsModel serializes and deserializes JSON correctly', () {
      final json = {
        'total_garments': 18,
        'clean_count': 5,
        'worn_count': 2,
        'in_laundry_count': 3,
        'stored_count': 1,
        'unassigned_count': 7,
      };

      final model = WardrobeStatsModel.fromJson(json);
      expect(model.totalGarments, equals(18));
      expect(model.cleanCount, equals(5));
      expect(model.inLaundryCount, equals(3));
      expect(model.unassignedCount, equals(7));

      final serialized = model.toJson();
      expect(serialized['total_garments'], equals(18));
      expect(serialized['clean_count'], equals(5));
    });
  });

  group('Phase 2: WardrobeController Advanced Operations', () {
    late MockWardrobeRepository repo;
    late WardrobeController controller;

    setUp(() async {
      repo = MockWardrobeRepository();
      controller = WardrobeController(repository: repo);

      final now = DateTime.now();
      await repo.saveGarment(Garment(
        id: 'CLO-001',
        userId: 'u',
        name: 'Navy Cotton Shirt',
        mainCategory: 'Tops',
        primaryColor: 'Navy Blue',
        fabricMaterial: 'Cotton',
        sleeveLength: 'Full Sleeves',
        laundryStatus: LaundryStatus.clean,
        isFavorite: true,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ));

      await repo.saveGarment(Garment(
        id: 'CLO-002',
        userId: 'u',
        name: 'Black Slim Chinos',
        mainCategory: 'Bottoms',
        primaryColor: 'Black',
        fabricMaterial: 'Cotton Blend',
        laundryStatus: LaundryStatus.worn,
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
      ));

      await controller.loadInitialData();
    });

    test('Controller handles sorting and multi-factor filters correctly', () {
      expect(controller.garments.length, equals(2));

      // Test Category filter
      controller.setCategoryFilter('Tops');
      expect(controller.filteredGarments.length, equals(1));
      expect(controller.filteredGarments.first.name, equals('Navy Cotton Shirt'));

      // Clear Category filter
      controller.setCategoryFilter(null);
      expect(controller.filteredGarments.length, equals(2));

      // Test Laundry filter
      controller.setLaundryFilter(LaundryStatus.worn);
      expect(controller.filteredGarments.length, equals(1));
      expect(controller.filteredGarments.first.name, equals('Black Slim Chinos'));

      // Test Favorites Only filter
      controller.setLaundryFilter(null);
      controller.toggleFavoritesOnly();
      expect(controller.filteredGarments.length, equals(1));
      expect(controller.filteredGarments.first.name, equals('Navy Cotton Shirt'));

      // Test Active Filter Count
      expect(controller.activeFilterCount, equals(1));
      controller.clearAllFilters();
      expect(controller.activeFilterCount, equals(0));
      expect(controller.filteredGarments.length, equals(2));
    });

    test('Controller adds, updates, and deletes garments reactively', () async {
      final now = DateTime.now();
      final newGarment = Garment(
        id: 'CLO-003',
        userId: 'u',
        name: 'White Linen Shirt',
        mainCategory: 'Tops',
        primaryColor: 'White',
        fabricMaterial: 'Linen',
        createdAt: now,
        updatedAt: now,
      );

      // Add
      await controller.addGarment(newGarment);
      expect(controller.garments.length, equals(3));
      expect(controller.garments.any((g) => g.id == 'CLO-003'), isTrue);

      // Update
      final updated = newGarment.copyWith(name: 'White Italian Linen Shirt');
      await controller.updateGarment(updated);
      expect(controller.garments.firstWhere((g) => g.id == 'CLO-003').name, equals('White Italian Linen Shirt'));

      // Delete
      final deleted = await controller.deleteGarment('CLO-003');
      expect(deleted, isTrue);
      expect(controller.garments.length, equals(2));
      expect(controller.garments.any((g) => g.id == 'CLO-003'), isFalse);
    });
  });

  group('Phase 2: GarmentFormScreen UI & Validation Tests', () {
    testWidgets('renders add garment form with category-sensitive fields', (tester) async {
      final repo = MockWardrobeRepository();
      final controller = WardrobeController(repository: repo);

      await tester.pumpWidget(
        buildTestApp(
          GarmentFormScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Check Form Titles and Inputs
      expect(find.text('Add New Garment'), findsOneWidget);
      expect(find.text('GARMENT IDENTIFICATION'), findsOneWidget);
      expect(find.text('VISUAL & MATERIAL ATTRIBUTES'), findsOneWidget);
      expect(find.text('BRAND & PURCHASE DETAILS'), findsOneWidget);
      expect(find.text('LAUNDRY STATUS'), findsOneWidget);

      // Tops by default shows Sleeve Length
      expect(find.text('Sleeve Length'), findsOneWidget);

      // Submit without name should trigger validation
      final saveButton = find.text('Add to Wardrobe');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a garment name'), findsOneWidget);

      // Fill name and save
      await tester.enterText(find.byType(TextFormField).first, 'Emerald Green Blazer');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(controller.garments.length, equals(1));
      expect(controller.garments.first.name, equals('Emerald Green Blazer'));
    });
  });

  group('Phase 2: WardrobeDetailScreen UI Tests', () {
    testWidgets('renders garment specifications, status badge, and triggers actions', (tester) async {
      final repo = MockWardrobeRepository();
      final controller = WardrobeController(repository: repo);

      final now = DateTime.now();
      final garment = Garment(
        id: 'CLO-001',
        userId: 'u',
        name: 'Navy Blue Formal Blazer',
        mainCategory: 'Outerwear',
        subcategory: 'Blazer',
        primaryColor: 'Navy Blue',
        fabricMaterial: 'Wool Blend',
        brand: 'Hugo Boss',
        purchasePrice: 299.99,
        laundryStatus: LaundryStatus.clean,
        isFavorite: false,
        notes: 'Dry clean only',
        createdAt: now,
        updatedAt: now,
      );

      await repo.saveGarment(garment);
      await controller.loadInitialData();

      await tester.pumpWidget(
        buildTestApp(
          WardrobeDetailScreen(
            initialGarment: garment,
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and specs
      expect(find.text('CLO-001'), findsOneWidget);
      expect(find.text('Navy Blue Formal Blazer'), findsOneWidget);
      expect(find.text('Hugo Boss'), findsWidgets);
      expect(find.text('SPECIFICATIONS'), findsOneWidget);
      expect(find.text('Navy Blue'), findsWidgets);
      expect(find.text('Wool Blend'), findsOneWidget);
      expect(find.text('\$299.99'), findsOneWidget);
      expect(find.text('Dry clean only'), findsOneWidget);

      // Verify Actions
      expect(find.text('Update Status'), findsOneWidget);
      expect(find.text('Edit Details'), findsOneWidget);

      // Tap Update Status -> opens status bottom sheet
      await tester.tap(find.text('Update Status'));
      await tester.pumpAndSettle();
      expect(find.text('Update Status: Navy Blue Formal Blazer'), findsOneWidget);
      expect(find.text('Worn / In Hamper'), findsOneWidget);
    });
  });
}

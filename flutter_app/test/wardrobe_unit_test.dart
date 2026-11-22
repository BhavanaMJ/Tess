import 'package:flutter_test/flutter_test.dart';
import 'package:tess/features/wardrobe/data/fixtures/initial_inventory.dart';
import 'package:tess/features/wardrobe/data/models/category_model.dart';
import 'package:tess/features/wardrobe/data/models/garment_model.dart';
import 'package:tess/features/wardrobe/data/repositories/wardrobe_repository_impl.dart';
import 'package:tess/features/wardrobe/domain/entities/category.dart';
import 'package:tess/features/wardrobe/domain/entities/garment.dart';
import 'package:tess/features/wardrobe/domain/entities/laundry_status.dart';

void main() {
  group('Phase 1: Wardrobe Domain Models & LaundryStatus Tests', () {
    test('LaundryStatus parses confirmed operational values correctly', () {
      expect(LaundryStatus.fromString('CLEAN'), equals(LaundryStatus.clean));
      expect(LaundryStatus.fromString('clean'), equals(LaundryStatus.clean));
      expect(LaundryStatus.fromString('WORN'), equals(LaundryStatus.worn));
      expect(LaundryStatus.fromString('WASHING'), equals(LaundryStatus.washing));
      expect(LaundryStatus.fromString('DRYING'), equals(LaundryStatus.drying));
      expect(LaundryStatus.fromString('STORED'), equals(LaundryStatus.stored));
      expect(LaundryStatus.fromString(null), isNull);
      expect(LaundryStatus.fromString(''), isNull);
      expect(LaundryStatus.fromString('UNKNOWN_VAL'), isNull);
    });

    test('WardrobeCategory defaultCategories contains 10 standardized categories', () {
      const categories = WardrobeCategory.defaultCategories;
      expect(categories.length, equals(10));

      final names = categories.map((c) => c.name).toList();
      expect(names, containsAll([
        'Tops',
        'Bottoms',
        'Ethnic wear',
        'Dresses',
        'Outerwear',
        'Activewear',
        'Innerwear',
        'Sleepwear',
        'Footwear',
        'Accessories',
      ]));
    });

    test('GarmentModel serializes and deserializes snake_case JSON correctly', () {
      final now = DateTime.now();
      final garment = Garment(
        id: 'CLO-001',
        userId: 'usr_123',
        name: 'Yellow Printed Top',
        mainCategory: 'Tops',
        subcategory: 'Tunics',
        primaryColor: 'Yellow',
        secondaryColors: const ['Multicolor'],
        sleeveLength: '3/4 sleeves',
        pattern: 'Printed',
        laundryStatus: LaundryStatus.clean,
        isFavorite: true,
        createdAt: now,
        updatedAt: now,
      );

      final model = GarmentModel.fromDomain(garment);
      final json = model.toJson();

      expect(json['id'], equals('CLO-001'));
      expect(json['user_id'], equals('usr_123'));
      expect(json['name'], equals('Yellow Printed Top'));
      expect(json['main_category'], equals('Tops'));
      expect(json['subcategory'], equals('Tunics'));
      expect(json['primary_color'], equals('Yellow'));
      expect(json['secondary_colors'], equals(['Multicolor']));
      expect(json['sleeve_length'], equals('3/4 sleeves'));
      expect(json['laundry_status'], equals('CLEAN'));
      expect(json['is_favorite'], isTrue);

      final fromJsonModel = GarmentModel.fromJson(json);
      final restored = fromJsonModel.toDomain();

      expect(restored.id, equals(garment.id));
      expect(restored.userId, equals(garment.userId));
      expect(restored.name, equals(garment.name));
      expect(restored.mainCategory, equals(garment.mainCategory));
      expect(restored.sleeveLength, equals('3/4 sleeves'));
      expect(restored.laundryStatus, equals(LaundryStatus.clean));
      expect(restored.isFavorite, isTrue);
    });

    test('GarmentModel handles null/optional attributes safely without exception', () {
      final json = <String, dynamic>{
        'id': 'CLO-TEST',
        'user_id': 'usr_test',
        'name': 'Minimal Garment',
        'main_category': 'Outerwear',
        'primary_color': 'Black',
      };

      final model = GarmentModel.fromJson(json);
      final garment = model.toDomain();

      expect(garment.id, equals('CLO-TEST'));
      expect(garment.name, equals('Minimal Garment'));
      expect(garment.subcategory, isNull);
      expect(garment.sleeveLength, isNull);
      expect(garment.laundryStatus, isNull);
      expect(garment.isFavorite, isFalse);
      expect(garment.secondaryColors, isEmpty);
      expect(garment.hasConfirmedLaundryStatus, isFalse);
    });

    test('WardrobeCategoryModel serializes and deserializes correctly', () {
      const cat = WardrobeCategory(
        id: 'cat_custom',
        name: 'Athleisure',
        subcategories: ['Hoodies', 'Joggers'],
        orderIndex: 5,
      );

      final model = WardrobeCategoryModel.fromDomain(cat);
      final json = model.toJson();

      expect(json['id'], equals('cat_custom'));
      expect(json['name'], equals('Athleisure'));
      expect(json['subcategories'], equals(['Hoodies', 'Joggers']));

      final parsed = WardrobeCategoryModel.fromJson(json).toDomain();
      expect(parsed.id, equals(cat.id));
      expect(parsed.name, equals(cat.name));
      expect(parsed.subcategories, equals(cat.subcategories));
    });
  });

  group('Phase 1: Initial Inventory Migration & Corrections Tests', () {
    test('InitialInventoryFixture contains exactly 18 garments with CLO-001..CLO-018', () {
      final items = InitialInventoryFixture.getInitialGarments('user_test_999');
      expect(items.length, equals(18));

      final ids = items.map((g) => g.id).toList();
      for (int i = 1; i <= 18; i++) {
        final expectedId = 'CLO-${i.toString().padLeft(3, '0')}';
        expect(ids, contains(expectedId));
      }
    });

    test('InitialInventoryFixture enforces required sleeve length attribute corrections', () {
      final items = InitialInventoryFixture.getInitialGarments('user_test_999');
      final map = {for (final g in items) g.id: g};

      // CLO-001: 3/4 sleeves
      expect(map['CLO-001']?.sleeveLength, equals('3/4 sleeves'));
      // CLO-002: Sleeveless
      expect(map['CLO-002']?.sleeveLength, equals('Sleeveless'));
      // CLO-003: 3/4 sleeves
      expect(map['CLO-003']?.sleeveLength, equals('3/4 sleeves'));
      // CLO-010: 3/4 sleeves
      expect(map['CLO-010']?.sleeveLength, equals('3/4 sleeves'));
      // CLO-011: 3/4 sleeves
      expect(map['CLO-011']?.sleeveLength, equals('3/4 sleeves'));
      // CLO-012: 3/4 sleeves
      expect(map['CLO-012']?.sleeveLength, equals('3/4 sleeves'));
      // CLO-013: 3/4 sleeves
      expect(map['CLO-013']?.sleeveLength, equals('3/4 sleeves'));
    });

    test('InitialInventoryFixture preserves explicitly unset/null laundry status', () {
      final items = InitialInventoryFixture.getInitialGarments('user_test_999');
      for (final garment in items) {
        expect(garment.laundryStatus, isNull,
            reason: '${garment.id} must have unassigned initial laundry status');
        expect(garment.hasConfirmedLaundryStatus, isFalse);
      }
    });
  });

  group('Phase 1: WardrobeRepository Offline/Local Behavior Tests', () {
    test('WardrobeRepositoryImpl saves, updates, toggles favorite, and filters', () async {
      final repo = WardrobeRepositoryImpl();

      final initial = await repo.getGarments();
      expect(initial, isEmpty);

      // Save a garment
      final now = DateTime.now();
      final g1 = Garment(
        id: 'CLO-001',
        userId: 'u1',
        name: 'Yellow Printed Top',
        mainCategory: 'Tops',
        primaryColor: 'Yellow',
        createdAt: now,
        updatedAt: now,
      );
      await repo.saveGarment(g1);

      final fetched = await repo.getGarmentById('CLO-001');
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Yellow Printed Top'));
      expect(fetched.isFavorite, isFalse);

      // Toggle favorite
      final favorited = await repo.toggleFavorite('CLO-001');
      expect(favorited.isFavorite, isTrue);

      // Update laundry status
      final washed = await repo.updateLaundryStatus('CLO-001', LaundryStatus.clean);
      expect(washed.laundryStatus, equals(LaundryStatus.clean));

      // Import batch of initial inventory
      final initialBatch = InitialInventoryFixture.getInitialGarments('u1');
      final count = await repo.importInitialInventory(initialBatch);
      expect(count, equals(18));

      final allGarments = await repo.getGarments();
      expect(allGarments.length, equals(18));

      // Category filter
      final tops = await repo.getGarments(category: 'Tops');
      expect(tops.every((g) => g.mainCategory == 'Tops'), isTrue);

      // Delete garment
      final deleted = await repo.deleteGarment('CLO-018');
      expect(deleted, isTrue);
      final remaining = await repo.getGarments();
      expect(remaining.length, equals(17));
    });
  });
}

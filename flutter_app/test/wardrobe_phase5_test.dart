import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tess/core/theme/app_theme.dart';
import 'package:tess/features/wardrobe/data/models/outfit_model.dart';
import 'package:tess/features/wardrobe/data/models/outfit_recommendation_model.dart';
import 'package:tess/features/wardrobe/data/repositories/outfit_repository_impl.dart';
import 'package:tess/features/wardrobe/domain/entities/garment.dart';
import 'package:tess/features/wardrobe/domain/entities/laundry_status.dart';
import 'package:tess/features/wardrobe/domain/entities/outfit.dart';
import 'package:tess/features/wardrobe/domain/entities/outfit_item.dart';
import 'package:tess/features/wardrobe/presentation/controllers/outfit_controller.dart';
import 'package:tess/features/wardrobe/presentation/screens/automatic_outfits_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/guided_styling_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/manual_outfit_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/outfit_detail_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/outfit_studio_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/saved_outfits_screen.dart';
import 'package:tess/features/wardrobe/presentation/widgets/garment_selection_grid.dart';
import 'package:tess/features/wardrobe/presentation/widgets/outfit_card.dart';
import 'package:tess/features/wardrobe/presentation/widgets/outfit_occasion_selector.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: child,
    );
  }

  const testOutfitItem1 = OutfitItem(
    garmentId: 'CLO-001',
    name: 'Navy Oxford Shirt',
    mainCategory: 'Tops',
    primaryColor: 'Navy Blue',
    laundryStatus: LaundryStatus.clean,
    isEligible: true,
  );

  const testOutfitItem2 = OutfitItem(
    garmentId: 'CLO-008',
    name: 'Beige Chinos',
    mainCategory: 'Bottoms',
    primaryColor: 'Beige',
    laundryStatus: LaundryStatus.clean,
    isEligible: true,
  );

  final testOutfit = Outfit(
    id: 'outfit_test_1',
    userId: 'u1',
    name: 'Business Casual Set',
    description: 'Perfect for client meetings',
    occasion: 'Office',
    isFavourite: true,
    creationSource: OutfitSource.manual,
    stylingExplanation: 'Crisp navy shirt complements structured beige chinos.',
    wearCount: 2,
    items: [testOutfitItem1, testOutfitItem2],
    garmentIds: const ['CLO-001', 'CLO-008'],
    isAvailable: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('Outfit Domain & Models Serialization', () {
    test('OutfitModel and OutfitItemModel roundtrip', () {
      final json = {
        'id': 'outfit_123',
        'user_id': 'u1',
        'name': 'Casual Weekend',
        'description': 'T-shirt and shorts',
        'occasion': 'Casual',
        'notes': 'Summer staple',
        'is_favourite': true,
        'creation_source': 'AUTOMATIC',
        'styling_explanation': 'Complementary summer palette.',
        'wear_count': 1,
        'last_worn_date': '2026-11-22T10:00:00Z',
        'items': [
          {
            'garment_id': 'CLO-001',
            'name': 'T-Shirt',
            'main_category': 'Tops',
            'primary_color': 'White',
            'secondary_colors': [],
            'laundry_status': 'CLEAN',
            'is_eligible': true,
          }
        ],
        'garment_ids': ['CLO-001'],
        'is_available': true,
        'unavailable_reasons': [],
        'created_at': '2026-11-22T08:00:00Z',
        'updated_at': '2026-11-22T08:00:00Z',
      };

      final model = OutfitModel.fromJson(json);
      expect(model.id, 'outfit_123');
      expect(model.creationSource, 'AUTOMATIC');
      expect(model.items.length, 1);

      final domain = model.toDomain();
      expect(domain.creationSource, OutfitSource.automatic);
      expect(domain.items.first.laundryStatus, LaundryStatus.clean);

      final backToJson = model.toJson();
      expect(backToJson['name'], 'Casual Weekend');
      expect(backToJson['is_favourite'], true);
    });

    test('OutfitRecommendationModel fromJson and toDomain', () {
      final json = {
        'id': 'rec_456',
        'name': 'Autumn Layers',
        'occasion': 'Casual',
        'explanation': 'Warm tones ideal for fall.',
        'garment_ids': ['CLO-001', 'CLO-002'],
        'is_available': true,
        'combination_fingerprint': 'CLO-001:CLO-002',
        'garments': [
          {
            'garment_id': 'CLO-001',
            'name': 'Shirt',
            'main_category': 'Tops',
            'primary_color': 'Blue',
            'is_eligible': true,
          }
        ],
      };

      final model = OutfitRecommendationModel.fromJson(json);
      expect(model.id, 'rec_456');
      final domain = model.toDomain();
      expect(domain.explanation, 'Warm tones ideal for fall.');
      expect(domain.isAvailable, true);
    });
  });

  group('Outfit Widgets Tests', () {
    testWidgets('OutfitOccasionSelector renders chips and triggers onSelected',
        (tester) async {
      String selected = 'Casual';
      await tester.pumpWidget(
        buildTestableWidget(
          OutfitOccasionSelector(
            selectedOccasion: selected,
            showAllOption: true,
            onSelected: (occ) => selected = occ,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Casual'), findsOneWidget);
      expect(find.text('Office'), findsOneWidget);

      await tester.tap(find.text('Office'));
      await tester.pumpAndSettle();
      expect(selected, 'Office');
    });

    testWidgets(
        'OutfitCard renders title, badges, explanation, and action callbacks',
        (tester) async {
      bool wearTapped = false;
      bool saveTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          OutfitCard(
            title: 'Summer Breeze',
            occasion: 'Casual',
            explanation: 'Light pastel tones for sunny weather.',
            garments: const [testOutfitItem1, testOutfitItem2],
            isAvailable: true,
            wearCount: 3,
            onWear: () => wearTapped = true,
            onSave: () => saveTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Summer Breeze'), findsOneWidget);
      expect(find.text('CASUAL'), findsOneWidget);
      expect(find.text('READY'), findsOneWidget);
      expect(find.text('Worn 3x'), findsOneWidget);
      expect(
          find.text('Light pastel tones for sunny weather.'), findsOneWidget);

      await tester.tap(find.text('Save Outfit'));
      await tester.pumpAndSettle();
      expect(saveTapped, true);

      await tester.tap(find.text('Wear Outfit'));
      await tester.pumpAndSettle();
      expect(wearTapped, true);
    });

    testWidgets('GarmentSelectionGrid renders items and handles toggle',
        (tester) async {
      final garments = [
        Garment(
          id: 'CLO-001',
          userId: 'u1',
          name: 'Navy Shirt',
          mainCategory: 'Tops',
          primaryColor: 'Navy',
          laundryStatus: LaundryStatus.clean,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Garment(
          id: 'CLO-008',
          userId: 'u1',
          name: 'Grey Pants',
          mainCategory: 'Bottoms',
          primaryColor: 'Grey',
          laundryStatus: LaundryStatus.worn,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final selected = <String>['CLO-001'];
      Garment? toggled;

      await tester.pumpWidget(
        buildTestableWidget(
          GarmentSelectionGrid(
            garments: garments,
            selectedGarmentIds: selected,
            onToggleGarment: (g) => toggled = g,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Navy Shirt'), findsOneWidget);
      expect(find.text('Grey Pants'), findsOneWidget);
      expect(find.text('Clean & Ready'), findsOneWidget);
      expect(find.text('Worn / In Hamper'), findsOneWidget);

      await tester.tap(find.text('Grey Pants'));
      await tester.pumpAndSettle();
      expect(toggled?.id, 'CLO-008');
    });
  });

  group('OutfitController Workflow Tests', () {
    test(
        'creates outfit, loads saved looks, toggles favourite, and wears outfit',
        () async {
      final repo = OutfitRepositoryImpl();
      final controller = OutfitController(repository: repo);

      // 1. Initial State
      expect(controller.savedOutfits, isEmpty);

      // 2. Save Outfit
      final saved = await controller.saveOutfit(
        name: 'Monochrome Set',
        occasion: 'Formal',
        garmentIds: const ['CLO-001', 'CLO-008'],
      );
      expect(saved, isNotNull);
      expect(controller.savedOutfits.length, 1);
      expect(controller.savedOutfits.first.name, 'Monochrome Set');

      // 3. Toggle favourite
      await controller.toggleFavourite(saved!);
      expect(controller.savedOutfits.first.isFavourite, true);

      // 4. Wear Outfit
      final wornOk = await controller.wearOutfit(saved.id);
      expect(wornOk, true);

      // 5. Automatic Recommendations
      await controller.generateRecommendations();
      expect(controller.recommendations, isNotEmpty);

      // 6. Guided Styling
      await controller.generateGuidedStyling('CLO-001');
      expect(controller.guidedRecommendations, isNotEmpty);

      // 7. Manual Builder Selection & Validation
      controller.toggleGarmentSelection('CLO-001');
      controller.toggleGarmentSelection('CLO-008');
      expect(controller.manualSelectedGarmentIds.length, 2);
      await controller.validateManualSelection();
      expect(controller.manualValidationResult?['is_valid'], true);

      // 8. Delete Outfit
      final delOk = await controller.deleteOutfit(saved.id);
      expect(delOk, true);
      expect(controller.savedOutfits, isEmpty);
    });
  });

  group('Outfit Screens UI Tests', () {
    testWidgets('OutfitStudioScreen renders mode cards and lookbook link',
        (tester) async {
      final repo = OutfitRepositoryImpl();
      final controller = OutfitController(repository: repo);

      await tester.pumpWidget(
        buildTestableWidget(
          OutfitStudioScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Outfit Studio'), findsOneWidget);
      expect(find.text('AI Personal Stylist'), findsOneWidget);
      expect(find.text('Automatic Suggestions'), findsOneWidget);
      expect(find.text('Guided Styling'), findsOneWidget);
      expect(find.text('Manual Outfit Builder'), findsOneWidget);
      expect(find.text('Saved Outfits & Lookbook'), findsOneWidget);
    });

    testWidgets('AutomaticOutfitsScreen renders recommendations',
        (tester) async {
      final repo = OutfitRepositoryImpl();
      final controller = OutfitController(repository: repo);

      await tester.pumpWidget(
        buildTestableWidget(
          AutomaticOutfitsScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Automatic Suggestions'), findsOneWidget);
      expect(find.byType(OutfitOccasionSelector), findsOneWidget);
    });

    testWidgets('GuidedStylingScreen renders garment grid initially',
        (tester) async {
      final repo = OutfitRepositoryImpl();
      final controller = OutfitController(repository: repo);

      await tester.pumpWidget(
        buildTestableWidget(
          GuidedStylingScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select Key Garment'), findsOneWidget);
    });

    testWidgets('ManualOutfitScreen renders category chips and validation',
        (tester) async {
      final repo = OutfitRepositoryImpl();
      final controller = OutfitController(repository: repo);

      await tester.pumpWidget(
        buildTestableWidget(
          ManualOutfitScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manual Outfit Builder'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Tops'), findsOneWidget);
    });

    testWidgets('SavedOutfitsScreen renders search and empty lookbook state',
        (tester) async {
      final repo = OutfitRepositoryImpl();
      final controller = OutfitController(repository: repo);

      await tester.pumpWidget(
        buildTestableWidget(
          SavedOutfitsScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saved Lookbook'), findsOneWidget);
      expect(find.text('Search saved looks...'), findsOneWidget);
      expect(find.text('No saved outfits yet'), findsOneWidget);
    });

    testWidgets(
        'OutfitDetailScreen renders constituent garments and wear action',
        (tester) async {
      final repo = OutfitRepositoryImpl();
      final controller = OutfitController(repository: repo);

      await tester.pumpWidget(
        buildTestableWidget(
          OutfitDetailScreen(outfit: testOutfit, controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Business Casual Set'), findsOneWidget);
      expect(find.text('OFFICE'), findsOneWidget);
      expect(find.text('CONSTITUENT GARMENTS'), findsOneWidget);
      expect(find.text('Navy Oxford Shirt'), findsOneWidget);
      expect(find.text('Beige Chinos'), findsOneWidget);
      expect(find.text('Wear This Look Today'), findsOneWidget);
    });
  });
}

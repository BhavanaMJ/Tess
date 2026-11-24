import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tess/core/theme/app_theme.dart';
import 'package:tess/features/wardrobe/data/models/garment_metadata_model_v1_1.dart';
import 'package:tess/features/wardrobe/domain/entities/garment.dart';
import 'package:tess/features/wardrobe/domain/entities/garment_metadata_v1_1.dart';
import 'package:tess/features/wardrobe/domain/repositories/wardrobe_import_repository.dart';
import 'package:tess/features/wardrobe/presentation/controllers/garment_import_controller.dart';
import 'package:tess/features/wardrobe/presentation/screens/garment_import_wizard_screen.dart';
import 'package:tess/features/wardrobe/presentation/widgets/import_stage1_prepare.dart';
import 'package:tess/features/wardrobe/presentation/widgets/import_stage2_catalogue.dart';
import 'package:tess/features/wardrobe/presentation/widgets/import_stage3_json.dart';
import 'package:tess/features/wardrobe/presentation/widgets/import_stage4_review.dart';

/// Test mock implementation of WardrobeImportRepository
class MockWardrobeImportRepository implements WardrobeImportRepository {
  bool shouldFailValidation = false;
  bool shouldFailUpload = false;
  bool shouldFailRegister = false;

  int uploadCallCount = 0;
  int registerCallCount = 0;

  final Map<String, dynamic> _savedDrafts = {};

  final String validSampleJson = jsonEncode({
    "schema_version": "1.1",
    "record_type": "garment",
    "identity": {
      "garment_name": "Midnight Indigo Kurta",
      "category": "Tops",
      "subcategory": "Kurta",
      "garment_type": "Long Kurta",
      "description": "Handloom deep indigo straight-cut kurta with mandarin collar.",
      "gender_section": "Unisex",
      "custom_category": null,
    },
    "appearance": {
      "primary_colour": "Indigo",
      "secondary_colours": ["Silver", "Navy"],
      "colour_family": "Blue",
      "pattern": "Solid with micro-weave",
      "visual_texture": "Subtle slub texture",
      "opacity": "Opaque",
      "sheen": "Matte",
    },
    "construction": {
      "neckline": "Mandarin Collar",
      "sleeve_length": "Full Sleeve",
      "sleeve_type": "Straight",
      "fit": "Regular",
      "silhouette": "Straight cut",
      "garment_length": "Knee Length",
      "collar_type": "Band Collar",
      "cuff_type": "Single button",
      "hemline": "Straight with side slits",
      "closure_type": "Front placket with coconut shell buttons",
      "pocket_configuration": "Two side in-seam pockets",
      "lining": "Unlined",
      "waist_rise": null,
    },
    "material": {
      "fabric_appearance": "Handwoven Khadi Cotton",
      "primary_material": "Cotton",
      "fabric_composition": "100% Khadi Cotton",
      "fabric_weight": "Medium",
      "stretch": "Non-stretch",
      "drape": "Structured",
    },
    "sizing": {
      "labelled_size": "L",
      "standardized_size": "L",
      "fit_notes": "Comfortable relaxed fit around chest and shoulders.",
      "measurements_cm": {"chest": 108.0, "length": 105.0},
    },
    "usage": {
      "occasions": ["Festive", "Smart Casual", "Family Gathering"],
      "seasons": ["Spring", "Summer", "Autumn"],
      "formality_level": "Semi-formal",
      "style_aesthetic": ["Traditional", "Handloom", "Minimalist"],
    },
    "purchase": {
      "brand": "Fabindia",
      "purchase_price": 2499.0,
      "purchase_currency": "INR",
      "purchase_source": "Retail Store",
    },
    "care": {
      "washing_method": "Hand wash cold separately",
      "drying_method": "Line dry in shade",
      "care_precautions": "First two washes may bleed excess natural indigo dye.",
    },
    "physical_location": {
      "storage_location": "Main Wardrobe, Hanger #12",
      "storage_section": "Ethnic Wear",
    },
    "category_specific": {
      "slit_type": "Deep side slits",
      "placket_length_cm": 25.0,
    },
    "ai_metadata": {
      "detection_source": "chatgpt_project",
      "model_name": "GPT-4o (TESS Custom Project)",
      "processing_timestamp": "2026-11-24T18:00:00Z",
    },
    "visual_assets": {
      "original_image_description": "Garment laid flat on bed before catalogue generation.",
      "catalogue_image_description": "Studio catalogue shot with clean white background.",
      "catalogue_image_generated": true,
      "original_image_preserved": true,
    },
  });

  @override
  Future<MetadataValidationResult> validateMetadata({
    String? rawJson,
    Map<String, dynamic>? metadata,
  }) async {
    if (shouldFailValidation) {
      return const MetadataValidationResult(
        isValid: false,
        errors: ['Server validation rejection: Invalid schema payload'],
      );
    }

    if (rawJson != null) {
      return GarmentMetadataModelV1_1.validateJsonString(rawJson);
    } else if (metadata != null) {
      return GarmentMetadataModelV1_1.validateJsonMap(metadata);
    }
    return const MetadataValidationResult(
      isValid: false,
      errors: ['No JSON or metadata map provided'],
    );
  }

  @override
  Future<String> uploadImage({
    required List<int> fileBytes,
    required String filename,
    required String imageType,
  }) async {
    if (shouldFailUpload) throw Exception('Image upload failed');
    uploadCallCount++;
    return 'uploaded_${imageType}_ref_$filename';
  }

  @override
  Future<Garment> registerGarment({
    required String catalogueImageRef,
    String? originalImageRef,
    required GarmentMetadataV1_1 metadata,
  }) async {
    if (shouldFailRegister) throw Exception('Registration failed on backend');
    registerCallCount++;

    return Garment(
      id: 'CLO-099',
      userId: 'test_user_1',
      name: metadata.identity.garmentName ?? 'Untitled Garment',
      mainCategory: metadata.identity.category ?? 'Tops',
      subcategory: metadata.identity.subcategory,
      primaryColor: metadata.appearance.primaryColour ?? 'Indigo',
      secondaryColors: metadata.appearance.secondaryColours,
      pattern: metadata.appearance.pattern,
      fabricMaterial: metadata.material.fabricAppearance,
      fit: metadata.construction.fit,
      seasons: metadata.usage.seasons,
      processedImageRef: catalogueImageRef,
      originalImageRef: originalImageRef,
      notes: metadata.identity.description,
      brand: metadata.purchase.brand,
      size: metadata.sizing.labelledSize,
      laundryStatus: null, // Critical requirement: initially null
      isFavorite: false,
      wearCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> saveDraft(String userId, Map<String, dynamic> draftData) async {
    _savedDrafts[userId] = draftData;
  }

  @override
  Future<Map<String, dynamic>?> loadDraft(String userId) async {
    return _savedDrafts[userId];
  }

  @override
  Future<void> clearDraft(String userId) async {
    _savedDrafts.remove(userId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GarmentMetadataModelV1_1 & Entity Tests', () {
    final mockRepo = MockWardrobeImportRepository();

    test('validates and parses complete Schema 1.1 JSON', () {
      final result = GarmentMetadataModelV1_1.validateJsonString(mockRepo.validSampleJson);

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
      expect(result.entity, isNotNull);

      final entity = result.entity!;
      expect(entity.schemaVersion, '1.1');
      expect(entity.recordType, 'garment');
      expect(entity.identity.garmentName, 'Midnight Indigo Kurta');
      expect(entity.identity.category, 'Tops');
      expect(entity.identity.subcategory, 'Kurta');
      expect(entity.appearance.primaryColour, 'Indigo');
      expect(entity.appearance.secondaryColours, ['Silver', 'Navy']);
      expect(entity.construction.neckline, 'Mandarin Collar');
      expect(entity.construction.sleeveLength, 'Full Sleeve');
      expect(entity.material.fabricAppearance, 'Handwoven Khadi Cotton');
      expect(entity.sizing.labelledSize, 'L');
      expect(entity.usage.occasions, contains('Festive'));
      expect(entity.usage.formalityLevel, 'Semi-formal');
      expect(entity.purchase.brand, 'Fabindia');
      expect(entity.care.washingMethod, 'Hand wash cold separately');
      expect(entity.physicalLocation.storageSection, 'Ethnic Wear');
      expect(entity.categorySpecific['slit_type'], 'Deep side slits');
      expect(entity.aiMetadata.modelName, 'GPT-4o (TESS Custom Project)');
      expect(entity.visualAssets.catalogueImageGenerated, isTrue);
    });

    test('rejects malformed JSON syntax gracefully', () {
      const brokenJson = '{ "schema_version": "1.1", "record_type": "garment", ';
      final result = GarmentMetadataModelV1_1.validateJsonString(brokenJson);

      expect(result.isValid, isFalse);
      expect(result.errors.first, contains('Your metadata JSON is invalid'));
      expect(result.entity, isNull);
    });

    test('rejects unsupported schema version', () {
      final invalidVersionJson = jsonEncode({
        "schema_version": "1.0",
        "record_type": "garment",
        "identity": {"garment_name": "Shirt", "category": "Tops"},
      });
      final result = GarmentMetadataModelV1_1.validateJsonString(invalidVersionJson);

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains("Expected '1.1'")), isTrue);
    });

    test('rejects invalid record_type', () {
      final invalidTypeJson = jsonEncode({
        "schema_version": "1.1",
        "record_type": "outfit",
        "identity": {"garment_name": "Shirt", "category": "Tops"},
      });
      final result = GarmentMetadataModelV1_1.validateJsonString(invalidTypeJson);

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains("Expected 'garment'")), isTrue);
    });

    test('rejects missing or empty garment name', () {
      final missingNameJson = jsonEncode({
        "schema_version": "1.1",
        "record_type": "garment",
        "identity": {"garment_name": "  ", "category": "Tops"},
      });
      final result = GarmentMetadataModelV1_1.validateJsonString(missingNameJson);

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('Please provide a garment name')), isTrue);
    });

    test('rejects unrecognized category without custom_category', () {
      final unknownCatJson = jsonEncode({
        "schema_version": "1.1",
        "record_type": "garment",
        "identity": {"garment_name": "Space Helmet", "category": "Astronaut Gear"},
      });
      final result = GarmentMetadataModelV1_1.validateJsonString(unknownCatJson);

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('Select a supported garment category')), isTrue);
    });

    test('accepts unrecognized category when custom_category is provided', () {
      final customCatJson = jsonEncode({
        "schema_version": "1.1",
        "record_type": "garment",
        "identity": {
          "garment_name": "Space Helmet",
          "category": "Other",
          "custom_category": "Astronaut Gear",
        },
      });
      final result = GarmentMetadataModelV1_1.validateJsonString(customCatJson);

      expect(result.isValid, isTrue);
      expect(result.entity?.identity.customCategory, 'Astronaut Gear');
    });

    test('entity toJson and fromJson roundtrip preserves all 12 sections', () {
      final parseResult = GarmentMetadataModelV1_1.validateJsonString(mockRepo.validSampleJson);
      final entity = parseResult.entity!;
      final map = GarmentMetadataModelV1_1.toJson(entity);
      final reconstructed = GarmentMetadataModelV1_1.fromJson(map);

      expect(reconstructed.identity.garmentName, entity.identity.garmentName);
      expect(reconstructed.appearance.primaryColour, entity.appearance.primaryColour);
      expect(reconstructed.construction.neckline, entity.construction.neckline);
      expect(reconstructed.material.fabricAppearance, entity.material.fabricAppearance);
      expect(reconstructed.sizing.labelledSize, entity.sizing.labelledSize);
      expect(reconstructed.usage.occasions, entity.usage.occasions);
      expect(reconstructed.purchase.brand, entity.purchase.brand);
      expect(reconstructed.care.washingMethod, entity.care.washingMethod);
      expect(reconstructed.physicalLocation.storageSection, entity.physicalLocation.storageSection);
      expect(reconstructed.categorySpecific, entity.categorySpecific);
      expect(reconstructed.aiMetadata.modelName, entity.aiMetadata.modelName);
      expect(reconstructed.visualAssets.catalogueImageGenerated, entity.visualAssets.catalogueImageGenerated);
    });
  });

  group('GarmentImportController Tests', () {
    late MockWardrobeImportRepository mockRepo;
    late GarmentImportController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockRepo = MockWardrobeImportRepository();
      controller = GarmentImportController(
        repository: mockRepo,
        userId: 'test_user_1',
      );
    });

    test('initial state is at Step 0 with no assets or metadata', () {
      expect(controller.currentStep, 0);
      expect(controller.hasOriginalImage, isFalse);
      expect(controller.hasCatalogueImage, isFalse);
      expect(controller.rawJson, isEmpty);
      expect(controller.metadata, isNull);
      expect(controller.registeredGarment, isNull);
    });

    test('step navigation honors validation and catalogue image guard', () {
      // Step 0 -> Step 1 is allowed
      controller.goToStep(1);
      expect(controller.currentStep, 1);

      // Step 1 -> Step 2 is blocked if no catalogue image
      controller.goToStep(2);
      expect(controller.currentStep, 1);
      expect(controller.errorMessage, contains('catalogue image'));

      // Provide catalogue image -> advance allowed
      controller.setCatalogueImageBytes([1, 2, 3, 4], 'kurta_studio.jpg');
      expect(controller.hasCatalogueImage, isTrue);
      controller.goToStep(2);
      expect(controller.currentStep, 2);

      // Step 2 -> Step 3 requires valid metadata
      controller.goToStep(3);
      expect(controller.currentStep, 2);
      expect(controller.errorMessage, contains('valid'));
    });

    test('validating valid JSON advances successfully to metadata object', () async {
      controller.setRawJson(mockRepo.validSampleJson);
      final ok = await controller.validateMetadata();

      expect(ok, isTrue);
      expect(controller.validationErrors, isEmpty);
      expect(controller.metadata, isNotNull);
      expect(controller.metadata?.identity.garmentName, 'Midnight Indigo Kurta');
    });

    test('metadata updates in Stage 4 notify listeners and update model', () async {
      controller.setRawJson(mockRepo.validSampleJson);
      await controller.validateMetadata();

      final current = controller.metadata!;
      final updated = current.copyWith(
        appearance: current.appearance.copyWith(primaryColour: 'Deep Royal Blue'),
      );
      controller.updateMetadata(updated);

      expect(controller.metadata?.appearance.primaryColour, 'Deep Royal Blue');
    });

    test('registerGarment enforces mandatory catalogue image and initial null laundry status', () async {
      // Valid JSON
      controller.setRawJson(mockRepo.validSampleJson);
      await controller.validateMetadata();

      // No catalogue image yet -> registration blocked
      var success = await controller.registerGarment();
      expect(success, isFalse);
      expect(controller.errorMessage, contains('catalogue image'));

      // Provide catalogue image and optional original image
      controller.setCatalogueImageBytes([10, 20, 30], 'studio_shot.jpg');
      controller.setOriginalImageBytes([40, 50, 60], 'phone_pic.jpg');

      success = await controller.registerGarment();
      expect(success, isTrue);
      expect(controller.registeredGarment, isNotNull);

      final garment = controller.registeredGarment!;
      expect(garment.id, 'CLO-099');
      expect(garment.name, 'Midnight Indigo Kurta');
      // Crucial constraint: laundry status MUST be null upon import
      expect(garment.laundryStatus, isNull);
      expect(garment.processedImageRef, contains('studio_shot.jpg'));
      expect(garment.originalImageRef, contains('phone_pic.jpg'));
      expect(mockRepo.uploadCallCount, 2);
      expect(mockRepo.registerCallCount, 1);
    });

    test('draft persistence saves and restores state across controller instances', () async {
      controller.setOriginalUserNotes('Purchased in Jaipur trip 2024');
      controller.setRawJson(mockRepo.validSampleJson);
      await controller.validateMetadata();
      await controller.saveDraft();

      // New controller instance loading same userId draft
      final freshController = GarmentImportController(
        repository: mockRepo,
        userId: 'test_user_1',
      );
      final loaded = await freshController.loadDraftIfExists();

      expect(loaded, isTrue);
      expect(freshController.originalUserNotes, 'Purchased in Jaipur trip 2024');
      expect(freshController.rawJson, mockRepo.validSampleJson);
      expect(freshController.metadata?.identity.garmentName, 'Midnight Indigo Kurta');
    });
  });

  group('Phase 3.4 Import UI Widgets Tests', () {
    late MockWardrobeImportRepository mockRepo;
    late GarmentImportController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockRepo = MockWardrobeImportRepository();
      controller = GarmentImportController(
        repository: mockRepo,
        userId: 'test_user_1',
      );
    });

    Widget wrapWithTheme(Widget child) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(body: child),
      );
    }

    testWidgets('ImportStage1Prepare renders instructions banner and notes field', (tester) async {
      await tester.pumpWidget(wrapWithTheme(ImportStage1Prepare(controller: controller)));

      expect(find.text('Use ChatGPT to Create Catalogue & Metadata'), findsOneWidget);
      expect(find.textContaining('TESS — AI GARMENT CATALOGUE & METADATA GENERATOR'), findsOneWidget);
      expect(find.text('OPTIONAL NOTES'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('ImportStage2Catalogue displays mandatory banner and studio upload card', (tester) async {
      await tester.pumpWidget(wrapWithTheme(ImportStage2Catalogue(controller: controller)));

      expect(find.textContaining('MANDATORY'), findsOneWidget);
      expect(find.text('Import Studio Catalogue Photograph'), findsOneWidget);
      expect(find.text('REQUIRED'), findsOneWidget);
    });

    testWidgets('ImportStage3Json displays JSON input area and validate trigger', (tester) async {
      await tester.pumpWidget(wrapWithTheme(ImportStage3Json(controller: controller)));

      expect(find.text('Import Metadata JSON (Schema 1.1)'), findsOneWidget);
      expect(find.text('Paste JSON'), findsOneWidget);
      expect(find.text('Format'), findsOneWidget);
      expect(find.text('Validate Schema 1.1'), findsOneWidget);
    });

    testWidgets('ImportStage4Review displays provenance badge, cards, and registration confirmation', (tester) async {
      // 1x1 transparent PNG bytes
      final testPng = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAA=');
      controller.setCatalogueImageBytes(testPng, 'cat.png');
      controller.setRawJson(mockRepo.validSampleJson);
      await controller.validateMetadata();

      await tester.pumpWidget(wrapWithTheme(
        ImportStage4Review(
          controller: controller,
          onRegistered: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Catalogue Image (Primary)'), findsOneWidget);
      expect(find.text('Midnight Indigo Kurta'), findsOneWidget);
      expect(find.text('Appearance & Colours'), findsOneWidget);
      expect(find.text('Construction & Fit'), findsOneWidget);

      // Scroll down to the registration button
      await tester.scrollUntilVisible(find.text('Add to My Wardrobe'), 500);
      expect(find.text('Add to My Wardrobe'), findsOneWidget);

      // Tap Add to My Wardrobe to open confirmation dialog
      await tester.tap(find.text('Add to My Wardrobe'));
      await tester.pumpAndSettle();

      expect(find.text('Add to My Wardrobe?'), findsOneWidget);
      expect(find.text('User Imported (ChatGPT Project)'), findsOneWidget);
      expect(find.text('Confirm & Register'), findsOneWidget);
    });

    testWidgets('GarmentImportWizardScreen renders stepper and step navigation', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        GarmentImportWizardScreen(
          userId: 'test_user_1',
          repository: mockRepo,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('AI Catalogue & Metadata Import'), findsOneWidget);
      expect(find.text('1. Prepare'), findsOneWidget);
      expect(find.text('2. Studio'), findsOneWidget);
      expect(find.text('3. JSON'), findsOneWidget);
      expect(find.text('4. Review'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });
  });
}

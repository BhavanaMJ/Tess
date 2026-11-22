import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tess/core/theme/app_theme.dart';
import 'package:tess/features/wardrobe/data/models/capture_job_model.dart';
import 'package:tess/features/wardrobe/data/models/garment_candidate_model.dart';
import 'package:tess/features/wardrobe/domain/entities/capture_job.dart';
import 'package:tess/features/wardrobe/domain/entities/garment_candidate.dart';
import 'package:tess/features/wardrobe/domain/repositories/wardrobe_capture_repository.dart';
import 'package:tess/features/wardrobe/presentation/controllers/wardrobe_capture_controller.dart';
import 'package:tess/features/wardrobe/presentation/screens/capture_processing_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/capture_review_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/smart_capture_screen.dart';
import 'package:tess/features/wardrobe/presentation/widgets/garment_attribute_editor.dart';
import 'package:tess/features/wardrobe/presentation/widgets/garment_candidate_card.dart';

class MockWardrobeCaptureRepository implements WardrobeCaptureRepository {
  CaptureJob? currentJob;
  List<GarmentCandidate> mockCandidates = [];
  bool shouldFail = false;

  @override
  Future<CaptureJob> uploadAndProcessCapture(List<int> imageBytes, String filename) async {
    if (shouldFail) throw Exception('Upload network error');
    final job = CaptureJob(
      id: 'job-test-123',
      userId: 'test-user',
      originalImageRef: filename,
      status: 'AWAITING_APPROVAL',
      currentStage: 'AWAITING_APPROVAL',
      progressPercent: 100,
      totalDetected: mockCandidates.length,
      providerType: 'DEVELOPMENT_LOCAL',
      candidates: mockCandidates,
    );
    currentJob = job;
    return job;
  }

  @override
  Future<CaptureJob> getJobStatus(String jobId) async {
    if (currentJob != null) return currentJob!;
    return CaptureJob(
      id: jobId,
      userId: 'test-user',
      originalImageRef: 'test.jpg',
      status: 'AWAITING_APPROVAL',
      currentStage: 'AWAITING_APPROVAL',
      progressPercent: 100,
      totalDetected: mockCandidates.length,
      candidates: mockCandidates,
    );
  }

  @override
  Future<List<GarmentCandidate>> getJobCandidates(String jobId) async {
    return mockCandidates;
  }

  @override
  Future<GarmentCandidate> updateCandidate(String candidateId, Map<String, dynamic> delta) async {
    final idx = mockCandidates.indexWhere((c) => c.id == candidateId);
    if (idx >= 0) {
      final old = mockCandidates[idx];
      final updated = old.copyWith(
        suggestedName: delta['suggested_name'] as String? ?? old.suggestedName,
        mainCategory: delta['main_category'] as String? ?? old.mainCategory,
        primaryColor: delta['primary_color'] as String? ?? old.primaryColor,
        isIncluded: delta['is_included'] as bool? ?? old.isIncluded,
        brand: delta['brand'] as String? ?? old.brand,
      );
      mockCandidates[idx] = updated;
      return updated;
    }
    throw Exception('Candidate not found');
  }

  @override
  Future<CaptureJob> retryJob(String jobId) async {
    return uploadAndProcessCapture([1, 2, 3], 'retry.jpg');
  }

  @override
  Future<Map<String, dynamic>> confirmJob(String jobId, {List<String>? candidateIds}) async {
    final confirmed = mockCandidates
        .where((c) => candidateIds == null || candidateIds.contains(c.id))
        .map((c) => c.copyWith(isApproved: true, registeredGarmentId: 'CLO-019'))
        .toList();
    return {
      'success': true,
      'job_id': jobId,
      'registered_count': confirmed.length,
      'registered_garment_ids': confirmed.map((c) => c.registeredGarmentId).toList(),
      'registered_garments': confirmed.map((c) => {'id': 'CLO-019', 'name': c.suggestedName}).toList(),
    };
  }
}

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: child,
    );
  }

  const testCandidate1 = GarmentCandidate(
    id: 'cand-001',
    jobId: 'job-test-123',
    suggestedName: 'Classic Navy Blazer',
    mainCategory: 'Outerwear',
    subcategory: 'Blazer',
    primaryColor: 'Navy',
    secondaryColors: ['Gold'],
    pattern: 'Solid',
    fabricMaterial: 'Wool',
    fit: 'Tailored',
    brand: 'Zara',
    confidenceScores: {
      'category': 'HIGH',
      'primary_color': 'HIGH',
      'pattern': 'MEDIUM',
      'fabric_material': 'LOW',
      'brand': 'UNCERTAIN',
    },
    uncertaintyNotes: 'Brand label could not be verified from photograph angle.',
    isIncluded: true,
  );

  const testCandidate2 = GarmentCandidate(
    id: 'cand-002',
    jobId: 'job-test-123',
    suggestedName: 'White Oxford Shirt',
    mainCategory: 'Tops',
    subcategory: 'Button-Down Shirt',
    primaryColor: 'White',
    confidenceScores: {
      'category': 'HIGH',
      'primary_color': 'HIGH',
    },
    isIncluded: true,
  );

  group('GarmentCandidate & CaptureJob Model Tests', () {
    test('GarmentCandidateModel fromJson and toJson serialization roundtrip', () {
      final json = {
        'id': 'cand-999',
        'job_id': 'job-100',
        'suggested_name': 'Charcoal Chinos',
        'main_category': 'Bottoms',
        'subcategory': 'Chinos',
        'primary_color': 'Charcoal',
        'secondary_colors': ['Grey'],
        'pattern': 'Solid',
        'fabric_material': 'Cotton',
        'fit': 'Slim',
        'brand': 'Uniqlo',
        'confidence_scores': {'category': 'HIGH', 'color': 'HIGH'},
        'is_included': true,
        'is_approved': false,
        'uncertainty_notes': 'Texture is partially blurred.',
      };

      final model = GarmentCandidateModel.fromJson(json);
      expect(model.id, 'cand-999');
      expect(model.suggestedName, 'Charcoal Chinos');
      expect(model.mainCategory, 'Bottoms');
      expect(model.primaryColor, 'Charcoal');
      expect(model.confidenceScores['category'], 'HIGH');
      expect(model.isIncluded, isTrue);

      final outJson = model.toJson();
      expect(outJson['suggested_name'], 'Charcoal Chinos');
      expect(outJson['primary_color'], 'Charcoal');
    });

    test('CaptureJobModel fromJson and properties', () {
      final json = {
        'id': 'job-abc',
        'user_id': 'u-1',
        'original_image_ref': 'media/wardrobe/u-1/raw.jpg',
        'status': 'AWAITING_APPROVAL',
        'current_stage': 'AWAITING_APPROVAL',
        'progress_percent': 100,
        'total_detected': 1,
        'provider_type': 'DEVELOPMENT_LOCAL',
        'candidates': [
          {
            'id': 'cand-1',
            'job_id': 'job-abc',
            'suggested_name': 'Test Shirt',
            'main_category': 'Tops',
            'primary_color': 'Blue',
          }
        ],
      };

      final jobModel = CaptureJobModel.fromJson(json);
      final job = jobModel.toDomain();
      expect(job.id, 'job-abc');
      expect(job.isAwaitingApproval, isTrue);
      expect(job.isProcessing, isFalse);
      expect(job.isCompleted, isFalse);
      expect(job.candidates.length, 1);
      expect(job.candidates.first.suggestedName, 'Test Shirt');
    });
  });

  group('GarmentCandidateCard Widget Tests', () {
    testWidgets('renders candidate information, confidence tags and uncertainty note', (tester) async {
      bool editTapped = false;
      bool toggleTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: GarmentCandidateCard(
              candidate: testCandidate1,
              onEdit: () => editTapped = true,
              onToggleInclude: () => toggleTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check candidate title
      expect(find.text('Classic Navy Blazer'), findsOneWidget);

      // Check category and color badges
      expect(find.text('Outerwear'), findsOneWidget);
      expect(find.text('Navy • Solid • Wool'), findsOneWidget);

      // Check confidence pill
      expect(find.text('Category: High'), findsOneWidget);

      // Check uncertainty note
      expect(find.text('Brand label could not be verified from photograph angle.'), findsOneWidget);

      // Check Include switch is present
      expect(find.text('Included'), findsOneWidget);

      // Tap Edit button
      final editBtn = find.byIcon(Icons.edit_note_rounded);
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      expect(editTapped, isTrue);

      // Toggle switch
      final switchWidget = find.byType(Switch);
      expect(switchWidget, findsOneWidget);
      await tester.tap(switchWidget);
      expect(toggleTapped, isTrue);
    });

    testWidgets('renders excluded state with opacity and Excluded label', (tester) async {
      final excludedCandidate = testCandidate1.copyWith(isIncluded: false);

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: GarmentCandidateCard(
              candidate: excludedCandidate,
              onEdit: () {},
              onToggleInclude: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Excluded'), findsOneWidget);
    });
  });

  group('GarmentAttributeEditor Modal Tests', () {
    testWidgets('displays form fields with initial candidate values and saves modifications', (tester) async {
      GarmentCandidate? savedCandidate;

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: Builder(
              builder: (ctx) {
                return ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: ctx,
                      isScrollControlled: true,
                      builder: (_) => GarmentAttributeEditor(
                        candidate: testCandidate1,
                        onSave: (candidate) {
                          savedCandidate = candidate;
                        },
                      ),
                    );
                  },
                  child: const Text('Open Editor'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap button to open editor
      await tester.tap(find.text('Open Editor'));
      await tester.pumpAndSettle();

      // Verify title and initial values
      expect(find.text('Correct Detected Attributes'), findsOneWidget);

      // Edit Brand field
      final brandField = find.widgetWithText(TextFormField, 'Zara');
      expect(brandField, findsOneWidget);
      await tester.enterText(brandField, 'Massimo Dutti');
      await tester.pumpAndSettle();

      // Tap Save Attributes
      final saveBtn = find.text('Save Attributes');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify saved candidate has new brand
      expect(savedCandidate, isNotNull);
      expect(savedCandidate!.brand, 'Massimo Dutti');
    });
  });

  group('WardrobeCaptureController Workflow Tests', () {
    test('image validation rejects empty bytes and too small images', () {
      final repo = MockWardrobeCaptureRepository();
      final controller = WardrobeCaptureController(repository: repo);

      // Empty bytes
      final errEmpty = controller.validateImageBytes([]);
      expect(errEmpty, contains('empty'));

      // Very small bytes (< 500 bytes)
      final errSmall = controller.validateImageBytes(List.filled(200, 1));
      expect(errSmall, contains('too small'));

      // Valid size
      final errValid = controller.validateImageBytes(List.filled(5000, 1));
      expect(errValid, isNull);
    });

    test('full process, candidate update, and confirmation flow', () async {
      final repo = MockWardrobeCaptureRepository();
      repo.mockCandidates = [testCandidate1, testCandidate2];
      final controller = WardrobeCaptureController(repository: repo);

      // Set image directly
      controller.setImageBytesDirectly(List.filled(25000, 42), 'sample_outfit.jpg');
      expect(controller.selectedImageBytes, isNotNull);

      // Start capture job
      final job = await controller.startCaptureJob();
      expect(job, isNotNull);
      expect(controller.activeJob, isNotNull);
      expect(controller.candidates.length, 2);
      expect(controller.includedCount, 2);

      // Toggle inclusion for candidate 2
      await controller.toggleCandidateInclusion('cand-002');
      expect(controller.includedCount, 1);

      // Update candidate 1 brand
      await controller.updateCandidate(testCandidate1.copyWith(brand: 'Prada'));
      expect(controller.candidates.first.brand, 'Prada');

      // Confirm selected garments
      final res = await controller.confirmSelectedGarments();
      expect(res, isNotNull);
      expect(res!['registered_count'], 1);
    });
  });

  group('SmartCaptureScreen UI Tests', () {
    testWidgets('renders capture options, instructions, and camera/gallery buttons', (tester) async {
      final repo = MockWardrobeCaptureRepository();
      final controller = WardrobeCaptureController(repository: repo);

      await tester.pumpWidget(
        buildTestableWidget(
          SmartCaptureScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and banner
      expect(find.text('Smart Capture'), findsOneWidget);
      expect(find.text('AI Garment Recognition'), findsOneWidget);

      // Check capture action buttons
      expect(find.text('Take Photograph'), findsOneWidget);
      expect(find.text('Select from Gallery'), findsOneWidget);
    });
  });

  group('CaptureProcessingScreen UI Tests', () {
    testWidgets('renders progress percentage and stage text', (tester) async {
      final repo = MockWardrobeCaptureRepository();
      final controller = WardrobeCaptureController(repository: repo);

      await tester.pumpWidget(
        buildTestableWidget(
          CaptureProcessingScreen(
            controller: controller,
          ),
        ),
      );
      await tester.pump();

      // Check title
      expect(find.text('Processing Photograph'), findsOneWidget);
    });
  });

  group('CaptureReviewScreen UI Tests', () {
    testWidgets('renders candidate cards and registers approved garments', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = MockWardrobeCaptureRepository();
      repo.mockCandidates = [testCandidate1, testCandidate2];
      final controller = WardrobeCaptureController(repository: repo);

      // Set image and start capture job
      controller.setImageBytesDirectly(List.filled(2000, 1), 'test.jpg');
      await controller.startCaptureJob();

      await tester.pumpWidget(
        buildTestableWidget(
          CaptureReviewScreen(
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify review title and candidate names
      expect(find.text('Review Detected Clothes'), findsOneWidget);
      expect(find.text('Classic Navy Blazer'), findsOneWidget);
      expect(find.text('White Oxford Shirt'), findsOneWidget);

      // Register button exists
      final registerBtn = find.text('Register 2 Garments in Wardrobe');
      expect(registerBtn, findsOneWidget);

      // Tap Register button
      await tester.tap(registerBtn);
      await tester.pumpAndSettle();

      // Should show success snackbar
      expect(find.text('Successfully registered 2 garments to My Wardrobe!'), findsOneWidget);
    });
  });
}

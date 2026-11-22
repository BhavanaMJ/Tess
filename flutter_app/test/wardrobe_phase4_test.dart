import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tess/core/theme/app_theme.dart';
import 'package:tess/features/wardrobe/data/models/laundry_batch_model.dart';
import 'package:tess/features/wardrobe/data/models/laundry_history_model.dart';
import 'package:tess/features/wardrobe/data/models/laundry_stats_model.dart';
import 'package:tess/features/wardrobe/data/repositories/laundry_repository_impl.dart';
import 'package:tess/features/wardrobe/domain/entities/garment.dart';
import 'package:tess/features/wardrobe/domain/entities/laundry_history_entry.dart';
import 'package:tess/features/wardrobe/domain/entities/laundry_status.dart';
import 'package:tess/features/wardrobe/presentation/controllers/laundry_controller.dart';
import 'package:tess/features/wardrobe/presentation/screens/garment_laundry_history_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/laundry_batch_detail_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/laundry_dashboard_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/laundry_status_items_screen.dart';
import 'package:tess/features/wardrobe/presentation/widgets/laundry_history_timeline.dart';
import 'package:tess/features/wardrobe/presentation/widgets/laundry_status_card.dart';
import 'package:tess/features/wardrobe/presentation/widgets/laundry_status_selector_sheet.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: child,
    );
  }

  final testGarmentWorn1 = Garment(
    id: 'CLO-001',
    userId: 'u1',
    name: 'Yellow Printed Top',
    mainCategory: 'Tops',
    primaryColor: 'Yellow',
    sleeveLength: '3/4 sleeves',
    laundryStatus: LaundryStatus.worn,
    wearCount: 2,
    washCount: 1,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testGarmentWorn2 = Garment(
    id: 'CLO-008',
    userId: 'u1',
    name: 'Black Leggings',
    mainCategory: 'Bottoms',
    primaryColor: 'Black',
    laundryStatus: LaundryStatus.worn,
    wearCount: 4,
    washCount: 3,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testGarmentUnassigned = Garment(
    id: 'CLO-010',
    userId: 'u1',
    name: 'Teal & Orange Kurta',
    mainCategory: 'Ethnic wear',
    primaryColor: 'Teal',
    laundryStatus: null, // Unassigned
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('Laundry Domain & Models Serialization', () {
    test('LaundryStatsModel fromJson and toDomain', () {
      final json = {
        'total_garments': 18,
        'clean_count': 6,
        'worn_count': 4,
        'washing_count': 2,
        'drying_count': 1,
        'stored_count': 3,
        'unassigned_count': 2,
        'active_batches_count': 1,
      };

      final model = LaundryStatsModel.fromJson(json);
      expect(model.totalGarments, 18);
      expect(model.cleanCount, 6);
      expect(model.wornCount, 4);
      expect(model.washingCount, 2);
      expect(model.dryingCount, 1);
      expect(model.storedCount, 3);
      expect(model.unassignedCount, 2);

      final domain = model.toDomain();
      expect(domain.totalInProcess, 3); // 2 + 1
      expect(domain.cleanCount, 6);
    });

    test('LaundryBatchModel and LaundryHistoryEntryModel roundtrip', () {
      final batchJson = {
        'id': 'b1',
        'user_id': 'u1',
        'batch_number': 'BATCH-001',
        'name': 'Weekly Delicates',
        'status': 'WASHING',
        'notes': 'Gentle wash cycle',
        'items_count': 1,
        'items': [
          {
            'id': 'bi1',
            'batch_id': 'b1',
            'garment_id': 'CLO-001',
            'garment_name': 'Yellow Printed Top',
            'status': 'ACTIVE',
            'added_at': DateTime.now().toIso8601String(),
          }
        ],
      };

      final bModel = LaundryBatchModel.fromJson(batchJson);
      expect(bModel.batchNumber, 'BATCH-001');
      expect(bModel.status, 'WASHING');
      expect(bModel.items.length, 1);

      final historyJson = {
        'id': 'h1',
        'user_id': 'u1',
        'garment_id': 'CLO-001',
        'event_type': 'WEAR',
        'previous_status': 'CLEAN',
        'new_status': 'WORN',
        'notes': 'Dinner out',
      };
      final hModel = LaundryHistoryEntryModel.fromJson(historyJson);
      expect(hModel.eventType, 'WEAR');
      expect(hModel.previousStatus, 'CLEAN');
      expect(hModel.newStatus, 'WORN');
    });
  });

  group('Laundry Status & History Widgets Tests', () {
    testWidgets('LaundryStatusCard renders title, count, and triggers onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: LaundryStatusCard(
              title: 'Worn / Hamper',
              subtitle: 'Ready for washing',
              count: 4,
              icon: Icons.checkroom_rounded,
              accentColor: Colors.amber,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Worn / Hamper'), findsOneWidget);
      expect(find.text('Ready for washing'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      await tester.tap(find.text('Worn / Hamper'));
      expect(tapped, isTrue);
    });

    testWidgets('LaundryStatusSelectorSheet displays all 5 statuses and unassigned option', (tester) async {
      LaundryStatus? selected;

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: ctx,
                    builder: (_) => LaundryStatusSelectorSheet(
                      garmentName: 'Yellow Printed Top',
                      currentStatus: LaundryStatus.worn,
                      onSelected: (val) => selected = val,
                    ),
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Check header and garment name
      expect(find.text('Update Laundry Status'), findsOneWidget);
      expect(find.text('Yellow Printed Top'), findsOneWidget);

      // Check all 5 statuses
      expect(find.text('Clean & Ready'), findsOneWidget);
      expect(find.text('Worn / In Hamper'), findsOneWidget);
      expect(find.text('In Wash Cycle'), findsOneWidget);
      expect(find.text('Drying'), findsOneWidget);
      expect(find.text('Stored / Off-Season'), findsOneWidget);
      expect(find.text('Status Not Assigned (Unset)'), findsOneWidget);

      // Tap Clean & Ready
      await tester.tap(find.text('Clean & Ready'));
      await tester.pumpAndSettle();

      expect(selected, LaundryStatus.clean);
    });

    testWidgets('LaundryHistoryTimeline renders chronological entries', (tester) async {
      final entries = [
        LaundryHistoryEntry(
          id: 'h2',
          userId: 'u1',
          garmentId: 'CLO-001',
          eventType: 'WASH_CYCLE_COMPLETED',
          previousStatus: 'DRYING',
          newStatus: 'CLEAN',
          notes: 'Regular wash completed',
          createdAt: DateTime(2026, 11, 22, 14, 30),
        ),
        LaundryHistoryEntry(
          id: 'h1',
          userId: 'u1',
          garmentId: 'CLO-001',
          eventType: 'WEAR',
          previousStatus: 'CLEAN',
          newStatus: 'WORN',
          notes: 'Worn to office',
          createdAt: DateTime(2026, 11, 20, 9, 0),
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: SingleChildScrollView(
              child: LaundryHistoryTimeline(history: entries),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WASH CYCLE COMPLETED'), findsOneWidget);
      expect(find.text('DRYING  ➔  CLEAN'), findsOneWidget);
      expect(find.text('Regular wash completed'), findsOneWidget);

      expect(find.text('WEAR'), findsOneWidget);
      expect(find.text('CLEAN  ➔  WORN'), findsOneWidget);
    });
  });

  group('LaundryController Workflow & Business Logic Tests', () {
    test('transitions garment status and increments wear/wash counts appropriately', () async {
      final repo = LaundryRepositoryImpl();
      repo.seedGarment(testGarmentWorn1);

      final controller = LaundryController(repository: repo);

      // Clean garment starts at washCount 1
      // Moving to Washing
      await controller.updateGarmentStatus('CLO-001', LaundryStatus.washing);
      var g = (await repo.getLaundryItems()).firstWhere((i) => i.id == 'CLO-001');
      expect(g.laundryStatus, LaundryStatus.washing);

      // Moving to Drying
      await controller.updateGarmentStatus('CLO-001', LaundryStatus.drying);
      g = (await repo.getLaundryItems()).firstWhere((i) => i.id == 'CLO-001');
      expect(g.laundryStatus, LaundryStatus.drying);

      // Moving to Clean increments wash count
      await controller.updateGarmentStatus('CLO-001', LaundryStatus.clean);
      g = (await repo.getLaundryItems()).firstWhere((i) => i.id == 'CLO-001');
      expect(g.laundryStatus, LaundryStatus.clean);
      expect(g.washCount, 2); // 1 + 1

      // Moving Clean to Worn increments wear count
      final prevWears = g.wearCount;
      await controller.updateGarmentStatus('CLO-001', LaundryStatus.worn);
      g = (await repo.getLaundryItems()).firstWhere((i) => i.id == 'CLO-001');
      expect(g.laundryStatus, LaundryStatus.worn);
      expect(g.wearCount, prevWears + 1);
    });

    test('creates batch, advances lifecycle, and respects individual overrides', () async {
      final repo = LaundryRepositoryImpl();
      repo.seedGarment(testGarmentWorn1);
      repo.seedGarment(testGarmentWorn2);

      final controller = LaundryController(repository: repo);

      // Create batch with 2 worn garments
      final batch = await controller.createBatch(
        ['CLO-001', 'CLO-008'],
        name: 'Test Mixed Batch',
      );
      expect(batch, isNotNull);
      expect(batch!.status, 'WASHING');
      expect(batch.items.length, 2);

      // Individual override: CLO-008 is moved individually to DRYING ahead of time
      await controller.updateGarmentStatus('CLO-008', LaundryStatus.drying);

      // Advance batch to DRYING
      final resDrying = await controller.advanceBatch(batch.id, 'DRYING');
      expect(resDrying, isNotNull);
      expect(resDrying!['updated_garment_ids'], contains('CLO-001'));
      expect(resDrying['skipped_garment_ids'], contains('CLO-008')); // override preserved!

      // Advance batch to COMPLETED
      final resCompleted = await controller.advanceBatch(batch.id, 'COMPLETED');
      expect(resCompleted, isNotNull);
      expect(resCompleted!['new_batch_status'], 'COMPLETED');

      // Both garments are now clean
      final all = await repo.getLaundryItems();
      final g1 = all.firstWhere((i) => i.id == 'CLO-001');
      final g8 = all.firstWhere((i) => i.id == 'CLO-008');
      expect(g1.laundryStatus, LaundryStatus.clean);
      expect(g8.laundryStatus, LaundryStatus.clean);
    });
  });

  group('Laundry Screens UI Tests', () {
    testWidgets('LaundryDashboardScreen renders metrics grid and active batches', (tester) async {
      final repo = LaundryRepositoryImpl();
      repo.seedGarment(testGarmentWorn1);
      repo.seedGarment(testGarmentUnassigned);

      final controller = LaundryController(repository: repo);

      await tester.pumpWidget(
        buildTestableWidget(
          LaundryDashboardScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and phase badge
      expect(find.text('Laundry Manager'), findsOneWidget);
      expect(find.text('PHASE 4'), findsOneWidget);

      // Check metrics section
      expect(find.text('GARMENTS BY LAUNDRY STATUS'), findsOneWidget);
      expect(find.text('Worn / Hamper'), findsOneWidget);
      expect(find.text('In Washing'), findsOneWidget);
      expect(find.text('Drying'), findsOneWidget);
      expect(find.text('Clean & Ready'), findsOneWidget);
      expect(find.text('Stored'), findsOneWidget);
      expect(find.text('Status Not Assigned'), findsOneWidget);

      // Check batch action
      expect(find.text('Start New Laundry Batch'), findsOneWidget);
      expect(find.text('ACTIVE LAUNDRY BATCHES'), findsOneWidget);
    });

    testWidgets('LaundryStatusItemsScreen displays filtered garments and search works', (tester) async {
      final repo = LaundryRepositoryImpl();
      repo.seedGarment(testGarmentWorn1);
      repo.seedGarment(testGarmentWorn2);

      final controller = LaundryController(repository: repo);

      await tester.pumpWidget(
        buildTestableWidget(
          LaundryStatusItemsScreen(
            controller: controller,
            statusFilter: 'WORN',
            statusTitle: 'Worn / In Hamper',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Worn / In Hamper'), findsOneWidget);
      expect(find.text('Yellow Printed Top'), findsOneWidget);
      expect(find.text('Black Leggings'), findsOneWidget);

      // Type in search bar to filter
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Leggings');
      await tester.pumpAndSettle();

      expect(find.text('Black Leggings'), findsOneWidget);
      expect(find.text('Yellow Printed Top'), findsNothing);
    });

    testWidgets('LaundryBatchDetailScreen renders lifecycle stepper and advance button', (tester) async {
      final repo = LaundryRepositoryImpl();
      repo.seedGarment(testGarmentWorn1);
      final controller = LaundryController(repository: repo);

      // Create a batch first
      final batch = await controller.createBatch(['CLO-001'], name: 'Quick Wash');

      await tester.pumpWidget(
        buildTestableWidget(
          LaundryBatchDetailScreen(
            controller: controller,
            batchId: batch!.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quick Wash'), findsOneWidget);
      expect(find.text('WASHING'), findsWidgets);
      expect(find.text('Yellow Printed Top'), findsOneWidget);

      // Next action button for WASHING is "Move Batch to Drying"
      expect(find.text('Move Batch to Drying'), findsOneWidget);
    });

    testWidgets('GarmentLaundryHistoryScreen displays counters and timeline', (tester) async {
      final repo = LaundryRepositoryImpl();
      repo.seedGarment(testGarmentWorn1);
      final controller = LaundryController(repository: repo);

      await tester.pumpWidget(
        buildTestableWidget(
          GarmentLaundryHistoryScreen(
            garment: testGarmentWorn1,
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Laundry History'), findsOneWidget);
      expect(find.text('Yellow Printed Top'), findsOneWidget);
      expect(find.text('TOTAL WEARS'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // 2 wears
      expect(find.text('TOTAL WASHES'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // 1 wash
      expect(find.text('LIFECYCLE TIMELINE'), findsOneWidget);
    });
  });
}

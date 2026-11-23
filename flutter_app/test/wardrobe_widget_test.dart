import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tess/core/theme/app_theme.dart';
import 'package:tess/features/wardrobe/data/repositories/wardrobe_repository_impl.dart';
import 'package:tess/features/wardrobe/domain/entities/garment.dart';
import 'package:tess/features/wardrobe/domain/entities/laundry_status.dart';
import 'package:tess/features/wardrobe/presentation/controllers/wardrobe_controller.dart';
import 'package:tess/features/wardrobe/presentation/screens/wardrobe_inventory_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/wardrobe_overview_screen.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: child,
    );
  }

  group('Phase 1: Wardrobe Overview Screen UI Tests', () {
    testWidgets('renders Wardrobe Overview with header, actions, and empty state', (tester) async {
      final repo = WardrobeRepositoryImpl();

      await tester.pumpWidget(
        buildTestableWidget(
          WardrobeOverviewScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Check App bar title and Phase 7 tag
      expect(find.text('Wardrobe Intelligence'), findsOneWidget);
      expect(find.text('PHASE 7'), findsOneWidget);

      // Check Contextual intro
      expect(find.text('Personal Clothes Organizer'), findsOneWidget);

      // Check Smart Capture action
      expect(find.text('Smart Capture / Add Clothes'), findsOneWidget);

      // Check Core module shortcuts
      expect(find.text('My Wardrobe'), findsOneWidget);
      expect(find.text('Outfit Studio'), findsOneWidget);
      expect(find.text('Laundry Manager'), findsOneWidget);
      expect(find.text('Outfit Calendar'), findsOneWidget);
      expect(find.text('Wardrobe Insights'), findsOneWidget);

      // Check Empty State when no garments imported yet
      expect(find.text('Your Wardrobe is Ready to Populate'), findsOneWidget);
      expect(find.text('Import Initial 18 Garments'), findsOneWidget);
    });

    testWidgets('clicking Import Initial 18 Garments populates inventory and shows telemetry', (tester) async {
      final repo = WardrobeRepositoryImpl();

      await tester.pumpWidget(
        buildTestableWidget(
          WardrobeOverviewScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to import button and tap
      final importButton = find.text('Import Initial 18 Garments');
      expect(importButton, findsOneWidget);
      await tester.ensureVisible(importButton);
      await tester.pumpAndSettle();
      await tester.tap(importButton);
      await tester.pumpAndSettle();

      // Verify SnackBar confirmation
      expect(find.text('Imported 18 initial garments successfully!'), findsOneWidget);

      // Telemetry summary card should now be visible
      expect(find.text('WARDROBE TELEMETRY'), findsOneWidget);
      expect(find.text('TOTAL'), findsOneWidget);
      expect(find.text('UNSET'), findsOneWidget);
      expect(find.text('18'), findsNWidgets(2)); // Total 18 and Unset 18
      expect(find.text('18 ITEMS'), findsOneWidget);

      // Empty state should be gone
      expect(find.text('Your Wardrobe is Ready to Populate'), findsNothing);
    });

    testWidgets('clicking coming soon modules displays informative snackbar', (tester) async {
      final repo = WardrobeRepositoryImpl();

      await tester.pumpWidget(
        buildTestableWidget(
          WardrobeOverviewScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Wardrobe Wishlist (Phase 8)
      final wishlist = find.text('Wardrobe Wishlist');
      await tester.ensureVisible(wishlist);
      await tester.pumpAndSettle();
      await tester.tap(wishlist);
      await tester.pumpAndSettle();

      expect(find.text('Wardrobe Wishlist will be activated in Phase 8.'), findsOneWidget);
    });
  });

  group('Phase 1: Wardrobe Inventory Screen UI Tests', () {
    testWidgets('renders My Wardrobe inventory with search, category chips, and garment cards', (tester) async {
      final repo = WardrobeRepositoryImpl();
      final now = DateTime.now();

      await repo.saveGarment(
        Garment(
          id: 'CLO-001',
          userId: 'test_user',
          name: 'Yellow Printed Top',
          mainCategory: 'Tops',
          subcategory: 'Tunics',
          primaryColor: 'Yellow',
          sleeveLength: '3/4 sleeves',
          laundryStatus: LaundryStatus.clean,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repo.saveGarment(
        Garment(
          id: 'CLO-004',
          userId: 'test_user',
          name: 'Black Elastic-Waist Jeans',
          mainCategory: 'Bottoms',
          subcategory: 'Jeans',
          primaryColor: 'Black',
          laundryStatus: LaundryStatus.worn,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final controller = WardrobeController(repository: repo);
      await controller.loadInitialData();

      await tester.pumpWidget(
        buildTestableWidget(
          WardrobeInventoryScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Wardrobe'), findsOneWidget);
      expect(find.text('Yellow Printed Top'), findsOneWidget);
      expect(find.text('Black Elastic-Waist Jeans'), findsOneWidget);
      expect(find.text('CLO-001'), findsOneWidget);
      expect(find.text('CLO-004'), findsOneWidget);
      expect(find.text('CLEAN'), findsOneWidget);
      expect(find.text('WORN'), findsOneWidget);

      // Category chip filter: Tap 'Tops'
      final topsChip = find.text('Tops');
      expect(topsChip, findsOneWidget);
      await tester.tap(topsChip);
      await tester.pumpAndSettle();

      // Only Tops should remain visible
      expect(find.text('Yellow Printed Top'), findsOneWidget);
      expect(find.text('Black Elastic-Waist Jeans'), findsNothing);

      // Search filter
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'xyz_no_match');
      await tester.pumpAndSettle();

      expect(find.text('No garments match your filters'), findsOneWidget);
    });

    testWidgets('toggles favorite on garment card', (tester) async {
      final repo = WardrobeRepositoryImpl();
      final now = DateTime.now();

      await repo.saveGarment(
        Garment(
          id: 'CLO-001',
          userId: 'test_user',
          name: 'Yellow Printed Top',
          mainCategory: 'Tops',
          primaryColor: 'Yellow',
          isFavorite: false,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final controller = WardrobeController(repository: repo);
      await controller.loadInitialData();

      await tester.pumpWidget(
        buildTestableWidget(
          WardrobeInventoryScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Initial heart should be border
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);

      // Tap favorite icon
      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pumpAndSettle();

      // Should now be filled heart
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });
  });
}

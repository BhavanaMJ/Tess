import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tess/core/theme/app_colors.dart';
import 'package:tess/core/theme/app_theme.dart';
import 'package:tess/core/theme/theme_controller.dart';
import 'package:tess/features/wardrobe/data/repositories/wardrobe_repository_impl.dart';
import 'package:tess/features/wardrobe/domain/entities/garment.dart';
import 'package:tess/features/wardrobe/domain/entities/laundry_status.dart';
import 'package:tess/features/wardrobe/presentation/controllers/wardrobe_controller.dart';
import 'package:tess/features/wardrobe/presentation/screens/wardrobe_inventory_screen.dart';
import 'package:tess/features/wardrobe/presentation/screens/wardrobe_overview_screen.dart';
import 'package:tess/features/wardrobe/presentation/theme/wardrobe_theme.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.instance.themeMode,
          home: child,
        );
      },
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

      // Check App bar title and Phase 8 tag
      expect(find.text('Wardrobe Intelligence'), findsOneWidget);
      expect(find.text('PHASE 8'), findsOneWidget);

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

    testWidgets('clicking Wardrobe Wishlist navigates to WishlistScreen', (tester) async {
      final repo = WardrobeRepositoryImpl();

      await tester.pumpWidget(
        buildTestableWidget(
          WardrobeOverviewScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Wardrobe Wishlist (Phase 8 active module)
      final wishlist = find.text('Wardrobe Wishlist');
      await tester.ensureVisible(wishlist);
      await tester.pumpAndSettle();
      await tester.tap(wishlist);
      await tester.pumpAndSettle();

      expect(find.text('PHASE 8'), findsOneWidget);
      expect(find.text('Add to Wishlist'), findsOneWidget);
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

  group('Wardrobe Brand Kit & Dynamic Theme Adaptation Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ThemeController.instance.setThemeMode(ThemeMode.light);
    });

    tearDown(() async {
      SharedPreferences.setMockInitialValues({});
      await ThemeController.instance.setThemeMode(ThemeMode.light);
    });

    test('WardrobeTheme defaults to Light Theme brand kit when user has not chosen dark', () {
      expect(ThemeController.instance.themeMode, equals(ThemeMode.light));
      expect(WardrobeTheme.isDark, isFalse);

      // Verify TESS Brand Kit light theme tokens
      expect(WardrobeTheme.voidBg, equals(AppColors.lightBg));
      expect(WardrobeTheme.spatialSurface, equals(AppColors.lightSurface));
      expect(WardrobeTheme.textPrimary, equals(AppColors.lightTextPrimary));
      expect(WardrobeTheme.textSecondary, equals(AppColors.lightTextSecondary));
      expect(WardrobeTheme.textMuted, equals(AppColors.lightTextMuted));
      expect(WardrobeTheme.border, equals(AppColors.lightBorder));
      expect(WardrobeTheme.borderSubtle, equals(AppColors.lightBorderSubtle));

      // Primary brand kit accents (Teal & Vibrant Mint)
      expect(WardrobeTheme.electricViolet, equals(AppColors.tessTeal));
      expect(WardrobeTheme.electricCyan, equals(AppColors.vibrantMint));
      expect(WardrobeTheme.softViolet, equals(AppColors.deepTeal));
    });

    test('WardrobeTheme switches to Dark Theme only when user chooses dark in settings', () async {
      await ThemeController.instance.setThemeMode(ThemeMode.dark);
      expect(ThemeController.instance.themeMode, equals(ThemeMode.dark));
      expect(WardrobeTheme.isDark, isTrue);

      // Verify Dark Theme spatial tokens
      expect(WardrobeTheme.voidBg, equals(const Color(0xFF0B100F)));
      expect(WardrobeTheme.spatialSurface, equals(const Color(0xFF131A19)));
      expect(WardrobeTheme.textPrimary, equals(AppColors.darkTextPrimary));
      expect(WardrobeTheme.textSecondary, equals(AppColors.darkTextSecondary));
      expect(WardrobeTheme.textMuted, equals(AppColors.darkTextMuted));
      expect(WardrobeTheme.border, equals(const Color(0xFF22302D)));

      // Dark accents
      expect(WardrobeTheme.electricViolet, equals(const Color(0xFF8B5CF6)));
      expect(WardrobeTheme.electricCyan, equals(const Color(0xFF22D3EE)));
    });

    testWidgets('WardrobeOverviewScreen renders seamlessly in light theme', (tester) async {
      await ThemeController.instance.setThemeMode(ThemeMode.light);
      final repo = WardrobeRepositoryImpl();

      await tester.pumpWidget(
        buildTestableWidget(
          WardrobeOverviewScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Wardrobe Intelligence'), findsOneWidget);
      expect(find.text('Personal Clothes Organizer'), findsOneWidget);
    });

    testWidgets('WardrobeOverviewScreen renders seamlessly in dark theme', (tester) async {
      await ThemeController.instance.setThemeMode(ThemeMode.dark);
      final repo = WardrobeRepositoryImpl();

      await tester.pumpWidget(
        buildTestableWidget(
          WardrobeOverviewScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Wardrobe Intelligence'), findsOneWidget);
      expect(find.text('Personal Clothes Organizer'), findsOneWidget);
    });
  });
}

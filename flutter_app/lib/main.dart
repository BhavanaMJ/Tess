import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'core/auth/auth_service.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/theme_controller.dart';

Future<void> main() async {
  // Ensure Flutter engine bindings are initialized before calling platform channels
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Theme preference
  await ThemeController.instance.init();

  // Configure system navigation bar & status bar overlays to match TESS spatial theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgSecondary,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Supabase Auth with environment configuration
  try {
    await AuthService.initialize(AppConfig.development());
  } catch (e) {
    debugPrint('[Main] Supabase initialization warning: $e');
  }

  runApp(const TessApp());
}

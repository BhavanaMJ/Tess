import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Centralized Configuration for TESS Flutter Application.
/// Supports runtime overrides via --dart-define flags:
/// e.g. `flutter run --dart-define=BACKEND_URL=http://192.168.1.175:8000`
class AppConfig {
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String apiBaseUrl;
  final Duration timeout;
  final bool enableDebugTelemetry;

  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.apiBaseUrl,
    this.timeout = const Duration(seconds: 15),
    this.enableDebugTelemetry = true,
  });

  /// Resolves the default backend URL based on host platform:
  /// - Android Emulator: 10.0.2.2 routes to host machine loopback.
  /// - Linux/Desktop/Web: localhost:8000.
  /// - Physical Device: LAN IP (e.g. 192.168.1.175:8000).
  static String resolveDefaultBackendUrl() {
    // 1. Check if an environment variable was passed via --dart-define
    const envUrl = String.fromEnvironment('BACKEND_URL');
    if (envUrl.isNotEmpty) return envUrl;

    // 2. Physical LAN IP takes precedence for local development across phones
    const lanUrl = 'http://192.168.1.175:8000';

    // 3. Platform detection for emulators
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          // Defaulting to LAN URL for universal real-device & emulator accessibility
          return lanUrl;
        }
      } catch (_) {}
    }

    return 'http://127.0.0.1:8000';
  }

  /// Factory for Development Configuration
  factory AppConfig.development() {
    return AppConfig(
      supabaseUrl: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://eksurcfrrbxuzqqzjuit.supabase.co',
      ),
      supabaseAnonKey: const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: 'sb_publishable_FLJXDR4I8Qpox5W1ixkiwA_Bx35A77m',
      ),
      apiBaseUrl: resolveDefaultBackendUrl(),
      timeout: const Duration(seconds: 15),
      enableDebugTelemetry: true,
    );
  }

  /// Factory for Production Configuration
  factory AppConfig.production() {
    return const AppConfig(
      supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      apiBaseUrl: String.fromEnvironment('BACKEND_URL', defaultValue: 'https://api.tess.ai'),
      timeout: Duration(seconds: 10),
      enableDebugTelemetry: false,
    );
  }
}

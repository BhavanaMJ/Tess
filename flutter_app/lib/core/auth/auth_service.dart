import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import 'auth_state.dart';

/// Core Authentication Service wrapping Supabase GoTrue Auth.
/// Manages sessions, token refresh, and auth state broadcasts.
class AuthService {
  static AuthService? _instance;
  final SupabaseClient? _client;

  AuthService._([this._client]);

  /// Access singleton instance or create with explicit client
  factory AuthService({SupabaseClient? client}) {
    if (client != null) {
      return AuthService._(client);
    }
    if (_instance == null) {
      try {
        _instance = AuthService._(Supabase.instance.client);
      } catch (_) {
        return AuthService._(null);
      }
    }
    return _instance!;
  }

  /// Initialize Supabase Flutter SDK
  static Future<void> initialize(AppConfig config) async {
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
      debug: kDebugMode && config.enableDebugTelemetry,
    );
  }

  /// Current Supabase client
  SupabaseClient? get client => _client;

  /// Current session (persisted automatically by Supabase GoTrue)
  Session? get currentSession => _client?.auth.currentSession;

  /// Current authenticated user
  User? get currentUser => _client?.auth.currentUser;

  /// Check whether user is authenticated
  bool get isAuthenticated => _client != null && currentSession != null && currentUser != null;

  /// Retrieves the current valid JWT Access Token for API calls.
  /// If expired, Supabase automatically attempts to refresh via refresh_token.
  Future<String?> getAccessToken() async {
    final session = currentSession;
    if (session == null || _client == null) return null;

    // Check if token needs refresh
    if (session.isExpired) {
      try {
        final res = await _client!.auth.refreshSession();
        return res.session?.accessToken;
      } catch (e) {
        debugPrint('[AuthService] Token refresh failed: $e');
        return null;
      }
    }
    return session.accessToken;
  }

  /// Stream of authentication state updates
  Stream<TessAuthState> get authStateChanges {
    if (_client == null) {
      return const Stream.empty();
    }
    return _client!.auth.onAuthStateChange.map((data) {
      final session = data.session;
      final user = session?.user;

      if (session != null && user != null) {
        return TessAuthState.authenticated(user: user, session: session);
      } else {
        return const TessAuthState.unauthenticated();
      }
    });
  }

  /// Sign In with Email and Password
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (_client == null) {
      throw Exception('Supabase client is not initialized.');
    }
    try {
      final response = await _client!.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      debugPrint('[AuthService] AuthException during signIn: ${e.message}');
      throw _mapAuthException(e);
    } catch (e) {
      debugPrint('[AuthService] Unexpected error during signIn: $e');
      throw Exception('Network connection error. Please verify server reachability.');
    }
  }

  /// Sign Up with Email, Password, and Metadata
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? callsign,
    String? fullName,
  }) async {
    if (_client == null) {
      throw Exception('Supabase client is not initialized.');
    }
    try {
      final response = await _client!.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          if (callsign != null && callsign.isNotEmpty) 'callsign': callsign.trim(),
          if (fullName != null && fullName.isNotEmpty) 'full_name': fullName.trim(),
        },
      );
      return response;
    } on AuthException catch (e) {
      debugPrint('[AuthService] AuthException during signUp: ${e.message}');
      throw _mapAuthException(e);
    } catch (e) {
      debugPrint('[AuthService] Unexpected error during signUp: $e');
      throw Exception('Network connection error during registration.');
    }
  }

  /// Sign Out / Terminate Session
  Future<void> signOut() async {
    if (_client == null) return;
    try {
      await _client!.auth.signOut();
    } catch (e) {
      debugPrint('[AuthService] Error during signOut: $e');
      throw Exception('Failed to sign out cleanly: $e');
    }
  }

  /// Map Supabase GoTrue AuthException into human-friendly messages
  Exception _mapAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return Exception('Invalid email or password. Please verify credentials.');
    }
    if (msg.contains('email not confirmed')) {
      return Exception('Email address not confirmed. Please check inbox.');
    }
    if (msg.contains('user already registered')) {
      return Exception('An account with this email already exists.');
    }
    if (msg.contains('password should be at least')) {
      return Exception('Password is too weak. Minimum 6 characters required.');
    }
    return Exception(e.message);
  }
}

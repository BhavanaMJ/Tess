import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tess/core/auth/auth_service.dart';
import 'package:tess/core/auth/auth_state.dart';

/// Shared Test Fake for AuthService
class FakeAuthService implements AuthService {
  final _stateController = StreamController<TessAuthState>.broadcast();
  bool _authenticated = false;
  String? mockToken = 'mock_jwt_access_token_xyz123';
  String? lastSignedInEmail;
  String? lastSignedUpEmail;
  bool throwOnSignIn = false;

  FakeAuthService({bool initialAuthenticated = false}) {
    _authenticated = initialAuthenticated;
  }

  @override
  bool get isAuthenticated => _authenticated;

  @override
  Future<String?> getAccessToken() async {
    return _authenticated ? mockToken : null;
  }

  @override
  Stream<TessAuthState> get authStateChanges => _stateController.stream;

  @override
  Session? get currentSession => null;

  @override
  User? get currentUser => null;

  @override
  SupabaseClient? get client => null;

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (throwOnSignIn) {
      throw Exception('Invalid email or password. Please verify credentials.');
    }
    lastSignedInEmail = email;
    _authenticated = true;
    _stateController.add(const TessAuthState.unauthenticated());
    return AuthResponse();
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? callsign,
    String? fullName,
  }) async {
    lastSignedUpEmail = email;
    _authenticated = true;
    return AuthResponse();
  }

  @override
  Future<void> signOut() async {
    _authenticated = false;
    _stateController.add(const TessAuthState.unauthenticated());
  }
}


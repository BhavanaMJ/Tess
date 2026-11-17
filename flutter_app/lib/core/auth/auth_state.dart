import 'package:supabase_flutter/supabase_flutter.dart';

enum TessAuthStatus { initial, authenticated, unauthenticated, error }

/// Represents the current state of authentication in TESS.
class TessAuthState {
  final TessAuthStatus status;
  final User? user;
  final Session? session;
  final String? errorMessage;

  const TessAuthState._({
    required this.status,
    this.user,
    this.session,
    this.errorMessage,
  });

  const TessAuthState.initial()
      : this._(status: TessAuthStatus.initial);

  const TessAuthState.authenticated({
    required User user,
    required Session session,
  }) : this._(
          status: TessAuthStatus.authenticated,
          user: user,
          session: session,
        );

  const TessAuthState.unauthenticated()
      : this._(status: TessAuthStatus.unauthenticated);

  const TessAuthState.error(String message)
      : this._(
          status: TessAuthStatus.error,
          errorMessage: message,
        );

  bool get isAuthenticated => status == TessAuthStatus.authenticated && session != null;
  bool get isLoading => status == TessAuthStatus.initial;
  String? get userEmail => user?.email;
  String? get userId => user?.id;
}


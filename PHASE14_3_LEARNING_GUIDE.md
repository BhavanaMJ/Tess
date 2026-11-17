# TESS Phase 14.3 — Supabase Authentication & API Foundation Master Guide

Welcome to the **TESS Phase 14.3 Master Learning Guide**. This milestone establishes the secure authentication pipeline and backend API foundation for the Flutter client (`flutter_app/`), integrating with the existing Supabase project and FastAPI backend.

---

## Table of Contents
1. [What Supabase Is](#1-what-supabase-is)
2. [What Authentication Means in Modern Systems](#2-what-authentication-means)
3. [Access Tokens vs. Refresh Tokens](#3-access-tokens-vs-refresh-tokens)
4. [JWT Structure and FastAPI Backend Verification](#4-jwt-structure-and-verification)
5. [Authentication State Management in Flutter](#5-authentication-state-in-flutter)
6. [Flutter Asynchronous Authentication Flows](#6-flutter-async-auth-flows)
7. [HTTP Requests & Networking](#7-http-requests--networking)
8. [JSON Serialization & Deserialization](#8-json-serialization)
9. [API Service Architecture](#9-api-service-architecture)
10. [Environment Configuration & Platform Networking](#10-environment-configuration--platform-networking)
11. [Error Handling & User Feedback](#11-error-handling)
12. [Secure Credential Management](#12-secure-credential-management)

---

## 1. What Supabase Is

**Supabase** is an open-source Backend-as-a-Service (BaaS) built on PostgreSQL. Rather than managing your own user tables, hashing passwords with bcrypt, or writing OAuth2 providers from scratch, Supabase provides:
1. **GoTrue Auth Engine**: Handles user registration, email/password verification, magic links, OAuth providers, and automated JSON Web Token (JWT) issuance.
2. **PostgreSQL Database**: Row-Level Security (RLS) protects database records at the engine level based on the caller's JWT user ID (`auth.uid()`).
3. **Session Storage & Auto-Refresh**: Securely persists sessions on device storage (`SharedPreferences` on Android/Linux, `AsyncStorage` in React Native).

### Architecture in TESS:
```
  ┌───────────────────────────────────────────────────────────┐
  │                 Flutter Mobile Client                     │
  └─────────────┬───────────────────────────────┬─────────────┘
                │ 1. Sign In (Email + Password) │ 3. API Call (Bearer JWT)
                ▼                               ▼
  ┌───────────────────────────┐   ┌───────────────────────────┐
  │   Supabase GoTrue Auth    │   │      FastAPI Backend      │
  │  (Issues JWT Access Token)│   │  (Validates JWT via JWKS) │
  └───────────────────────────┘   └───────────────────────────┘
```

---

## 2. What Authentication Means

- **Authentication (AuthN)**: Answering the question: *"Who are you?"* (e.g. verifying email and password).
- **Authorization (AuthZ)**: Answering the question: *"What permissions do you have?"* (e.g. ensuring user A cannot view user B's predictions).

When a user signs in via [auth_service.dart](file:///home/bhavanamj/Desktop/Tess/flutter_app/lib/core/auth/auth_service.dart), Supabase validates credentials and issues a cryptographic proof of identity: a **JSON Web Token (JWT)**.

---

## 3. Access Tokens vs. Refresh Tokens

Mobile apps do not send your password with every API request. Instead, they use a **dual-token model**:

| Feature | Access Token (JWT) | Refresh Token |
| :--- | :--- | :--- |
| **Purpose** | Authorizes API requests against FastAPI | Obtains a new Access Token when the current one expires |
| **Lifespan** | Short-lived (typically 1 hour) | Long-lived (days to weeks) |
| **Where Sent** | Sent in `Authorization: Bearer <token>` | Sent exclusively to Supabase Auth `/auth/v1/token` |
| **Exposure Risk** | Minimal; if intercepted, expires rapidly | High; must be stored in secure local storage |

### Auto-Refresh in TESS Flutter:
In `AuthService.getAccessToken()`:
```dart
Future<String?> getAccessToken() async {
  final session = currentSession;
  if (session == null) return null;

  // Supabase automatically checks JWT expiration
  if (session.isExpired) {
    final res = await _client!.auth.refreshSession();
    return res.session?.accessToken;
  }
  return session.accessToken;
}
```

---

## 4. JWT Structure and Verification

A JWT is a string consisting of three Base64URL-encoded segments separated by dots (`.`):
```
header.payload.signature
```
1. **Header**: Algorithmic metadata, e.g. `{"alg": "HS256", "typ": "JWT"}`.
2. **Payload (Claims)**: Information about the user:
   ```json
   {
     "sub": "bhavanamj-user-uuid",
     "email": "commander@tess.ai",
     "role": "authenticated",
     "exp": 1731859200
   }
   ```
3. **Signature**: Cryptographic hash created by Supabase using the project's secret key.

### How FastAPI Verifies It:
Look at `backend/app/core/auth.py`:
```python
def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security), supabase: Client = Depends(get_supabase_client)):
    token = credentials.credentials
    # Supabase validates token signature and returns User object
    user_resp = supabase.auth.get_user(token)
    if not user_resp or not user_resp.user:
        raise HTTPException(status_code=401, detail="Invalid authentication credentials")
    return user_resp.user
```
The FastAPI backend trusts Supabase's signature; no plain passwords ever cross the API gateway.

---

## 5. Authentication State in Flutter

### React Native vs. Flutter State Comparison:

| Feature | React Native (`mobile/contexts/AuthContext.tsx`) | Flutter (`flutter_app/lib/app/app.dart`) |
| :--- | :--- | :--- |
| **Event Listener** | `supabase.auth.onAuthStateChange((event, session) => ...)` | `authService.authStateChanges` (Dart `Stream<TessAuthState>`) |
| **UI Integration** | React Context + `useAuth()` hook | `StreamBuilder<TessAuthState>` in `AuthGate` |
| **Persistence** | `AsyncStorage` | `SharedPreferences` (wrapped by `supabase_flutter`) |

### The TESS AuthGate Pattern:
In [app.dart](file:///home/bhavanamj/Desktop/Tess/flutter_app/lib/app/app.dart):
```dart
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TessAuthState>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isAuthenticated) {
          return const MainNavigationShell(); // User is logged in
        }
        return LoginScreen(); // User is unauthenticated
      },
    );
  }
}
```
When `authService.signOut()` is called anywhere in the app, the stream emits an unauthenticated state, and `StreamBuilder` immediately replaces the dashboard with `LoginScreen`.

---

## 6. Flutter Async Authentication Flows

When a user submits credentials in [login_screen.dart](file:///home/bhavanamj/Desktop/Tess/flutter_app/lib/features/auth/screens/login_screen.dart):
1. **Form Validation**: `_formKey.currentState?.validate()` checks for email syntax and non-empty password.
2. **Loading State**: `setState(() => _isLoading = true)` replaces the button with a spinning `CircularProgressIndicator`.
3. **Async Call**: `await _authService.signInWithPassword(...)` makes a network request to Supabase.
4. **Error Catching**: If credentials fail, Supabase throws an `AuthException`. We catch it, map it to a readable message (`"Invalid email or password"`), and show an inline error card.

---

## 7. HTTP Requests & Networking

In mobile environments, network connections are unpredictable (WiFi to Cellular switches, latency spikes, offline mode).

In [api_client.dart](file:///home/bhavanamj/Desktop/Tess/flutter_app/lib/core/network/api_client.dart):
- **Timeouts**: Every request uses `.timeout(config.timeout)` (15 seconds).
- **SocketException Handling**: Catches physical network disconnections and returns an informative error.
- **TimeoutException Handling**: Catches slow connections before the UI freezes.

---

## 8. JSON Serialization

Dart requires explicit serialization between raw strings and strongly typed models.
- **Serialization (Model -> JSON)**: `jsonEncode(model.toJson())`
- **Deserialization (JSON -> Model)**: `Model.fromJson(jsonDecode(response.body))`

Example in `Task.fromJson`:
```dart
factory Task.fromJson(Map<String, dynamic> json) {
  return Task(
    id: json['id'] as String,
    title: json['title'] as String,
    category: json['category'] as String,
    priority: TaskPriority.values.firstWhere((p) => p.name == json['priority']),
    isCompleted: json['isCompleted'] as bool? ?? false,
  );
}
```

---

## 9. API Service Architecture

The TESS client separates concerns cleanly:
1. `AuthService`: Owns authentication tokens and Supabase session lifecycle.
2. `ApiClient`: Generic HTTP engine that requests the token from `AuthService` and injects `Authorization: Bearer <token>` into outgoing requests.
3. Feature Screens: Consume high-level methods (`apiClient.get('/api/v1/devices')`) without knowing about token refresh or header formatting.

---

## 10. Environment Configuration & Platform Networking

When testing on different devices, the backend URL changes based on network routing:

| Platform | Host URL | Rationale |
| :--- | :--- | :--- |
| **Linux Desktop** | `http://127.0.0.1:8000` | Local loopback interface on same machine |
| **Android Emulator** | `http://10.0.2.2:8000` | Android Virtual Device alias to host machine loopback |
| **Physical Phone (WiFi)** | `http://192.168.1.175:8000` | Local Area Network (LAN) IP of developer workstation |

Configured in [app_config.dart](file:///home/bhavanamj/Desktop/Tess/flutter_app/lib/core/config/app_config.dart) with runtime `--dart-define` flag support:
```bash
flutter run --dart-define=BACKEND_URL=http://192.168.1.175:8000
```

---

## 11. Error Handling

We map raw HTTP status codes to actionable user feedback:
- **401 Unauthorized**: Session expired; informs user to log in again.
- **403 Forbidden**: Access restricted.
- **500 Internal Server Error**: Parses backend JSON `{ "detail": "message" }`.
- **503 Unavailable**: Backend node offline or unreachable.

---

## 12. Secure Credential Management

1. **Publishable/Anon Key Only**: The mobile client **only** receives `SUPABASE_PUBLISHABLE_KEY`. This key has limited permissions governed strictly by PostgreSQL Row-Level Security (RLS).
2. **Never Expose Service-Role Keys**: Service-role keys bypass all RLS policies and must exist **exclusively** on the FastAPI backend server (`backend/.env`).
3. **Token Masking**: Our `ApiClient._log()` method strips out token headers before printing to console, preventing accidental token leaks in production logs or error reporting tools.

---
*Authored for the TESS Personal AI Operating System — Phase 14.3 Engineering Guide.*


# TESS Phase 14.4 — Real Dashboard & Backend Integration Master Guide

Welcome to the **TESS Phase 14.4 Master Learning Guide**. This milestone transforms the Flutter companion from a static placeholder into a functional, live dashboard consuming real data from the FastAPI backend and Supabase session state.

---

## Table of Contents
1. [API Integration in Flutter](#1-api-integration-in-flutter)
2. [The HTTP Request Lifecycle](#2-the-http-request-lifecycle)
3. [JSON Serialization & Strong Typing](#3-json-serialization--strong-typing)
4. [Model Classes: Designing for Real Backends](#4-model-classes-designing-for-real-backends)
5. [Async / Await in Production Applications](#5-async--await-in-production-applications)
6. [Managing Loading, Data, and Error States](#6-managing-loading-data-and-error-states)
7. [Service Layer vs. UI Layer Responsibilities](#7-service-layer-vs-ui-layer-responsibilities)
8. [Widget Lifecycle During Network Calls](#8-widget-lifecycle-during-network-calls)
9. [Implementing Pull-to-Refresh](#9-implementing-pull-to-refresh)
10. [State Management Architectural Decisions](#10-state-management-architectural-decisions)

---

## 1. API Integration in Flutter

In modern client architecture, UI widgets should never construct HTTP headers, parse raw JSON strings, or hardcode endpoint URIs.

### The TESS Pipeline:
```
  ┌──────────────────────────────────────────────────────────────┐
  │         UI Layer (HomeScreen & Presentation Widgets)         │
  └──────────────────────────────┬───────────────────────────────┘
                                 │ Calls high-level domain method: fetchDashboardData()
                                 ▼
  ┌──────────────────────────────────────────────────────────────┐
  │     Service Layer (DashboardService & AuthService)           │
  └──────────────────────────────┬───────────────────────────────┘
                                 │ Executes typed requests & resolves models
                                 ▼
  ┌──────────────────────────────────────────────────────────────┐
  │         Core Network Engine (ApiClient with Bearer JWT)      │
  └──────────────────────────────┬───────────────────────────────┘
                                 │ Sends HTTP via http.Client with 15s timeout
                                 ▼
  ┌──────────────────────────────────────────────────────────────┐
  │                 FastAPI Backend Server (:8000)               │
  └──────────────────────────────────────────────────────────────┘
```

---

## 2. The HTTP Request Lifecycle

When `HomeScreen` mounts and requests data:
1. **Authentication Check**: `ApiClient` calls `AuthService.getAccessToken()` to retrieve the current Supabase session JWT.
2. **Header Construction**: Injects `Authorization: Bearer <token>`, `Content-Type: application/json`, and `Accept: application/json`.
3. **Execution & Timeout**: Sends asynchronous GET request wrapped with `.timeout(Duration(seconds: 15))`.
4. **Status Code Evaluation**:
   - `200 OK`: Decodes body from UTF-8 JSON.
   - `401 Unauthorized`: Throws `ApiException(401)` advising session refresh.
   - `500 Server Error`: Parses `{ "detail": "..." }` into typed exception.
   - `SocketException`: Catches device network disconnects.

### React Native Comparison:
In `mobile/services/api.ts`:
```typescript
const headers = await getHeaders();
const response = await safeFetch(`${BACKEND_URL}/api/v1/productivity/summary`, { headers });
return handleResponse(response);
```
In Flutter `lib/core/network/api_client.dart`:
```dart
final headers = await _buildHeaders(requiresAuth: true);
final response = await _httpClient.get(uri, headers: headers).timeout(config.timeout);
return _handleResponse(response);
```
Both platforms use an identical gateway contract and token injection mechanism.

---

## 3. JSON Serialization & Strong Typing

Unlike JavaScript where JSON is parsed dynamically into untyped objects, Dart is strongly typed.
If a backend sends `{ "overdue": 3 }`, accessing `json['overdue']` returns an `Object?`.

In [dashboard_model.dart](file:///home/bhavanamj/Desktop/Tess/flutter_app/lib/features/home/models/dashboard_model.dart):
```dart
factory ProductivitySummaryModel.fromJson(Map<String, dynamic>? json) {
  if (json == null) return const ProductivitySummaryModel();
  return ProductivitySummaryModel(
    totalActive: json['total_active'] as int? ?? 0,
    overdue: json['overdue'] as int? ?? 0,
    dueToday: json['due_today'] as int? ?? 0,
    dueThisWeek: json['due_this_week'] as int? ?? 0,
    completedRecently: json['completed_recently'] as int? ?? 0,
  );
}
```
**Defensive Parsing**:
- Use `as int? ?? 0` so that if a key is missing or null, the application never crashes with a `TypeError` or `NullCheckError`.

---

## 4. Model Classes: Designing for Real Backends

FastAPI schemas use `snake_case` (e.g. `total_active`, `prediction_type`), while Dart conventions use `camelCase` (e.g. `totalActive`, `predictionType`).

### Probability vs. Confidence:
The backend returns two distinct attributes:
- `probability`: Numerical floating-point value (`0.85` or `85.0`).
- `confidence`: Qualitative categorical rating (`"HIGH"`, `"MEDIUM"`, `"LOW"`).

In `BackendFuturePredictionModel`:
```dart
final double probability;
final String confidence;

// Normalizing raw backend numbers (handles both 0.0-1.0 and 0-100)
double parsedProb = rawProb > 1.0 ? rawProb.toDouble() : (rawProb * 100).toDouble();
```
We keep these metrics strictly separate so users see both the statistical probability and the AI engine's confidence tier.

---

## 5. Async / Await in Production Applications

### Parallel Request Execution:
When loading the dashboard, we must fetch both Productivity Summary and Future Predictions. Calling them sequentially would double network latency:
```dart
// SLOW: Sequential Execution (~1.5s + ~1.5s = ~3.0s)
final summary = await _fetchSummary();
final predictions = await _fetchPredictions();

// FAST: Parallel Execution with Future.wait (~1.5s total)
final results = await Future.wait([
  _fetchSummary(),
  _fetchPredictions(),
]);
```
`Future.wait` fires both HTTP requests simultaneously over concurrent sockets and completes only when both responses return.

---

## 6. Managing Loading, Data, and Error States

In `_HomeScreenState`, state is represented by three explicit variables:
```dart
bool _isLoading = true;
DashboardData? _dashboardData;
String? _errorMessage;
```

### Transition Matrix:
| State | `_isLoading` | `_dashboardData` | `_errorMessage` | Mascot State |
| :--- | :--- | :--- | :--- | :--- |
| **Initial / Fetching** | `true` | `null` or previous | `null` | `MascotState.thinking` |
| **Success (Nominal)** | `false` | populated | `null` | `MascotState.idle` |
| **Success (Alerts)** | `false` | has overdue/risk | `null` | `MascotState.attention` |
| **Success (Wins)** | `false` | completed > 0 | `null` | `MascotState.happy` |
| **Network / Server Error** | `false` | `null` | error string | `MascotState.attention` |

---

## 7. Service Layer vs. UI Layer Responsibilities

| Responsibility | Layer | File |
| :--- | :--- | :--- |
| Fetching HTTP endpoints | Service | `DashboardService`, `ApiClient` |
| Deserializing JSON into models | Model | `ProductivitySummaryModel`, `BackendFuturePredictionModel` |
| Managing loading / retry state | UI State | `HomeScreen` |
| Rendering layout & animations | UI Presentation | `GreetingSection`, `ProductivityOverview`, `FuturePreview` |

This separation ensures that if an endpoint route changes in FastAPI, only `DashboardService` needs an update, leaving all presentation widgets untouched.

---

## 8. Widget Lifecycle During Network Calls

### The `mounted` Guard:
When an asynchronous `await` completes, the user might have already navigated away from the screen. Calling `setState()` on an unmounted widget throws a Flutter framework exception:
```dart
final data = await _dashboardService.fetchDashboardData();

// ALWAYS verify mounted before calling setState!
if (mounted) {
  setState(() {
    _dashboardData = data;
    _isLoading = false;
  });
}
```

---

## 9. Implementing Pull-to-Refresh

Flutter provides the standard `RefreshIndicator` widget:
```dart
RefreshIndicator(
  color: AppColors.violet,
  backgroundColor: AppColors.bgSurface,
  onRefresh: _loadDashboardData, // Must return Future<void>
  child: SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(), // Ensures scrolling even when content fits screen
    child: ...
  ),
)
```
- Setting `physics: const AlwaysScrollableScrollPhysics()` guarantees that pull-to-refresh gestures trigger even on large tablet screens where the content does not naturally overflow the viewport.

---

## 10. State Management Architectural Decisions

In Phase 14.4, we deliberately utilized Flutter's built-in `StatefulWidget` and `setState` rather than introducing complex third-party state managers (Riverpod, Bloc, MobX):
1. **Zero External Overhead**: Keeps the application lightweight and fast to compile.
2. **Encapsulated Scope**: Dashboard loading state belongs solely to the home dashboard view.
3. **Transparent Debugging**: No dependency injection magic; every data transition is directly traceable in `_loadDashboardData()`.

---
*Authored for the TESS Personal AI Operating System — Phase 14.4 Engineering Guide.*


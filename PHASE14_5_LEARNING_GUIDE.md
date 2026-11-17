# TESS Phase 14.5 Learning Guide: Flutter Chat & Personal Memory Architecture

## 1. Executive Summary & Architecture Overview

Phase 14.5 connects the TESS Flutter application to the core conversational AI and persistent personal memory subsystem powered by the existing FastAPI backend and Supabase PostgreSQL persistence layer.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        TESS FLUTTER CLIENT                             │
├───────────────────────────────┬────────────────────────────────────────┤
│     Chat Subsystem            │         Personal Memory Bank           │
│  - ChatScreen                 │  - MemoryScreen                        │
│  - ChatMascotHeader           │  - MemoryCard                          │
│  - ChatBubble (Optimistic)    │  - CreateMemorySheet                   │
│  - ChatInputBar (Guarded)     │  - MemoryService                       │
│  - ConversationSheet          │  - MemoryModel                         │
│  - ChatService                │                                        │
│  - ChatMessageModel           │                                        │
└───────────────┬───────────────┴───────────────────┬────────────────────┘
                │                                   │
                ▼                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        CORE NETWORK LAYER                              │
│  - ApiClient (GET, POST, PUT, DELETE)                                  │
│  - Automatic Supabase Bearer JWT Injection & 15s Timeout               │
└───────────────────────────────┬────────────────────────────────────────┘
                                │ HTTP / JSON
                                ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        FASTAPI BACKEND SERVICE                         │
│  - POST /api/v1/conversations/{id}/messages (Cognitive Prompting)       │
│  - GET/POST /api/v1/conversations                                      │
│  - GET/POST/PUT/DELETE /api/v1/memories                                │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Deep Dive: Dart & Flutter Concepts Explained

### 2.1 Optimistic UI Updates vs Eventual Consistency
In conventional mobile apps, messages are only appended after the server returns an HTTP 200 response. In a companion AI like TESS, this creates an unnatural latency where the user wonders if their directive was received.

In Flutter, we implement **Optimistic UI Updates**:
1. When the user taps **Send**, a local `ChatMessageModel` is immediately generated with:
   ```dart
   isPending: true,
   hasFailed: false,
   id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
   ```
2. The UI instantly appends this pending bubble to `_messages` and calls `_scrollToBottom()`.
3. The `ChatInputBar` locks inputs (`isSending = true`) to guard against duplicate submissions.
4. When `ChatService.sendMessage()` resolves:
   - The pending user message is updated to `isPending: false`.
   - The assistant's `ChatMessageModel` response is appended.
   - The Mascot state transitions to `MascotState.happy` (or `MascotState.attention` if risk keywords are detected).
5. If the request fails (e.g. timeout or network outage):
   - The pending message is marked with `hasFailed: true`.
   - A retry prompt appears directly under the bubble: *"Failed to transmit. Tap to retry."*

### 2.2 Asynchronous Concurrency & Cancellation
In Dart, every `async` function returns a `Future`. Unlike JavaScript promises, Dart futures are tightly integrated into the event loop:
- `Future.wait([_loadThreads(), _loadMemories()])` allows parallel execution of independent endpoints.
- If a widget unmounts during an asynchronous wait, calling `setState()` throws an exception. In Flutter, we always guard post-await UI updates with:
  ```dart
  if (!mounted) return;
  setState(() { ... });
  ```

### 2.3 Sound Null Safety & Defensive Serialization
FastAPI schemas use Pydantic models where fields like `updated_at`, `provenance`, or `title` may be optional or nullable.
In `ConversationModel`, `ChatMessageModel`, and `MemoryModel`, we employ defensive null coalescing:

```dart
factory ConversationModel.fromJson(Map<String, dynamic> json) {
  return ConversationModel(
    id: json['id'] as String? ?? '',
    userId: json['user_id'] as String? ?? '',
    title: (json['title'] as String?)?.isNotEmpty == true
        ? json['title'] as String
        : 'New Conversation',
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
        : DateTime.now(),
    updatedAt: json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
        : DateTime.now(),
  );
}
```

---

## 3. Comparing Flutter with React Native

| Architectural Area | React Native + Expo | Flutter 3.50 + Dart |
|---|---|---|
| **Chat Stream Rendering** | `FlatList` with `renderItem` and `keyExtractor`. Uses native bridge for scrolling. | `ListView.builder` directly manages render objects on the Skia/Impeller canvas with zero bridge overhead. |
| **Keyboard Dismissal & SafeArea** | `KeyboardAvoidingView` with platform-specific behavior (`padding` vs `height`). | Built-in `MediaQuery.of(context).viewInsets.bottom` and `SafeArea(top: false)` adapts naturally across iOS, Android, and Web. |
| **Component Typing** | TypeScript interfaces (`interface Memory`). Types disappear at runtime. | Sound null-safe Dart classes. Runtime type checks prevent crashes from unexpected JSON payloads. |
| **Component State** | `useState`, `useEffect`, and `useRef`. Prone to stale closures during async delays. | `StatefulWidget` with explicit `initState`, `dispose`, and `mounted` checks. |
| **Modal Sheets** | Third-party `@gorhom/bottom-sheet` or native modals requiring separate configuration. | Built-in `showModalBottomSheet(isScrollControlled: true)`. Fully customizable with spatial dark themes. |

---

## 4. TESS Personality & Mascot Reactive Engine

The TESS mascot is not a static decoration; it acts as a visual emotional telemetry monitor:

```dart
enum MascotState {
  idle,         // •_• (Violet)   Ready for directives
  thinking,     // O_O (Light Violet) Cognitive engine processing prompt
  listening,    // O_o (Cyan)     Awaiting user audio/text
  speaking,     // ^o^ (Emerald)  Streaming or verbalizing response
  intervening,  // O_O! (Rose)    Proactive simulation warning
  attention,    // O_O! (Amber)   Overdue tasks or convergence alerts
  happy,        // ^_^ (Emerald)  Successful task completion or trajectory sync
  error,        // x_x (Rose)     Transmission failure or network dropout
}
```

In `ChatScreen._handleSendMessage()`, the response text is scanned for contextual cues:
- If the response references `overdue`, `risk`, `warning`, `alert`, or `attention`, the mascot transitions to **ATTENTION** (`O_O!`).
- Standard successful answers trigger **HAPPY** (`^_^`).
- Network dropouts trigger **ERROR** (`x_x`).


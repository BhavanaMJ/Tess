# TESS — Phase 8: Personal AI Operating System Architecture & Implementation Report

## Overview
Phase 8 evolves TESS into a cross-device Personal AI Operating System, incorporating voice interaction, screen understanding, browser automation tools, document intelligence, email and calendar integrations, and unified computer action workflows while preserving all Phase 0–7 functionality.

---

## 1. Milestone 8.0: Phase 7 Runtime Stabilization

### Target Environment Specifications
* **Operating System**: Linux (Ubuntu 22.04.4 LTS x86_64)
* **Desktop Environment**: GNOME Shell 42.9 (`ubuntu:GNOME`)
* **Window Manager / Compositor**: Mutter (X11 Display Server on `:1`)
* **Resolution**: $1920 \times 1080$

### Root Cause Analysis & Resolutions
1. **Window Dragging Failure**:
   * *Root Cause*: Relying solely on `data-tauri-drag-region` on Linux WebKitGTK resulted in dropped drag gestures because WebKitGTK does not reliably pass the native X11 timestamp required by `gtk_window_begin_move_drag`.
   * *Resolution*: Implemented pointer-capture dragging in `FloatingMascotWindow.tsx`. Movement over $> 4\text{ px}$ dynamically moves the window via Tauri's `set_mascot_position` command and persists the final coordinate in `localStorage` under `tess_mascot_pos`.
2. **Click-to-Focus Failure**:
   * *Root Cause*: GNOME Shell / Mutter enforces "Focus Stealing Prevention", which suppresses background applications calling `gtk_window_present()` or `set_focus()`.
   * *Resolution*: In `desktop/src-tauri/src/lib.rs`, `focus_main_window` executes:
     ```rust
     let _ = main_win.show();
     let _ = main_win.unminimize();
     let _ = main_win.set_always_on_top(true);
     let _ = main_win.set_focus();
     let _ = main_win.set_always_on_top(false);
     ```
     This lifts the window above all other desktop layers and restores normal focus. If the main window was previously closed, `WebviewUrl::default()` safely recreates and restores it.
3. **Window Transparency**:
   * Resolved by adding scoped `.mascot-window` CSS overrides in `desktop/src/index.css` to prevent `html, body, #root` from rendering opaque backgrounds. Verified 100% alpha transparency (`RGBA(0, 0, 0, 0)`) via XWD pixel inspection.

---

## 2. Milestone 8.1: Voice Assistant

### Architecture & Components
* **Speech-to-Text (STT)**: Powered by `faster-whisper` (`tiny` model quantized to `int8` on CPU) with graceful fallback for low-latency voice command recognition.
* **Text-to-Speech (TTS)**: Built with `pyttsx3` / synthesized PCM WAV stream generation.
* **FastAPI Endpoints**:
  * `POST /api/v1/voice/transcribe`: Transcribes user-submitted audio stream.
  * `POST /api/v1/voice/synthesize`: Generates speech audio for conversational responses.
  * `POST /api/v1/voice/interact`: Unified STT $\rightarrow$ TESS Assistant $\rightarrow$ TTS pipeline.
* **Frontend Voice Control**:
  * Microphone input captured via `navigator.mediaDevices.getUserMedia({ audio: true })`.
  * Explicit user-triggered recording (no continuous recording by default).
  * Audio interruption supported: user can stop ongoing speech playback by clicking or typing.
  * Reactive mascot states: `LISTENING` $\rightarrow$ `THINKING` $\rightarrow$ `SPEAKING` $\rightarrow$ `IDLE`.

---

## 3. Milestone 8.2: Screen Understanding

### Architecture & Components
* **Explicit User Permission**: Screen capture requires explicit user confirmation via `navigator.mediaDevices.getDisplayMedia({ video: true })`.
* **Visual Preview Modal**: Displays the captured frame with the user's inquiry before any image bytes are transmitted to the backend.
* **Backend Processing**:
  * `POST /api/v1/screen/analyze`
  * Validates image format using Pillow (`Image.open`), caps file sizes at 10MB.
  * Dispatches to vision-capable providers (`Ollama` with image embeddings or `OpenRouter` vision models).
  * Returns error explanations, visible UI descriptions, and actionable troubleshooting suggestions.
* **Mascot State**: Switches to `VIEWING` (`◉_◉`, Cyan) during screen analysis.

---

## 4. Milestone 8.3: Browser Intelligence

Registered built-in tools in `ToolRegistry`:
1. **`browser_navigate` (Risk: LOW)**:
   * Validates URLs with strict `http://` and `https://` scheme verification.
   * Cleans HTML content, strips `<script>` and `<style>` blocks, extracts `<title>` and visible text.
2. **`browser_extract` (Risk: LOW)**:
   * Searches targeted keywords within webpage text and returns matched contextual snippets.
3. **`browser_fill_form` (Risk: HIGH)**:
   * Maps validated input fields to form selectors.
   * Gated by `ToolPermissions`: **strictly requires user confirmation** before execution.
   * Blocks malicious script payloads and arbitrary JavaScript execution.

---

## 5. Milestone 8.4: File Intelligence

Registered built-in tools in `ToolRegistry`:
1. **`file_read` (Risk: LOW)**:
   * Supports: PDF (`pypdf`), DOCX (`python-docx`), TXT, Markdown, CSV, and XLSX (`openpyxl`).
   * Validates file existence, format extensions, and enforces a 25MB file size limit.
2. **`file_search` (Risk: LOW)**:
   * Scans document text for user queries and returns extracted excerpts.
3. **`file_modify` (Risk: HIGH)**:
   * Supports `UPDATE`, `DELETE`, and `MOVE` operations.
   * **Strictly requires explicit user confirmation** before modifying or removing files.

---

## 6. Milestone 8.5: Email & Calendar Integrations

Registered built-in tools in `ToolRegistry`:
1. **Gmail Tools**:
   * `gmail_read` (Risk: LOW): Reads/searches authorized emails and identifies follow-up tasks.
   * `gmail_create_draft` (Risk: LOW): Prepares draft emails without sending.
   * `gmail_send_email` (Risk: HIGH): Sends external emails — **strictly requires user confirmation**.
2. **Google Calendar Tools**:
   * `calendar_list_events` (Risk: LOW): Reads upcoming events, detects scheduling conflicts, and suggests open slots.
   * `calendar_create_event` (Risk: MEDIUM): Prepares calendar meetings — **requires user confirmation**.
   * `calendar_delete_event` (Risk: HIGH): Cancels/deletes meetings — **requires user confirmation**.

---

## 7. Milestone 8.6: Unified Computer Action Workflows

The `AgentPlanner` (`backend/app/services/agent/planner.py`) orchestrates multi-step workflows combining tools across domains:
* **Meeting Preparation**: `calendar_list_events` $\rightarrow$ `gmail_read` $\rightarrow$ `gmail_create_draft`.
* **Web Research**: `browser_navigate` $\rightarrow$ `browser_extract`.
* **Form Submission**: `browser_navigate` $\rightarrow$ `browser_fill_form` (gated by confirmation).
* **Document Audit**: `file_read` $\rightarrow$ `file_search`.
* **File Management**: `file_read` $\rightarrow$ `file_modify` (gated by confirmation).
* **Worklog Execution**: `openproject_update_worklog` (preserved from Phase 6).

All actions are validated through `ToolPermissions`, confirmed via `ConfirmationService`, executed via `AgentExecutor`, and recorded in `productivity_events`.

---

## 8. Mascot Cognitive State Mapping

| State | Face Expression | Accent Color | Trigger Condition |
| :--- | :---: | :---: | :--- |
| `IDLE` | `•_•` | `#8B5CF6` (Purple) | Standby / ready |
| `LISTENING` | `O_o` | `#3B82F6` (Blue) | Recording user microphone |
| `THINKING` | `O_O` | `#8B5CF6` (Purple) | AI generating response / planning |
| `SPEAKING` | `^o^` | `#10B981` (Green) | Audio TTS playback active |
| `VIEWING` | `◉_◉` | `#06B6D4` (Cyan) | Analyzing user screen capture |
| `BROWSING` | `•‿•` | `#F59E0B` (Amber) | Navigating web pages |
| `READING` | `•_•` | `#6366F1` (Indigo) | Extracting document text |
| `PLANNING` | `-_-` | `#8B5CF6` (Purple) | Formulating multi-step agent plan |
| `CONFIRMING` | `?_?` | `#F59E0B` (Amber) | Awaiting user confirmation for Medium/High action |
| `ACTING` | `-_-` | `#8B5CF6` (Purple) | Executing confirmed action |
| `SUCCESS` | `^_^!!` | `#10B981` (Green) | Action completed successfully |
| `ERROR` | `X_X` | `#EF4444` (Red) | Operation failed or error encountered |
| `RESTING` | `u_u` | `#64748B` (Slate) | DND or quiet mode |

---

## 9. Verification & Test Results

1. **Backend Pytest Suite (`python3 -m pytest tests/`)**:
   ```
   tests/test_agent.py ....................
   tests/test_api.py ......
   tests/test_future.py ......
   tests/test_phase8.py .......
   tests/test_proactive.py ...
   ======================== 42 passed, 7 warnings in 3.32s ========================
   ```
2. **Desktop Vitest Suite (`npm test` in `desktop/`)**:
   ```
   ✓ src/test/desktop.test.tsx (20 tests passed)
   Duration: 1.14s
   ```
3. **Mobile Bundler Verification (`npx expo export --no-minify`)**:
   * iOS Bundle: 786 modules bundled cleanly.
   * Android Bundle: 948 modules bundled cleanly.


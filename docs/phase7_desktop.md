# Phase 7 — Cross-Device Companion Documentation

## 1. Overview
Phase 7 extends TESS into a cross-device companion with two desktop experiences:
1. **Full TESS Desktop Application**: A rich workstation dashboard for chat, task tracking, future simulations, proactive intervention management, Phase 6 agent execution, and memory review.
2. **Floating TESS Mascot**: A small, frameless, draggable, always-on-top desktop companion that reflects TESS's active cognitive state in real time and provides quick access to the main app.

Both Android and Desktop run off the same FastAPI backend, Supabase PostgreSQL database, and AI providers.

---

## 2. Directory Structure

```
desktop/
  src/
    components/
      Mascot.tsx           # 2D ASCII/graphic face component with states & animations
      Header.tsx           # Global header with sync trigger and mascot visibility toggle
      Sidebar.tsx          # Desktop navigation with badges
      Layout.tsx           # Main workstation layout with background sync
    screens/
      HomeScreen.tsx       # Overview dashboard with metrics & active alerts
      ChatScreen.tsx       # Multi-conversation desktop chat interface
      TasksScreen.tsx      # OpenProject work package list with filters & sync
      FuturesScreen.tsx    # Probabilistic trajectory & 24h/3d/7d simulator
      InterventionsScreen.tsx # Proactive cards with FIX IT, LATER, DISMISS
      AgentActivityScreen.tsx # Phase 6 plan review, confirmation & execution
      MemoryScreen.tsx     # Long-term memory review, creation, and deletion
      SettingsScreen.tsx   # Notification preferences, mascot toggle & device list
      LoginScreen.tsx      # Supabase authentication interface
    services/
      api.ts               # Centralized API service with JWT auth
      notifications.ts     # Native desktop notification integration
    contexts/
      AuthContext.tsx      # Supabase auth state & device registration
      MascotContext.tsx    # Cross-window mascot state synchronization
    mascot/
      FloatingMascotWindow.tsx # Frameless, draggable, transparent companion window
    types/
      index.ts             # Shared desktop TypeScript interfaces
    App.tsx                # Multi-window entry router (main vs. mascot)
    main.tsx               # React root mounting
    index.css              # Dark-theme desktop design system & utility classes
  src-tauri/
    src/
      main.rs              # Rust entry point
      lib.rs               # Custom Tauri commands (focus, toggle, position)
    capabilities/
      default.json         # Scoped Tauri security permissions
    icons/                 # Desktop application icons
    tauri.conf.json        # Tauri multi-window configuration
  package.json
  tsconfig.json
  vite.config.ts
```

---

## 3. Technology Stack
- **Framework**: Tauri 2
- **Frontend**: React 18 + TypeScript + Vite
- **Styling**: Tailored dark-theme system with purple primary accent (`#8B5CF6`)
- **Backend API**: FastAPI (`/api/v1/*`)
- **Database**: Supabase PostgreSQL with Row Level Security (RLS)
- **Testing**: Vitest + React Testing Library (19 automated tests)

---

## 4. Floating Mascot Architecture & Multi-Window Setup

Tauri 2 manages two windows defined in `tauri.conf.json`:
1. `"main"`: Standard application window ($1140 \times 780$, resizable, centered, standard window chrome).
2. `"mascot"`: Compact window ($160 \times 200$, frameless, transparent background, always-on-top, skip taskbar, draggable).

Both windows point to the same Vite frontend bundle:
- Main window loads `index.html`.
- Mascot window loads `index.html?window=mascot`.
- `App.tsx` inspects `window.location.search` to render `FloatingMascotWindow` when `window=mascot`.
- State is synchronized across windows in real time using `BroadcastChannel('tess_mascot_broadcast')`.
- Clicking the mascot invokes the Tauri Rust command `focus_main_window` to bring the main window into view.

### Mascot States
| State | Face | Accent Color | Behavior |
| :--- | :--- | :--- | :--- |
| `IDLE` | `•_•` | Purple (`#8B5CF6`) | Waiting, ready for interaction |
| `THINKING` | `O_O` | Blue (`#3B82F6`) | Generating chat response |
| `ATTENTION` | `O_O!` | Red (`#EF4444`) | Urgent future risk detected |
| `INTERVENING` | `O_O!` | Amber (`#F59E0B`) | Proactive intervention active |
| `PLANNING` | `-_-` | Purple (`#8B5CF6`) | Formulating tool execution plan |
| `CONFIRMING` | `?_?` | Amber (`#F59E0B`) | Awaiting user confirmation |
| `ACTING` | `-_-` | Purple (`#8B5CF6`) | Executing confirmed action |
| `SUCCESS` | `^_^!!` | Green (`#10B981`) | Action completed |
| `ERROR` | `X_X` | Red (`#EF4444`) | API or execution error |
| `SLEEPING` | `u_u` | Gray (`#6B7280`) | Quiet mode |

---

## 5. Desktop Notifications
Native desktop notifications are implemented via `@tauri-apps/plugin-notification` with Web Notification API fallback.
- **Channels**: Future risks, upcoming deadlines, proactive interventions, and agent action results.
- **Privacy**: If `detailedPreviews` is disabled in Settings, sensitive information is masked (`"TESS has an update requiring your attention."`).
- **Spam Prevention**: Cooldown cache prevents duplicate notifications within 60 seconds.

---

## 6. Cross-Device Synchronization
- All data is synchronized via the central backend.
- Background polling (`Layout.tsx`) runs every 60 seconds and on tab focus.
- Device registry (`user_devices` table) tracks each active client (Android, Linux desktop, Windows desktop) with automatic registration upon login.

---

## 7. Build and Platform Setup

### Frontend Build
```bash
cd desktop
npm install
npm run build    # Produces production bundle in desktop/dist/
npm test         # Runs 19 automated desktop Vitest tests
```

### Linux Desktop Prerequisites (for native `cargo tauri build`)
```bash
sudo apt update
sudo apt install -y pkg-config libdbus-1-dev libwebkit2gtk-4.1-dev libgtk-3-dev libssl-dev
```

Run in development mode:
```bash
npm run tauri dev
```

Build production bundle:
```bash
npm run tauri build
```

### Windows Desktop Prerequisites
1. Install [Visual Studio C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) (Desktop development with C++).
2. Install [WebView2 runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/) (preinstalled on Windows 10/11).
3. Run `npm run tauri build` to generate `.msi` and `.exe` installers.

---

## 8. Known Limitations
- Native compilation of the Tauri Rust binary requires platform C libraries (`pkg-config`, `libdbus-1-dev`, `libwebkit2gtk-4.1-dev` on Linux; MSVC on Windows). In environments without root/sudo or MSVC, the frontend web application runs in standard browser or Electron/WebKit view.
- Smartwatch integration is deliberately deferred to future phases; notification dispatch contracts remain extensible.


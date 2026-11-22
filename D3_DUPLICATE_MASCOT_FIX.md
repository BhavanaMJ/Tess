# TESS Phase D3 Bug Fix — Elimination of Duplicate Mascot Rendering

## 1. Issue Summary & Root Cause Analysis

### Identified Issue
When launching the TESS desktop application, users observed two mascot instances rendered simultaneously:
1. A large mascot SVG graphic inside the `DashboardWelcome` hero section at the center of the dashboard.
2. The persistent floating mascot window, which was positioned on the lower left of the screen overlapping the sidebar near Memory Core (`⌘7`).

### Root Causes
1. **Redundant Mascot Mount in Dashboard**:
   - `desktop/src/components/dashboard/DashboardWelcome.tsx` mounted `<Mascot state={mascotState} size="lg" showLabel={true} />` inside an ornamental container, creating a full second mascot avatar inside the main window.
2. **Window Coordinate & Sidebar Overlap**:
   - In Tauri multi-window mode, the `mascot` window was created without explicit initial placement in `tauri.conf.json`.
   - On Linux/X11, unmapped or default window placement positioned the transparent window at the default cascade position on the left side of the display (around `x: 0..200`), overlapping the `260px` sidebar near Memory Core.
   - In `FloatingMascotWindow.tsx`, restoring `tess_mascot_pos` from `localStorage` persisted and restored invalid or sidebar-overlapping coordinates without validating against the minimum sidebar width clearance.
   - In `src-tauri/src/lib.rs`, the monitor query in `.setup()` did not fall back to `primary_monitor()`, and `PhysicalPosition` calculations lacked a minimum physical sidebar clearance threshold.

---

## 2. Architectural Solution: Single Authoritative Persistent Mascot

### A. DashboardWelcome Refinement (`DashboardWelcome.tsx`)
- Removed the `<Mascot>` component and ornamental card entirely from `DashboardWelcome.tsx`.
- Replaced with a compact, text-based **Companion Telemetry Status Card**:
  - Displays `TESS COMPANION` headline with an animated pulse dot colored by the companion's authoritative emotion.
  - Displays a clean text status badge (`IDLE`, `THINKING`, `ATTENTION`, `CONFIRMING`, etc.).
  - Added a status indicator: `Floating Companion Active`.
  - Zero duplicate character graphics are mounted.

### B. Sidebar Emblem Alignment (`Sidebar.tsx`)
- Replaced the mini `<Mascot>` avatar in the sidebar brand header with a sleek vector brand monogram badge (`[T]`), ensuring the sidebar brand header does not mount an extra character.

### C. Companion Flyout Panel Alignment (`CompanionPanel.tsx`)
- In `CompanionPanel.tsx`, replaced the header mascot instance with a glowing companion avatar spark badge. Opening the panel or pressing `⌘M` does not spawn an additional character.

### D. Safe Floating Mascot Window Positioning (`FloatingMascotWindow.tsx` & `lib.rs`)
- Introduced `MIN_SIDEBAR_CLEARANCE_X = 320`:
  - The left sidebar width is `260px`.
  - A minimum horizontal boundary of `320px` guarantees that the floating window **never** overlaps the sidebar, navigation labels, or Memory Core.
- Default positioning dynamically places the floating window in the bottom-right workspace corner:
  - `x = Math.max(320, screenWidth - 220)`
  - `y = Math.max(100, screenHeight - 280)`
- In `src-tauri/src/lib.rs`:
  - Updated window placement to query `current_monitor().or_else(primary_monitor)`.
  - Enforced `(((size.width as f64) - (200.0 * scale)) as i32).max((320.0 * scale) as i32)` in physical pixels.
- In `FloatingMascotWindow.tsx`:
  - When dragging or restoring from `localStorage`, coordinates are clamped: `safeX = Math.max(320, ...)`.

---

## 3. Files Modified
1. `desktop/src/components/dashboard/DashboardWelcome.tsx`
2. `desktop/src/mascot/FloatingMascotWindow.tsx`
3. `desktop/src/components/Sidebar.tsx`
4. `desktop/src/components/companion/CompanionPanel.tsx`
5. `desktop/src-tauri/src/lib.rs`


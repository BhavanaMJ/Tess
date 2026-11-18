# TESS Expressive Mascot Integration & Architecture Specification

## 1. Overview & Identity

The TESS mascot is the visual and emotional anchor of the application. It represents an autonomous, highly capable personal companion that stays attentive to user workflows, schedules, and futures.

Identity Statement:
> **TESS: An expressive, luminescent, asymmetric organic presence living at the intersection of clarity and intelligence.**

---

## 2. Nine Canonical States (`TessMascotState`)

The companion transitions across 9 distinct states mapped directly to cognitive and backend activities:

| State | Role & Trigger | Visual Expression | Accent Color |
|:---|:---|:---|:---|
| `idle` | Resting baseline, monitoring ambient telemetry | Calm open eyes, gentle slow breathing oscillation | `AppColors.vibrantMint` (`#35B9A5`) |
| `thinking` | Querying LLM, calculating forecast, running inference | Inward curved focused eyes, dynamic breathing pulse | `AppColors.tessTeal` (`#168F83`) |
| `happy` | Request completed, good forecast, task marked done | Upturned cheerful arc eyes, subtle buoyant lift | `AppColors.success` (`#10B981`) |
| `attention` | Deadline risk detected, anomaly found | Wide alert eyes, prominent warning badge | `AppColors.warning` (`#F59E0B`) |
| `planning` | Formulating agent objective steps | Analytical gaze, subtle sequential pulse | `AppColors.tessTeal` (`#168F83`) |
| `confirming` | Human-in-the-loop authorization gate active | Inquisitive attentive gaze, awaiting user tap | `AppColors.warning` (`#F59E0B`) |
| `acting` | Actively executing approved tools | Dynamic focus, continuous progress resonance | `AppColors.vibrantMint` (`#35B9A5`) |
| `success` | Objective succeeded, action confirmed | Satisfied expression, radiant luminescent glow | `AppColors.success` (`#10B981`) |
| `error` | Network disconnect, permission denied | Soft downturned eyes, cautionary indicator | `AppColors.danger` (`#EF4444`) |

---

## 3. Organic Vector Fallback Architecture (`TessMascotFallback`)

Because production `.riv` files require continuous animation authoring pipelines, TESS features a high-fidelity procedural Flutter vector implementation using `CustomPainter`:

### 3.1 Mathematical Geometry
- **Asymmetrical Dual-Blob Silhouette**: Formed by two interconnected, smoothly blended Bézier curves with an aspect ratio of approximately 1.35 : 0.95.
- **Brand Palette**:
  - Primary body gradient: `vibrantMint` (`#35B9A5`) to `tessTeal` (`#168F83`).
  - Face illumination: `luminescentFace` (`#F4FFFB`).
  - Eye curvature: `deepEyes` (`#174C48`).
- **Idle Breathing Cycle**: 3200ms sine curve applying a subtle `scale(1.0 ± 0.02)` and vertical shift (`±1.5px`).
- **Natural Blink Cycle**: 140ms eyelid closure every 3400ms via `AnimationController` and `Timer`.
- **Resource Management**: Blink timer (`_blinkTimer`) is explicitly tracked and cancelled on `dispose()` to prevent memory leaks and test framework invariant failures.

---

## 4. Rive Integration Layer & Readiness

The `TessMascot` widget is built with explicit drop-in support for Rive animations:

```
                      +-----------------------------+
                      |         TessMascot          |
                      +--------------+--------------+
                                     |
                    Does assets/rive/tess_mascot.riv
                    exist and Rive is loaded?
                                     |
                   +-----------------+-----------------+
                   | YES                               | NO (Default)
                   v                                   v
    +------------------------------+     +-------------------------------+
    |        RiveAnimation         |     |      TessMascotFallback       |
    |  artboard: 'Tess'            |     |  CustomPainter (Vector cloud) |
    |  stateMachine: 'State Machine|     |  3.2s breath + 140ms blinks   |
    +------------------------------+     +-------------------------------+
```

### 4.1 Integration Contract for 3D/Rive Artists
1. **Asset Location**: Place the authored file at `flutter_app/assets/rive/tess_mascot.riv`.
2. **State Machine Name**: `State Machine 1` (or `TessStateMachine`).
3. **Inputs Required**:
   - `stateIndex` (Number: 0 = idle, 1 = thinking, 2 = happy, 3 = attention, 4 = planning, 5 = confirming, 6 = acting, 7 = success, 8 = error).
   - `triggerBlink` (Trigger).
   - `isDark` (Boolean: switches luminescent contrast).

---

## 5. Usage in Flutter Screens

### 5.1 Hero Mode (Dashboard / Auth)
```dart
TessMascot(
  state: TessMascotState.idle,
  size: 88.0,
  showStatusBadge: true,
)
```

### 5.2 Compact Mode (AppBars / Headers / List Items)
```dart
TessMascot.compact(
  state: TessMascotState.thinking,
  size: 38.0,
)
```

### 5.3 Temporary Reactive Expressions
```dart
final mascotController = TessMascotController();

// React to user completing a task:
mascotController.express(
  TessMascotState.happy,
  duration: const Duration(seconds: 3),
);
```

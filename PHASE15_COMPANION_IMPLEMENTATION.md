# TESS Phase 15 — Emotion-Driven Mascot Companion Implementation

## 1. Overview & Architectural Principles

The TESS Companion has been upgraded from a floating vector mascot into a fully expressive, emotion-driven personal AI companion. The visual identity, silhouette, proportions, and approved teal color palette have been preserved while introducing dynamic micro-expressions, facial anatomy, sensory antenna physics, and emotion-reactive luminescent auras.

All animations operate via custom Flutter vector shaders (`CustomPainter`), ensuring zero external dependencies (no heavy Lottie or Rive bundles required), 60 FPS rendering, respect for `MediaQuery.disableAnimations`, and deterministic lifecycle disposal.

---

## 2. Directory Structure & Key Components

```
flutter_app/lib/shared/companion/
├── tess_emotion.dart               # The 9 canonical emotion states & metadata
├── tess_companion_controller.dart  # State controller with auto-revert & duration support
├── tess_companion_painter.dart     # Organic CustomPainter for body, face & expressions
├── tess_companion.dart             # Reusable widget (Standard, Hero, Compact)
└── tess_companion_preview_screen.dart # Interactive developer lab for emotion inspection
```

---

## 3. The 9 Canonical Companion Emotions

Each emotion modulates 6 distinct visual facets simultaneously:

| Emotion | Eyes | Eyebrows | Mouth | Antenna | Body Physics | Reactive Aura |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`idle`** | Natural oval eyes, gentle 140ms blinks every 3.5s | Calm resting arc | Subtle sweet neutral curve | Gentle floating bob | 3.2s breathing float | Vibrant Mint (`#35B9A5`) |
| **`thinking`** | Inquisitive gaze shifted up-right with catchlight glint | Asymmetrical (one raised, one tilted) | Small contemplative curve | Tilted forward with pulse | 1.6s forward contemplative rhythm | TESS Teal (`#168F83`) |
| **`happy`** | Joyful upward crescents (`^ ^`) | Raised arched brows | Wide cheerful smile arc | Buoyant playful bounce | Squash & stretch joyful bounce | Vibrant Mint (`#35B9A5`) |
| **`attention`** | Wide observant circular eyes with dual catchlights | Raised high in alert stance | Curious open "o" mouth | Upright focused with glow | Alert vertical stretch (`+3%` Y) | Warning Amber (`#F59E0B`) |
| **`planning`** | Analytical steady forward gaze | Focused analytical brow | Subtle concentrated line | Rhythmic sensory pulse | Controlled forward lean | TESS Teal (`#168F83`) |
| **`confirming`** | Reassuring observant eyes | Expectant inquiring brow | Soft reassuring gentle smile | Gentle questioning tilt | Steady attentive hold | Soft Amber (`#F59E0B`) |
| **`acting`** | Dynamic focused forward eyes | Determined parallel brows | Confident purposeful line | Energetic sensory vibration | Dynamic forward posture | Vibrant Mint (`#35B9A5`) |
| **`success`** | Cheerful radiant crescent eyes | High celebratory brows | Broad radiant smile arc | Celebratory double bounce | Dynamic squash & stretch | Radiant Mint (`#35B9A5`) |
| **`error`** | Sympathetic downward-curved eyes | Soft furrowed brows | Gentle sympathetic downturn | Tilted downward sympathetically | Gentle lower slump (`+2.5px` Y) | Danger Coral (`#EF4444`) |

---

## 4. Widget Integration & Backward Compatibility

- **`TessCompanion`**: The new canonical widget supporting `TessCompanionSize.compact` (44px), `TessCompanionSize.standard` (80px), `TessCompanionSize.hero` (130px), and custom pixel dimensions.
- **`TessMascotFallback`**: Fully unified to delegate its rendering to `TessCompanionPainter` while mapping `TessMascotState` to `TessEmotion` 1:1. All existing screens (Home, Chat, Login, Modals) immediately benefit from the expressive eyebrows, mouth, antenna, and body physics without refactoring.
- **Interactive Lab**: `TessCompanionPreviewScreen` allows developers to test all 9 emotions, custom dimensions, transient transitions (e.g. 2s happy bounce, 3s thinking), and reduced motion toggles.


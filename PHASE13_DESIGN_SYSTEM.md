# TESS Phase 13 — Complete Futuristic Design System
## The Personal AI Operating System (Design Token & Interaction Specification)

---

## 1. Design Philosophy: Ambient Intelligence & Spatial Operating System

TESS is not a conventional productivity admin dashboard. It is a **Personal Future Simulator + AI Companion + Autonomous Agent Engine**.

The visual language is built around the paradigm:
```
PRESENT ACTION  ───►  CONSEQUENCE  ───►  POSSIBLE FUTURES  ───►  INTERVENTION  ───►  AUTONOMOUS ACTION
```

### Visual Hallmarks:
- **Deep Layered Void:** Rich cosmic dark canvas (`#080910`, `#0B0D18`) avoiding flat dead-black.
- **Controlled Neon Energy:** Dual-frequency illumination with Electric Violet (`#8B5CF6`) as consciousness/companion, and Cyan (`#22D3EE`) as futuristic predictive telemetry.
- **Glassmorphic Spatial Panels:** Translucent multi-layered surfaces with soft blurred backdrops (`backdrop-filter: blur(20px)`), frosted edges, and hairline glowing borders (`1px solid rgba(139, 92, 246, 0.2)`).
- **Living Mascot Presence:** A multi-ring holographic orb that pulses with state-driven breathing, orbital energy particles, audio frequency reactions, and diagnostic glows.

---

## 2. Color System & Design Tokens

### Surface Hierarchy
| Token Name | Hex / RGBA | Role / Semantics |
| :--- | :--- | :--- |
| `--bg-void` | `#05060A` | Deepest root level, window borders |
| `--bg-primary` | `#080910` | Primary application canvas |
| `--bg-secondary` | `#0B0D18` | Persistent side navigation & top bar |
| `--bg-surface` | `#111426` | Standard content panels & dashboard cards |
| `--bg-elevated` | `#171A2D` | Active selection, modals, dropdowns |
| `--bg-glass` | `rgba(17, 20, 38, 0.72)` | Translucent spatial cards with backdrop blur |
| `--bg-glass-hover` | `rgba(28, 32, 54, 0.85)` | Elevated hover state |

### Dual Accents & Illumination
| Token Name | Hex / RGBA | Role / Semantics |
| :--- | :--- | :--- |
| `--accent-violet` | `#8B5CF6` | Primary AI Core & Companion Identity |
| `--accent-violet-light`| `#A78BFA` | Violet glow, active highlights |
| `--accent-cyan` | `#22D3EE` | Telemetry, Future Engine, Trajectory lines |
| `--accent-ice` | `#60A5FA` | Secondary tech metadata, neutral intelligence |

### Telemetry & Status
| Token Name | Hex | Role |
| :--- | :--- | :--- |
| `--status-success` | `#34D399` | Positive momentum, completed actions, safe future |
| `--status-warning` | `#FBBF24` | Upcoming risks, confirmation required |
| `--status-critical` | `#FB7185` | Urgent interventions, high-risk trajectories, errors |
| `--status-neutral` | `#94A3B8` | System timestamps, secondary metadata |

### Hairline Borders & Neon Glow
| Token Name | Value | Role |
| :--- | :--- | :--- |
| `--border-subtle` | `rgba(255, 255, 255, 0.08)` | Baseline card boundary |
| `--border-violet` | `rgba(139, 92, 246, 0.35)` | Violet interactive element border |
| `--border-cyan` | `rgba(34, 211, 238, 0.35)` | Future engine / telemetry border |
| `--glow-violet` | `0 0 24px rgba(139, 92, 246, 0.25)` | AI presence luminescence |
| `--glow-cyan` | `0 0 24px rgba(34, 211, 238, 0.25)` | Future prediction luminescence |

---

## 3. Typography & Hierarchy

- **Primary Interface Font:** `'Inter', -apple-system, BlinkMacSystemFont, sans-serif`
- **Telemetry & Technical Font:** `'JetBrains Mono', 'Fira Code', monospace`

### Scale
- **Display 1 (Command Greeting):** `1.75rem` (28px), Bold, `-0.02em` letter spacing
- **Section Heading:** `1.125rem` (18px), Semi-bold, `0.02em` uppercase tracking for category headers
- **Body Core:** `0.875rem` (14px), Regular/Medium, `1.5` line height
- **Telemetry / Badges:** `0.75rem` (12px), Monospace or Bold Uppercase `0.06em` letter spacing
- **Micro Metadata:** `0.6875rem` (11px), Monospace muted

---

## 4. Animation & Interaction Model

Target 60 FPS transitions using CSS GPU transforms (`transform: translate3d`, `opacity`, `filter`).

1. **Orb Breathing (`orbBreathing`):**
   - 4-second sinusoidal scale (0.98 to 1.04) and glow expansion.
2. **Orbital Energy Rings (`orbitalSpin`):**
   - Outer elliptical ring revolving at 12s, counter-rotating inner ring at 8s.
3. **Ambient Particle Drift (`particleDrift`):**
   - Soft background aura shifting subtly behind hero cards.
4. **Neon Scanner Line (`scanline`):**
   - Telemetry loading indicator across charts and future predictions.
5. **Interactive Elevation:**
   - Cards smoothly lift (`translateY(-2px)`) with heightened neon border on hover.


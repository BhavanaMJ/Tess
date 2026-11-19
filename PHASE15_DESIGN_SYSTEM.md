# TESS Design System Specification v1.0 (Phase 15)

## 1. Executive Summary

This document specifies the production design system for the **TESS Mobile & Web Companion Application**, implemented in Flutter during **Phase 15: Flutter Mobile Visual Redesign & Expressive Companion Integration**.

The design system embodies the approved brand identity:
> **"See Where Today Takes You."**

It balances an ultra-clean, modern companion aesthetic with the technical depth of an autonomous intelligence system. The default interface is an inviting **Light Theme** built on crisp surfaces with fresh mint and teal accents, complemented by an immersive, low-glare **Dark Theme**.

---

## 2. Color Palette & Semantic Tokens (`app_colors.dart`)

All colors are exposed as static constants and semantic helpers in `lib/core/theme/app_colors.dart`.

### 2.1 Brand Identity Colors
| Token Name | Hex Code | Color Role & Usage |
|:---|:---|:---|
| `AppColors.vibrantMint` | `#35B9A5` | Primary brand accent; active focus highlights, vibrant buttons, key interactive states. |
| `AppColors.tessTeal` | `#168F83` | Primary action teal; AppBar titles, interactive buttons, focused borders, link text. |
| `AppColors.deepTeal` | `#08776E` | Deep tertiary teal; active container backgrounds, dark contrast accents. |
| `AppColors.mintHighlight` | `#BDF2E4` | Luminescent mint tint; container accents, soft badge backgrounds. |
| `AppColors.luminescentFace`| `#F4FFFB` | Companion mascot luminescent face fill, pure light dark-mode foreground. |
| `AppColors.deepEyes` | `#174C48` | Companion mascot eye color and deep iconography contrast. |

### 2.2 Neutral Palette — Light Theme (Default)
| Token Name | Hex Code | Purpose |
|:---|:---|:---|
| `AppColors.lightBg` | `#F8FAF9` | Scaffold background; soft, non-fatiguing cool light gray-green. |
| `AppColors.lightSurface` | `#FFFFFF` | Primary card and dialog surface; pure white with soft elevation. |
| `AppColors.lightSurfaceSubtle` | `#F0F4F2` | Subtle nested containers, inactive chips, form field backgrounds. |
| `AppColors.lightSecondary` | `#E8F0ED` | Input text fill and disabled card container background. |
| `AppColors.lightBorder` | `#E2EAE7` | Card borders, dividers, subtle outline strokes. |
| `AppColors.lightBorderSubtle` | `#EAF0EE` | Secondary dividers and non-critical card borders. |
| `AppColors.lightTextPrimary` | `#111817` | High-contrast body and title typography (contrast ratio > 12:1). |
| `AppColors.lightTextSecondary` | `#4F615E` | Subtitles, supporting copy, labels (contrast ratio > 4.5:1). |
| `AppColors.lightTextMuted` | `#7D938F` | Placeholder hints, timestamps, tertiary telemetry captions. |

### 2.3 Neutral Palette — Dark Theme
| Token Name | Hex Code | Purpose |
|:---|:---|:---|
| `AppColors.darkBg` | `#0B100F` | Scaffold background; deep obsidian teal, avoids harsh pure black (#000000). |
| `AppColors.darkSurface` | `#131A19` | Primary card and modal background; elevated obsidian teal. |
| `AppColors.darkSurfaceElevated` | `#1A2422` | Raised dialogs, dropdowns, and elevated action sheets. |
| `AppColors.darkSurfaceSubtle` | `#101716` | Recessed input containers, nested status panels. |
| `AppColors.darkBorder` | `#22302D` | High-definition card outlines, structural dividers. |
| `AppColors.darkBorderSubtle` | `#1A2422` | Secondary dividers and background outlines. |
| `AppColors.darkTextPrimary` | `#F4FFFB` | High-contrast luminescent body and heading copy. |
| `AppColors.darkTextSecondary` | `#A2B7B3` | Secondary labels, descriptions, and metadata. |
| `AppColors.darkTextMuted` | `#637874` | De-emphasized hints, inactive timestamps, muted telemetry. |

### 2.4 Semantic & Feedback Colors
| Semantic Role | Token | Light Theme Hex | Dark Theme Hex | Meaning |
|:---|:---|:---|:---|:---|
| **Success** | `AppColors.success` | `#10B981` | `#34D399` | Goal achieved, approved step, completed task. |
| **Warning** | `AppColors.warning` | `#F59E0B` | `#FBBF24` | Convergence risk detected, timeline drift. |
| **Danger / Risk** | `AppColors.danger` | `#EF4444` | `#F87171` | Critical deadline violation, network failure. |
| **Info / Sensor** | `AppColors.info` | `#06B6D4` | `#22D3EE` | Telemetry link, device status, neutral forecast. |

---

## 3. Typography Scale (`app_typography.dart`)

Typography is configured to use **Inter** for all UI surfaces, headings, and labels, while retaining **JetBrains Mono** for telemetry parameters, hexadecimal fingerprints, code steps, and raw execution logs.

```
Display Large:    28.0 pt | w800 | -0.5 tracking | Headers & hero titles
Title Large:      20.0 pt | w700 | -0.4 tracking | Modal & section headers
Title Medium:     16.0 pt | w600 | -0.2 tracking | Card titles, list headers
Title Small:      14.0 pt | w600 |  0.0 tracking | Tab labels & badge text
Body Large:       15.0 pt | w400 |  0.0 tracking | Message bubbles & narratives
Body Medium:      13.5 pt | w400 |  0.0 tracking | General UI body text
Body Small:       12.0 pt | w400 | +0.1 tracking | Metadata & secondary text
Label Large:      13.0 pt | w600 | +0.2 tracking | Primary button labels
Label Medium:     11.0 pt | w600 | +0.5 tracking | Category pills & chips
Label Small:      10.0 pt | w700 | +0.8 tracking | Telemetry badges & uppercase pills
Code / Monospace: 12.0 pt | w500 |  0.0 tracking | Fingerprints, tokens, code snippets
```

---

## 4. Spacing & Layout Grid (`app_spacing.dart`)

Built upon a strict **4px/8px incremental grid**:

```dart
static const double xs  = 4.0;   // Inset padding, icon-text spacing
static const double sm  = 8.0;   // Compact padding, chip gaps
static const double md  = 16.0;  // Standard screen & card padding
static const double lg  = 24.0;  // Section gaps, card separation
static const double xl  = 32.0;  // Major section headers
static const double xxl = 48.0;  // Hero empty states, top spacing
```

---

## 5. Shape, Radii & Elevations (`app_radius.dart`, `app_shadows.dart`)

Consistent organic rounding conveys friendliness while preserving structural discipline:

```dart
// Radii
static const BorderRadius xs     = BorderRadius.all(Radius.circular(4.0));
static const BorderRadius sm     = BorderRadius.all(Radius.circular(8.0));
static const BorderRadius md     = BorderRadius.all(Radius.circular(12.0));
static const BorderRadius lg     = BorderRadius.all(Radius.circular(16.0));
static const BorderRadius xl     = BorderRadius.all(Radius.circular(20.0));
static const BorderRadius xxl    = BorderRadius.all(Radius.circular(28.0));
static const BorderRadius pill   = BorderRadius.all(Radius.circular(999.0));
static const BorderRadius card   = BorderRadius.all(Radius.circular(16.0));
static const BorderRadius button = BorderRadius.all(Radius.circular(12.0));

// Shadows (Subtle, diffused ambient light)
AppShadows.cardLight  // Blur 12px, Offset (0, 3), #000000 with 0.04 alpha
AppShadows.cardDark   // Blur 16px, Offset (0, 4), #000000 with 0.35 alpha
AppShadows.dialog     // Blur 32px, Offset (0, 8), #000000 with 0.12 alpha
AppShadows.glowMint   // Blur 12px, Offset (0, 2), #35B9A5 with 0.25 alpha
```

---

## 6. Shared Component Library

### 6.1 `TessCard` (`lib/shared/widgets/tess_card.dart`)
- Adaptive background (`lightSurface` / `darkSurface`)
- Crisp 1px border (`lightBorder` / `darkBorder`)
- Standard 16px card radius with subtle ambient shadow
- Optional `elevated: true` property for hero cards

### 6.2 `TessButton` (`lib/shared/widgets/tess_button.dart`)
- **Primary**: Mint/Teal gradient fill (`#35B9A5` → `#168F83`) with white text.
- **Secondary**: Outlined teal border with transparent surface.
- **Danger**: Red outline/surface for destructive operations (delete memory, cancel plan).
- Built-in loading spinner (`isLoading: true`) with disabled tap interaction.

### 6.3 `TessBadge` (`lib/shared/widgets/tess_badge.dart`)
- Compact status indicator (Success, Warning, Danger, Info, Neutral).
- Automatic opacity-backed fill (12% alpha) and solid text foreground.

### 6.4 `ResponsiveMetricCard` (`lib/shared/widgets/responsive_metric_card.dart`)
- Dual-metric and KPI presentation card with status accent strips.
- Clean number presentation with accompanying trend iconography.


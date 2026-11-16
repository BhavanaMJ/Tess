# TESS Phase 12 — Desktop and Mobile Continuity Guide

**Date:** November 16, 2026  
**Subsystems:** Linux Desktop (Tauri/Vite) & Android Mobile (Expo/React Native)  
**Status:** ARCHITECTURE UNIFIED & VERIFIED

---

## 1. Single Identity & Shared Backend Architecture

Both Desktop and Mobile clients communicate with the same FastAPI backend (`http://<host>:8000`) and the same Supabase PostgreSQL database:

```
+------------------------------------+       +------------------------------------+
|        TESS Desktop Client         |       |        TESS Android Mobile         |
|        (Tauri v2 + React 18)       |       |        (Expo SDK 52 + RN)          |
+-----------------+------------------+       +-----------------+------------------+
                  |                                            |
                  | Bearer JWT                                 | Bearer JWT
                  v                                            v
+---------------------------------------------------------------------------------+
|                         FastAPI Backend (/api/v1/*)                             |
|        Endpoints: Conversations, Memories, Productivity, Future, Companion      |
+---------------------------------------+-----------------------------------------+
                                        |
                                        v
+---------------------------------------------------------------------------------+
|                        Supabase PostgreSQL (Single DB)                          |
|         Row-Level Security (auth.uid() = user_id) across all 14 tables          |
+---------------------------------------------------------------------------------+
```

---

## 2. Continuity Verification Matrix

| Data Domain | Synchronization Mechanism | Continuity Behavior |
| :--- | :--- | :--- |
| **Conversations & Messages** | `/api/v1/conversations` | Starting a chat on desktop allows resuming the conversation on mobile. Messages persist in `messages` table. |
| **Episodic & Semantic Memories** | `/api/v1/memories` | Memories captured during desktop productivity tasks are immediately available to the mobile assistant. |
| **Living Companion Preferences** | `/api/v1/companion/preferences` | Personality style (`ANALYTICAL`, `CALM`, `PLAYFUL`, `EMPATHIC`), response verbosity, and tone adapt synchronously across devices. |
| **Mascot Personalization** | `MascotContext.tsx` & `Mascot.tsx` | The visual digital pet matches mood, current routine state, and animation frames on both platforms. |
| **Companion Routines** | `/api/v1/companion/routines` | Daily routines (e.g. Morning Briefing at 08:30) trigger on whichever device is active. |
| **Milestones & Achievements** | `/api/v1/companion/milestones` | Streaks and productivity milestones are credited to the user's shared profile. |
| **Proactive Interventions** | `/api/v1/proactive/interventions` | Responding to an intervention (`CONFIRM` or `DISMISS`) updates the status for both desktop and mobile clients. |
| **Session Renewal** | Supabase `autoRefreshToken` | Automatic token refresh prevents session disconnects during normal daily usage. |

---

## 3. Duplicate Notification Prevention

To prevent duplicate alerts when both desktop and phone are active on the same desk:
1. **Desktop Client Deduplication:** [desktop/src/services/notifications.ts](file:///home/bhavanamj/Desktop/Tess/desktop/src/services/notifications.ts) caches recent notification keys (`${title}:${body}`) for 60 seconds.
2. **Backend Intervention Status:** Once an intervention is generated, its status in `proactive_interventions` is tracked. When the user responds on one device, subsequent polling or checks see status `RESPONDED` and omit redundant popups.


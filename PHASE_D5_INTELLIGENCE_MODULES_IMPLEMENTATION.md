# TESS DESKTOP REDESIGN — PHASE D5 IMPLEMENTATION SPECIFICATION
## INTELLIGENCE MODULES: AGENT ACTIVITY, MEMORY CORE & SYSTEM SETTINGS

**Status**: 100% Complete (D5.1, D5.2, D5.3 Fully Verified & Committed)  
**Author**: Antigravity  
**Target Platform**: Desktop (Tauri 2 + React + TypeScript + Vite)  
**Backend**: FastAPI + Supabase + Ollama  
**Test Suite**: 108/108 Tests Passing (11 Test Suites)  

---

## 1. Executive Summary & D5 Scope

Phase D5 focuses on transforming TESS's three **Intelligence Modules** into premium, transparent, interactive, and reliable workspaces:
1. **D5.1 — Agent Activity**: Autonomous agent execution plans, tool invocation timeline, risk safeguards, and human-in-the-loop confirmation.
2. **D5.2 — Memory Core**: Contextual knowledge retrieval, personal preference encoding, importance levels, provenance attribution, and memory management.
3. **D5.3 — System Settings**: Living companion evolution controls, personality presets, routine automation schedules, connected devices, and desktop notifications.

Per strict user directives:
- **Phase D5.1 (Agent Activity) is implemented and validated first.**
- **No changes to Memory Core or System Settings** occur until D5.1 is tested, committed, documented, and approved.
- **Zero duplicate mascots**: The single persistent floating companion window established in D3-fix is preserved.
- **Real backend data only**: No mock or hallucinated plans. Existing FastAPI agent endpoints and schemas are strictly respected.

---

## 2. Comprehensive D5 Architecture Audit

### 2.1 Agent Activity Module Audit
- **Current State (`desktop/src/screens/AgentActivityScreen.tsx`)**:
  - Contains basic two-column layout: an objective creation form with simple plan cards on the left, and a detail view with steps on the right.
  - Lacks aggregate metrics (Active, Awaiting Approval, Executing, Completed, Failed).
  - Missing status filters, search capability, and detailed tool output inspection.
  - Does not provide structured error messages or objective suggestions based on backend capabilities.
- **Backend Service & API (`backend/app/api/agent.py`, `backend/app/services/agent/`)**:
  - `GET /api/v1/agent/plans`: Fetches user's agent plans with steps and confirmation states.
  - `POST /api/v1/agent/objectives`: Formulates autonomous plan from user objective string via `AgentPlanner.plan(objective)`. Supported domains:
    1. *Worklog / OpenProject*: Keywords `worklog`, `openproject`, `fix`, `log time`. Tool: `openproject_update_worklog`.
    2. *Calendar & Briefing*: Keywords `meeting`, `prepare me for`, `briefing`, `schedule`. Tools: `calendar_list_events`, `calendar_create_event`, `gmail_read`, `gmail_create_draft`.
    3. *Email Notification*: Keywords `send email`, `email to`, `send message`. Tool: `gmail_send_email`.
    4. *Web Navigation & Research*: Keywords `browse`, `open url`, `website`, `check github`, `search web`. Tools: `browser_navigate`, `browser_extract`, `browser_fill_form`.
    5. *File Intelligence*: Keywords `file`, `document`, `pdf`, `docx`, `read report`. Tools: `file_read`, `file_search`, `file_modify`.
  - `POST /api/v1/agent/plans/{plan_id}/confirm`: Confirms pending medium/high risk steps.
  - `POST /api/v1/agent/plans/{plan_id}/cancel`: Safely cancels ready or pending plans.
  - `POST /api/v1/agent/plans/{plan_id}/execute`: Sequentially runs plan steps with tool execution and persists events.
- **Desktop API Client (`desktop/src/services/api.ts`)**:
  - Implements `getAgentPlans()`, `getAgentPlan(id)`, `createAgentObjective(objective)`, `confirmAgentPlan(id)`, `cancelAgentPlan(id)`, `executeAgentPlan(id)`.

### 2.2 Memory Core Module Audit (For D5.2 Reference)
- **Current State (`desktop/src/screens/MemoryScreen.tsx`)**:
  - Basic list with inline editing, categories (preference, goal, project, workflow, commitment, routine, fact), and importance rating (1-5).
  - Needs structured categorization tabs, search/filter controls, memory health metrics, provenance indicators, and confirmation badges.
- **Backend Endpoints (`backend/app/api/endpoints.py`, `backend/app/services/companion/memory_continuity.py`)**:
  - `GET /api/v1/memories`: Returns array of memory entries.
  - `POST /api/v1/memories`: Inserts new structured memory.
  - `PUT /api/v1/memories/{id}`: Modifies content or confirmation status.
  - `DELETE /api/v1/memories/{id}`: Deletes memory.

### 2.3 System Settings Module Audit (For D5.3 Reference)
- **Current State (`desktop/src/screens/SettingsScreen.tsx`)**:
  - Large monolithic screen managing companion evolution stage, personality presets, routine creator, notification toggles, and connected devices.
  - Needs clean tabbed navigation (Companion & Demeanor, Routines & Automation, Notifications, Devices & Session, System Info) for seamless desktop management.

---

## 3. Detailed Component Plan for Phase D5.1 (Agent Activity)

To transform Agent Activity into an intuitive, high-transparency command console, the screen is decomposed into focused modular components under `desktop/src/components/agent/`:

```
desktop/src/components/agent/
├── AgentMetricsOverview.tsx   # Top KPI metrics (Total Plans, Awaiting Approval, Executing, Completed, Failed)
├── AgentFilterBar.tsx          # Status filter pills (All, Ready, Running, Success, Failed, Cancelled) & Search input
├── AgentPlanCard.tsx           # Rich plan card with status badge, step count, risk indicator, tool pills, timestamp
├── AgentPlanDetailModal.tsx    # Modal/Inspector showing step-by-step timeline, parameters, confirmation status, output
└── AgentObjectiveForm.tsx      # Autonomous objective creator with domain starters & formulation helper
```

### 3.1 Interaction Architecture
1. **Quick Objective Formulations**: Built-in template starters ("Log time: 2 hours on task #101", "Prepare briefing for tomorrow", "Browse https://github.com") to guide users on backend-supported capabilities.
2. **Interactive Plan Selection & Inspection**:
   - Left rail displays filtered plan list with active selection indicator.
   - Main workspace or detail modal allows inspecting every step: tool name, action type, parameters, risk level badge (`LOW`, `MEDIUM`, `HIGH`), and confirmation state.
3. **Human-in-the-Loop Safeguards**:
   - `READY` plans with pending confirmations show prominent "Confirm Action" trigger.
   - Confirmed plans show "Execute Plan" with real-time spinner and step progression.
   - Cancel safeguards allow aborting unexecuted plans.
4. **Mascot Emotional Synchrony**:
   - `PLANNING` while generating objective plan.
   - `CONFIRMING` when plan requires human confirmation.
   - `ACTING` during tool execution.
   - `SUCCESS` when execution completes without error.
   - `ERROR` when execution fails or backend returns an error.
   - `IDLE` / default during calm inspection.
   - Preserves single persistent floating window without duplicate `<Mascot>` elements.

---

## 4. Verification & Testing Strategy

- **Automated Tests (`desktop/src/test/agent_d5.test.tsx`)**:
  - Plans listing and metric calculations.
  - Status filtering and search functionality.
  - Objective formulation and plan submission.
  - Action confirmation (`confirmAgentPlan`) and cancellation (`cancelAgentPlan`).
  - Execution progression (`executeAgentPlan`) and state changes.
  - Error banner display upon network or execution failure.
  - Inspection modal opening and closing.
- **Verification Gates**:
  - All existing 83 tests pass (`npm test`).
  - New D5.1 agent tests pass.
  - Production build succeeds with 0 TypeScript/Vite errors (`npm run build`).
  - Backend validation against live FastAPI server.


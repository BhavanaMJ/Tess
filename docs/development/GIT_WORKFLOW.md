# TESS — Professional Git Branching & Workflow Governance

## 1. Executive Summary

This document establishes the official Git branching strategy, environment management, and release process for **TESS (Personal AI Operating System)**.

This repository (`BhavanaMJ/Tess`) contains:
- **Flutter Mobile Application** (`flutter_app/`) — Personal AI operating system client, Wardrobe Intelligence, Smart Capture.
- **FastAPI Python Backend** (`backend/`) — Agent engines, Future simulator, Proactive companion, Wardrobe service, and SQLite local persistence.
- **Desktop Application** (`desktop/`) — Tauri v2 + React 18 companion interface with floating mascot.
- **Legacy React Native Client** (`mobile/`) — Retained Phase 0-12 foundation.

---

## 2. Phase 1 — Comprehensive Repository Audit

### 2.1 Branch & Remote Audit (2026-11-25)

| Metric | Status / Value | Description |
|---|---|---|
| **Active Local Branch** | `clothes-organizer` | Checked out, working tree clean. |
| **Current HEAD Commit** | `53106f1fd5d669e109c8f7b918f6a40fb94a8bd0` | `feat(wardrobe): implement persistent SQLite local database for wardrobe storage` |
| **Local Branches** | `clothes-organizer` (`53106f1`), `main` (`53106f1`) | Both point to the latest verified commit. |
| **Remote Origin URL** | `git@github.com:BhavanaMJ/Tess.git` | Authenticated SSH protocol (`fetch` and `push`). |
| **Remote Branches** | `origin/clothes-organizer` (`53106f1`), `origin/main` (`cf60602`) | Remote tracking active. |
| **Merge Base** | `cf60602c4f80a4045d67945ac374a17464d98da1` | Initial repository commit. |
| **Commit Delta** | Local `main` / `clothes-organizer` are **39 commits ahead** of `origin/main` | 598 files changed, 104,127 insertions(+), 3,455 deletions(-). |
| **Working Tree** | Clean | No uncommitted or untracked changes. |
| **Git Tags** | None | No tags or releases created yet. |
| **CI/CD Workflows** | None | `.github/workflows/` currently empty. |
| **Existing PRs** | None open | PR URL available: `https://github.com/BhavanaMJ/Tess/pull/new/clothes-organizer` |

### 2.2 Commit Range Analysis

The 39 commits between `origin/main` (`cf60602`) and `53106f1` encompass the following completed phases:
1. **Phases 13–14 Mobile & Backend** (`22b6abe` – `1784863`): Flutter foundation, Supabase auth, dashboard, companion chat, future engine, proactive intelligence, agent actions, and voice synthesis.
2. **Android & Desktop Polish** (`bcdce04` – `7054f7b`): Gradle 9.5 compatibility, Android compileSdk 36, theme tokens, Desktop workspaces D2 through D6.
3. **Clothes Organizer & Wardrobe Intelligence** (`19eb7c0` – `53106f1`):
   - Phase 3.1 & 3.2 Smart Capture foundation
   - Laundry manager & batch tracking
   - Phase 5 Outfit Studio & AI stylist
   - Phase 6 Outfit Calendar & weather context
   - Phase 7 Wardrobe Insights & analytics
   - Phase 8 Wishlist & shopping intelligence
   - Phase 3.4 ChatGPT-assisted garment catalogue and Schema 1.1 metadata import
   - Category normalization & alias mapping
   - Production SQLite local database (`backend/app/core/local_db.py`) with ACID persistence

### 2.3 Environmental & Security Audit
- **Credentials & Secrets**: `.env` files exist locally across root, `backend/`, `desktop/`, and `mobile/`. No live secrets or API keys are committed in Git history.
- **Databases**: SQLite local database `backend/app/data/wardrobe.sqlite3` is ignored via `.gitignore` (`*.sqlite3*`).
- **Tests**:
  - Flutter test suite: 230/230 tests passing.
  - Backend pytest suite: 23/23 wardrobe and import tests passing.

---

## 3. Branching Strategy & Architecture

We adopt a 3-tier branch model: **Production (`main`)**, **Staging (`staging`)**, and **Development (`develop`)**, supported by ephemeral feature, bugfix, and hotfix branches.

```
[ hotfix/* ] ──────> ( main ) [Release Tag: vX.Y.Z] (Production)
                        ▲
                        │ PR (Tested Release Candidate)
                        │
                   ( staging ) (Pre-Production / Acceptance)
                        ▲
                        │ PR (Integration Candidate)
                        │
[ feature/* ] ─────> ( develop ) (Active Development Integration)
[ bugfix/*  ] ─────>    ▲
```

### 3.1 Branch Definitions & Governance

#### 1. `main` — Production Release
- **Purpose**: Stable, production-ready code running in production environments.
- **Allowed Merges**: Only through Pull Requests from `staging` (for regular releases) or `hotfix/*` (for emergency fixes).
- **Rules**:
  - Never commit directly to `main`.
  - Never force-push (`git push --force` is prohibited).
  - Every merge to `main` must be tagged with a Semantic Version (`vMAJOR.MINOR.PATCH`).
  - Mandatory CI status checks passing (Flutter, Backend, Desktop).

#### 2. `staging` — Pre-Production / Release Candidate
- **Purpose**: Release candidate testing, integration verification, migration dry-runs, and user acceptance testing (UAT).
- **Allowed Merges**: Only through Pull Requests from `develop`.
- **Rules**:
  - Mirrors production configuration with staging credentials.
  - Full automated regression test suites executed.
  - Verified before promoting to `main`.

#### 3. `develop` — Development Integration
- **Purpose**: Primary integration branch for active development.
- **Allowed Merges**: Pull Requests from `feature/*` and `bugfix/*`.
- **Rules**:
  - Keep reasonably stable; all merged PRs must pass unit and integration tests.
  - Base branch for creating all new `feature/*` and `bugfix/*` branches.

#### 4. `feature/<name>` — New Features
- **Naming**: `feature/<short-description>` (e.g., `feature/wardrobe-search`, `feature/calendar-recurrence`).
- **Source**: `develop`
- **Target**: `develop` via PR.

#### 5. `bugfix/<name>` — Non-Emergency Bug Fixes
- **Naming**: `bugfix/<short-description>` (e.g., `bugfix/category-validation`, `bugfix/garment-image-cache`).
- **Source**: `develop`
- **Target**: `develop` via PR.

#### 6. `hotfix/<name>` — Critical Production Hotfixes
- **Naming**: `hotfix/<short-description>` (e.g., `hotfix/auth-token-crash`, `hotfix/data-corruption`).
- **Source**: `main`
- **Target**: `main` via PR.
- **Rule**: Upon merging to `main`, the hotfix **must immediately be merged into `staging` and `develop`** to prevent regressions.

---

## 4. Handling the Existing `clothes-organizer` Branch

- The `clothes-organizer` branch currently contains the full working state of TESS up to commit `53106f1`.
- It is backed up locally and remotely on `origin/clothes-organizer`.
- **Preservation Policy**:
  - `clothes-organizer` will **not** be deleted or rewritten.
  - When `develop` is established as the active integration branch, a Pull Request (`feat(wardrobe): integrate TESS Clothes Organizer`) will be prepared targeting `develop`.
  - Merging will occur only after explicit user approval.

---

## 5. Standard Developer Workflow

### 5.1 Starting a New Feature
```bash
# 1. Update develop
git checkout develop
git pull origin develop

# 2. Branch out
git checkout -b feature/your-feature-name

# 3. Work, test, and commit
flutter test
cd backend && pytest && cd ..
git commit -m "feat(module): descriptive message"

# 4. Push and open PR
git push -u origin feature/your-feature-name
```

### 5.2 Emergency Hotfix Workflow
```bash
# 1. Branch from main
git checkout main
git pull origin main
git checkout -b hotfix/critical-issue-name

# 2. Fix and test
git commit -m "fix(security): resolve production issue"

# 3. Push and PR into main
git push -u origin hotfix/critical-issue-name

# 4. Sync fix to staging and develop after merge
git checkout develop && git pull origin develop
git merge main
git push origin develop
```

---

## 6. Versioning & Release Policy

We follow [Semantic Versioning 2.0.0](https://semver.org/):
`v<MAJOR>.<MINOR>.<PATCH>`

- **Initial Base**: `v0.1.0` (Development release baseline).
- **Clothes Organizer Integration**: `v0.2.0` (Feature release).
- **Bugfixes**: `v0.2.1`, `v0.2.2`.
- **First General Production Release**: `v1.0.0` (Following formal UAT and cross-platform verification).

---

## 7. Next Execution Steps (Pending User Approval)

1. **Step 1**: Push local `main` (`53106f1`) to `origin/main` to establish the verified baseline on remote.
2. **Step 2**: Create `develop` branch from `main` and push to `origin/develop`.
3. **Step 3**: Create `staging` branch from `main` and push to `origin/staging`.
4. **Step 4**: Prepare Pull Request configuration and templates (`.github/pull_request_template.md`, issue templates).
5. **Step 5**: Create automated GitHub Actions CI/CD workflows for Flutter, Backend, and Desktop.
6. **Step 6**: Add developer documentation for branch naming, release process, and environment management.


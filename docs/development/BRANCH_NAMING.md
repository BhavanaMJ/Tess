# TESS Branch Naming & Management Standards

This document defines the strict branch naming standards for the TESS project across all repositories and submodules.

---

## 1. Permanent Core Branches

These branches are persistent and protected. They must never be deleted or force-pushed.

| Branch | Purpose | Base | Target for PRs | Direct Commits Allowed? |
|---|---|---|---|---|
| `main` | Production-ready, tagged releases | `staging` / `hotfix/*` | None | **NO** |
| `staging` | Release candidate validation & UAT | `develop` | `main` | **NO** |
| `develop` | Daily development integration | `feature/*` / `bugfix/*` | `staging` | **NO** |

---

## 2. Ephemeral Working Branches

All working branches are ephemeral and must be deleted after being merged to their target branch.

### 2.1 Feature Branches (`feature/*`)
Used for all new capabilities, enhancements, and UI additions.
- **Pattern**: `feature/<component-or-topic>-<short-description>`
- **Source**: `develop`
- **Target**: `develop`
- **Examples**:
  - `feature/wardrobe-search`
  - `feature/clothes-organizer-ai-import`
  - `feature/companion-custom-voice`
  - `feature/future-timeline-filters`

### 2.2 Bugfix Branches (`bugfix/*`)
Used for non-critical bugs, test repairs, and styling issues identified in development or staging.
- **Pattern**: `bugfix/<component-or-topic>-<short-description>`
- **Source**: `develop`
- **Target**: `develop`
- **Examples**:
  - `bugfix/category-validation`
  - `bugfix/garment-image-cache`
  - `bugfix/sqlite-transaction-lock`

### 2.3 Hotfix Branches (`hotfix/*`)
Reserved exclusively for urgent, critical issues in production requiring an immediate patch.
- **Pattern**: `hotfix/<critical-issue-name>`
- **Source**: `main`
- **Target**: `main`
- **Post-Merge Requirement**: Must be back-ported and merged immediately into `staging` and `develop`.
- **Examples**:
  - `hotfix/auth-token-crash`
  - `hotfix/wardrobe-data-loss`
  - `hotfix/production-api-500`

### 2.4 Chore & Documentation Branches (`chore/*`, `docs/*`)
Used for dependency bumps, CI configuration, refactoring, and documentation improvements.
- **Pattern**: `chore/<description>` or `docs/<description>`
- **Source**: `develop`
- **Target**: `develop`
- **Examples**:
  - `chore/upgrade-flutter-3-24`
  - `docs/api-documentation-phase3`

---

## 3. General Branch Rules

1. **Lowercase only**: Use lowercase letters, numbers, and hyphens (`-`).
2. **No special characters**: Do not use underscores (`_`), slashes except for the prefix category (`feature/`), or spaces.
3. **Concise descriptions**: Keep the description under 35 characters.
4. **No developer names**: Do not include personal names or initials in branch names (e.g. `john/feature` is prohibited).
5. **Delete merged branches**: Ephemeral branches should be pruned locally and remotely after PR acceptance.

# TESS Release Process & Versioning Guide

This document defines the formal release cycle, promotion path, semantic versioning scheme, and rollback procedures for TESS.

---

## 1. Versioning Scheme

TESS adheres to [Semantic Versioning (SemVer 2.0.0)](https://semver.org/):

`v<MAJOR>.<MINOR>.<PATCH>`

- **MAJOR**: Breaking changes, fundamental architectural rewrites, or non-backward-compatible API/schema overhauls.
- **MINOR**: Backward-compatible new features (e.g., Clothes Organizer, Outfit Studio, Voice Intelligence).
- **PATCH**: Backward-compatible bug fixes, UI styling corrections, or security patches.

### Initial Release Milestones
- `v0.1.0`: Core baseline platform (Phases 0–12 foundation).
- `v0.2.0`: Clothes Organizer and Wardrobe Intelligence feature integration.
- `v0.3.0`: Proactive companion & cross-device synchronization.
- `v1.0.0`: General Availability (GA) production release following multi-platform user acceptance testing.

---

## 2. Release Promotion Pipeline

```
[ develop ] ────(PR: Release Candidate)────> [ staging ] ────(PR: Approved Release)────> [ main ] ──(Tag: vX.Y.Z)
```

### Stage 1: Feature Freeze & Release Candidate Creation
1. Ensure all targeted features and bugfixes are merged into `develop` and CI is passing.
2. Cut a release branch from `develop` named `release/vX.Y.Z`:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b release/v0.2.0
   ```
3. Update version identifiers:
   - `flutter_app/pubspec.yaml` (e.g. `version: 0.2.0+2`)
   - `desktop/package.json` (e.g. `"version": "0.2.0"`)
4. Open a Pull Request from `release/v0.2.0` into `staging`.

### Stage 2: Staging Deployment & Acceptance Testing (UAT)
1. Merge `release/v0.2.0` into `staging`.
2. Staging environment triggers deployment.
3. Execute the full QA Verification Checklist:
   - [ ] Backend healthcheck: `curl http://staging.tess.internal:8000/health`
   - [ ] Database migration check: All migrations applied cleanly without errors.
   - [ ] Cross-module smoke testing:
     - Authentication & login session persistence
     - Clothes Organizer: Garment addition, Smart Capture, Schema 1.1 import, SQLite retention
     - Laundry Manager, Outfit Studio, Outfit Calendar
     - Companion chat & mascot interaction
   - [ ] Verify no unhandled exceptions in backend or client logs.

### Stage 3: Production Promotion & Tagging
1. Once staging testing is signed off, open a PR from `staging` into `main`.
2. Merge the PR using a **Merge Commit**.
3. Create and push a signed/annotated Git tag:
   ```bash
   git checkout main
   git pull origin main
   git tag -a v0.2.0 -m "Release v0.2.0: Clothes Organizer & Wardrobe Intelligence"
   git push origin v0.2.0
   ```
4. Back-merge the tagged release state back into `develop` so that version bumps and any release adjustments are synchronized:
   ```bash
   git checkout develop
   git pull origin develop
   git merge main
   git push origin develop
   ```

---

## 3. Emergency Hotfix Procedure

When a critical defect is identified in production:

1. **Create hotfix branch from `main`**:
   ```bash
   git checkout main
   git pull origin main
   git checkout -b hotfix/v0.2.1-fix-login-token
   ```
2. **Implement fix & add regression test**:
   Verify fix passes tests locally.
3. **Open PR to `main`**:
   Tag reviewer for emergency approval.
4. **Merge and Tag**:
   ```bash
   git checkout main
   git pull origin main
   git tag -a v0.2.1 -m "Hotfix v0.2.1: Fix production token expiry"
   git push origin v0.2.1
   ```
5. **Mandatory Back-Propagation**:
   The hotfix **must** immediately be merged into `staging` and `develop`:
   ```bash
   git checkout staging && git pull origin staging && git merge main && git push origin staging
   git checkout develop && git pull origin develop && git merge main && git push origin develop
   ```

---

## 4. Rollback Strategy

1. **Production Rollback**:
   If a production deployment fails, redeploy the previous release tag (e.g., `v0.1.0`).
2. **Database Migration Safety**:
   Before deploying new database migrations to production, execute `scripts/backup_db.sh`.
   If a rollback is required, use `scripts/restore_db.sh` to restore pre-deployment database state.

# TESS Pull Request Guide & Standards

This document establishes the guidelines, quality gates, and review standards for submitting Pull Requests in TESS.

---

## 1. PR Title Standard

All Pull Request titles must follow the **Conventional Commits** specification:

`<type>(<scope>): <concise description>`

### Allowed Types:
- `feat`: A new feature or capability.
- `fix`: A bug fix.
- `refactor`: Internal code restructuring without behavioral change.
- `docs`: Documentation only.
- `test`: Adding or correcting tests.
- `chore`: Build, CI, tool, or dependency updates.

### Examples:
- `feat(wardrobe): integrate TESS Clothes Organizer`
- `fix(wardrobe): resolve Schema 1.1 category alias mapping`
- `feat(companion): add proactive notification scheduler`
- `test(backend): add SQLite persistence regression tests`

---

## 2. PR Target Branch Matrix

| Type of Work | Target Branch | Notes |
|---|---|---|
| New Feature | `develop` | Branch must stem from latest `develop`. |
| Bug Fix | `develop` | Branch must stem from latest `develop`. |
| Release Candidate | `staging` | Stemmed from `develop` when feature set is frozen. |
| Production Release | `main` | Stemmed from `staging` after UAT and sign-off. |
| Emergency Hotfix | `main` | Stemmed directly from `main`. |

---

## 3. Mandatory Quality Checklist

Before requesting review or merging:

### 3.1 Code Quality & Static Analysis
- [ ] Flutter: `flutter analyze --no-fatal-infos` passes cleanly.
- [ ] Backend: `flake8 app --count --select=E9,F63,F7,F82 --show-source` passes with 0 syntax or undefined errors.
- [ ] Desktop: `tsc --noEmit` passes with 0 TypeScript errors.

### 3.2 Automated Tests
- [ ] Flutter tests pass (`cd flutter_app && flutter test`).
- [ ] Backend tests pass (`cd backend && pytest tests/`).
- [ ] Desktop tests pass (`cd desktop && npm test`).

### 3.3 Data Integrity & Security
- [ ] Database migrations are numbered sequentially in `backend/migrations/` and have been verified.
- [ ] No hardcoded secrets, API keys, or tokens exist in commits or configuration files.
- [ ] Local SQLite files (`*.sqlite3*`) and environment overrides (`.env`) are excluded by `.gitignore`.

---

## 4. Review & Merge Policy

1. **Review Required**: Every PR must be reviewed and approved.
2. **CI Passing**: All automated GitHub Actions status checks (`Flutter CI`, `Backend CI`, `Desktop CI`) must be green.
3. **Merge Strategy**:
   - `develop` and `staging`: **Squash and Merge** or **Rebase and Merge** for clean commit history.
   - `main`: **Merge Commit** to preserve the release milestone and merge commit SHA for traceability.

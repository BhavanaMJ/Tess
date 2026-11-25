## Pull Request Description

### Summary
Brief description of the changes introduced in this PR.

### Related Issues
Fixes #(issue) or Closes #(issue)

### Type of Change
- [ ] `feat`: A new feature
- [ ] `fix`: A bug fix
- [ ] `refactor`: Code refactoring without behavioral changes
- [ ] `docs`: Documentation updates
- [ ] `test`: Added or updated tests
- [ ] `chore`: Tooling, CI, or dependency updates

---

## Target Branch & Verification Checklist

- [ ] Target branch matches branching policy (`develop` for features/bugfixes, `staging` for RC, `main` for hotfixes/releases)
- [ ] Flutter tests pass (`cd flutter_app && flutter test`)
- [ ] Flutter analyze passes (`cd flutter_app && flutter analyze`)
- [ ] Backend tests pass (`cd backend && pytest tests/`)
- [ ] Desktop tests pass (`cd desktop && npm test`)
- [ ] No database migration gaps or unversioned schema files
- [ ] No secrets, credentials, or local SQLite/env files included
- [ ] Self-review conducted

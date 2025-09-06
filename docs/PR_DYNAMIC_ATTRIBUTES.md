# PR: Dynamic Attributes - DAO/Repository + Test tooling + FeatureFlag

## Summary

This change set introduces the initial backend plumbing for the dynamic attributes feature and a small standalone test runner. It also makes the feature flag runtime-overridable so we can enable it in tests and staging without rebuilding.

What changed

- `lib/core/config/feature_flags.dart` — `useDynamicAttributes` is now runtime-overridable via env var `USE_DYNAMIC_ATTRIBUTES` and `FeatureFlags.setForTests()`.
- `lib/data/attributes/attribute_dao.dart` — DAO to ensure attributes, attribute_values, and to link variant_attributes.
- `lib/data/attributes/attribute_repository.dart` — small repository wrapper using the DAO.
- `tool/test_attribute_repository.dart` — standalone test runner (uses `sqflite_common_ffi`) to exercise DAO/Repository without Flutter.
- `docs/DYNAMIC_ATTRIBUTES_IMPLEMENTATION_PLAN.md` — updated to mark completed work, add notes and how-to-run instructions.

Why

- Allows incremental rollout and testing of the dynamic attributes model without changing production behavior.
- Provides small, testable components to be integrated into `ProductRepository`/`ProductDao` in a follow-up PR.

How to run locally

- Run the repository smoke test (in-memory DB):

```powershell
dart run tool/test_attribute_repository.dart
```

- Run discovery on a DB file:

```powershell
dart run tool/generate_discovery_report.dart --db=C:\absolute\path\to\clothes_pos.db
```

- Dry-run extraction:

```powershell
dart run tool/extract_and_dryrun_migrate.dart --db=C:\absolute\path\to\clothes_pos.db
```

- Apply planned inserts (requires explicit confirmation; will create backup):

```powershell
dart run tool/commit_planned_inserts.dart --apply --backup --db=C:\absolute\path\to\clothes_pos.db
```

Discovery / planning artifacts

- See `backups/migration_reports/` for generated CSVs (discovery, extracted_values, planned_inserts, commit_audit). Example files produced during local runs:
  - `backups/migration_reports/dynamic_attributes_discovery_20250828_162523.csv`
  - `backups/migration_reports/extracted_values_20250828_162402.csv`
  - `backups/migration_reports/planned_inserts_20250828_162402.csv`
  - `backups/migration_reports/commit_audit_2025-08-28T16-24-15.281866Z.csv`

Notes for reviewer

- This PR purposefully limits scope to backend helpers and runtime flag changes. Integration into product logic and UI is intentionally left for follow-up PRs to keep review size small.
- Tests: there is a standalone runner; I plan to add unit tests using `flutter_test` for integration with `ProductRepository` in the next PR.
- Safety: tools create DB backups before applying changes; discovery/extract are dry-run by default.

Suggested review checklist

- [ ] Verify `FeatureFlags` API is acceptable for test usage.
- [ ] Review DAO/Repository APIs for suitability with `ProductRepository`.
- [ ] Run `tool/test_attribute_repository.dart` locally and confirm successful output.

---

If you want, I can push this new branch and open the GitHub PR for you (requires remote access). Otherwise, you can push the branch `pr/dynamic-attributes-prepare` and open the PR with the above description.

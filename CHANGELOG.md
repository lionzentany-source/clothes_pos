# Changelog

All notable changes will be documented in this file.

## [1.0.2+4] - Unreleased

- (placeholder) Add upcoming changes here.

## [1.0.1+3] - 2025-09-06

- Add README badges and dynamic attributes documentation.
- Prepare CHANGELOG infrastructure.

## [1.0.0+2] - 2025-09-06

### Added

- Dynamic attributes migrations (022–025) and attribute picker UI.
- Barcode scanning migrated to `barcode_scan2`.
- Arabic Noto fonts embedded for PDF receipts.
- GitHub Actions: CI + Android release (tag-trigger) with auto release notes.
- Thermal printing flow (ESC/POS generator improvements, receipt enhancements).
- Tests: barcode services, PDF Arabic smoke, modal + safety guards.

### Changed

- Refactored POS cart handling with `CartCubit`.
- Improved session closing variance report + logging.
- Build scripts: removed temporary namespace hack.

### Fixed

- Android release build failures due to missing plugin namespace & R8 missing classes.
- Multiple UI safety issues (mounted context checks post-await).

### Removed

- Legacy `flutter_barcode_scanner` dependency.

--
Regenerate this file with a custom script or manual curation as needed.

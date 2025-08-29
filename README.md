# Clothes POS

iOS-style (Cupertino) Point-of-Sale app for clothing stores, built with Flutter. Local SQLite first, future-ready for online sync.

## Features (initial)

- Cupertino iOS UI with 4 tabs: POS, Inventory, Reports, Settings
- Local SQLite DB (sqflite): products/variants, sales/purchases, inventory movements, users/roles, cash sessions
- PDF printing for receipts/reports; charts with fl_chart
- Barcode scanning (camera); RFID/thermal printer to be selected later

## Run

- Flutter 3.22+ and Dart SDK 3.8+
- Platforms: Android, iOS, Windows, macOS, Linux (dev)

Install deps and run:

```
flutter pub get
flutter run
```

## Developer: clean DB (dynamic attributes)

For working with a fresh, canonical clean database (no legacy size/color columns) the repo uses `backups/clothes_pos_clean.db`.

Quick commands (run from repo root):

```powershell
dart run tool/create_clean_db.dart    # create backups/clothes_pos_clean.db
dart run tool/seed_clean_db.dart      # seed sample attributes/variants
dart run tool/query_variant_attributes.dart 1   # print attributes for variant 1
```

These tools write/read the canonical `backups/clothes_pos_clean.db` file. Remove other `.db` duplicates under `.dart_tool` if you need to reclaim space; the canonical backups file is the one used by the tooling.

## Project Structure

- presentation/: Cupertino UI & routing (go_router)
- domain/: entities & use cases (planned)
- data/: repositories & data sources (planned)
- core/: db helper, DI, utilities
- assets/db/: schema.sql
- docs/: TASKS.md, DB_SCHEMA.md

## Tests

```
flutter test
```

## CI

Simple workflow runs analyze and tests on PRs (see .github/workflows/ci.yml).

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

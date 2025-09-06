# Clothes POS

![CI](https://github.com/lionzentany-source/clothes_pos/actions/workflows/ci.yml/badge.svg)
![Android Release](https://github.com/lionzentany-source/clothes_pos/actions/workflows/android-release.yml/badge.svg)
![License](https://img.shields.io/badge/license-Private-informational)

iOS-style (Cupertino) Point-of-Sale app for clothing stores, built with Flutter.
Local-first (SQLite) architecture, dynamic product attributes, offline‑friendly vision, and printable receipts / labels.

## Core Features

- Cupertino iOS UI: POS, Inventory, Reports, Settings.
- Dynamic attributes system (no fixed size/color columns) with migration tooling (migrations 022–025) and attribute picker UI.
- Local SQLite (sqflite / ffi) for: products, variants, sales, purchases, inventory movements, cash sessions, users / roles.
- Barcode scanning via `barcode_scan2` (replaces legacy `flutter_barcode_scanner`).
- Printable PDFs (receipts, reports) with Arabic font embedding (Noto Naskh Arabic + SF Arabic fallback) and thermal ESC/POS output.
- Cash session management (open/close, variance logging).
- Offline-friendly seeding & canonical clean DB utilities.
- Charts & KPIs (fl_chart) + reporting repositories.
- Modular DI (`get_it`) and layered repository adapters (planned expansion).

## Run

- Flutter 3.22+ and Dart SDK 3.8+
- Platforms: Android, iOS, Windows, macOS, Linux (dev)

Install deps and run:

```
flutter pub get
flutter run
```

## Developer: Dynamic Attributes / Clean DB

For working with a fresh, canonical clean database (no legacy size/color columns) the repo uses `backups/clothes_pos_clean.db`.

Quick commands (run from repo root):

```powershell
dart run tool/create_clean_db.dart    # create backups/clothes_pos_clean.db
dart run tool/seed_clean_db.dart      # seed sample attributes/variants
dart run tool/query_variant_attributes.dart 1   # print attributes for variant 1
```

These tools write/read the canonical `backups/clothes_pos_clean.db` file. Remove other `.db` duplicates under `.dart_tool` if you need to reclaim space; the canonical backups file is the one used by the tooling.

## Project Structure (selected)

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

Simple workflow runs analyze and tests on PRs (see `.github/workflows/ci.yml`). It currently executes:

1. Checkout & Flutter setup (stable channel)
2. `flutter pub get`
3. `flutter analyze`
4. `flutter test` (all unit/widget tests)
5. Coverage collection & optional upload (Codecov if token available)

You can extend it with a production release job that performs an obfuscated, size‑optimized build once signing is configured (see below).

### Android Release & Versioning

Current version: `1.0.2+4` (active development cycle after tagging `v1.0.1+3`). Use semantic (MAJOR.MINOR.PATCH+BUILD).

1. Generate a keystore (one time):
   ```powershell
   keytool -genkey -v -keystore android/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `android/key.properties` (DO NOT COMMIT):
   ```
   storePassword=YOUR_STORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```
3. Reference it in `android/app/build.gradle.kts` signingConfig (already scaffolded – just uncomment / adapt if needed).
4. Build a release APK / AppBundle with obfuscation & symbol files:
   ```powershell
   flutter build apk --release --obfuscate --split-debug-info=build/symbols
   flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
   ```
5. Keep the `build/symbols` directory private; it is required to de-obfuscate stack traces.

Optional size wins:

- Add ABI splits (Play Store will auto split AAB; for APK you can use `--target-platform android-arm,android-arm64,android-x64` with separate builds)
- Use `--tree-shake-icons` if using Material icons subset only (verify Cupertino dependencies first)

### PDF Arabic Font & Localization

## CHANGELOG

See `CHANGELOG.md` (auto-generated summary below when present). If missing, generate with:

```powershell
git log --pretty="* %h %s" v1.0.0+2..HEAD > CHANGELOG.md
```

## Roadmap (abridged)

- Background sync & conflict resolution
- Rich discount engine & promotions
- Multi-store replication
- Advanced reporting dashboards
- Full hardware integration (RFID gates, network printers auto-discovery)

---

For internal/private use. Do not distribute binaries externally without authorization.

To eliminate glyph warnings in generated PDFs, add high-quality Arabic fonts (e.g., Noto Naskh Arabic Regular/Bold) under `assets/fonts/` (filenames must match the entries added in `pubspec.yaml`). The label template engine loads in this priority: Noto Regular -> Noto Bold -> SF Arabic -> SF Latin. Missing assets are skipped silently. Add a widget / unit test later to assert at least one Arabic-capable font loads for deterministic output.

---

## 🇴🇲 الميزات (Arabic Feature Overview)

> ملخص شامل لميزات نظام نقاط البيع (Clothes POS) باللغة العربية.

### 1. الواجهة و التجربة
- واجهة iOS (Cupertino) سريعة و متجاوبة.
- دعم اتجاه RTL كامل للعربية.
- تنظيم منطقي: المبيعات – الجرد – التقارير – الإعدادات.
- عناصر تفاعلية خفيفة تدعم الاختبارات (مفاتيح Widgets مدروسة).

### 2. إدارة المنتجات و المتغيرات
- خصائص (Attributes) ديناميكية بدون أعمدة ثابتة (مثل اللون/المقاس التقليدية).
- ترحيلات قاعدة بيانات (migrations 022–025) تدعم إضافة الخصائص مستقبلاً بدون كسر البيانات.
- منتقي خصائص متقدم (AttributePicker) مع:
   - بحث فوري مع Normalization للنص العربي.
   - منع التكرار و تخزين مؤقت للقيم.
   - إعادة ترتيب العناصر المختارة بالسحب (اختبارياً عبر الأسهم حالياً).
- دعم صور أو وسائط مستقبلية (واجهة جاهزة للتوسعة).

### 3. قاعدة البيانات و البيانات
- SQLite محلي (sqflite / ffi) مع إمكانية التشغيل على: Android / Windows / Linux / macOS.
- ملف قاعدة "نظيفة" قياسي `backups/clothes_pos_clean.db` لتوليد/اختبار السيناريوهات.
- أدوات (Scripts) لتوليد / تهيئة / فحص البيانات (
   - create_clean_db / seed_clean_db / query_variant_attributes).
- نسخ احتياطي تلقائي (db backups) أثناء التطوير لتجنّب فقدان البيانات.

### 4. المخزون و الجرد
- تهيئة بيانات أولية (Seed) للمقاسات و الألوان.
- تعقب المتغيرات (Variants) و دعم تعدد السمات.
- منطق تجاري للتحقق من الكمية و الأخطاء الشائعة (مغطى في اختبارات عملية).

### 5. المبيعات و الجلسات النقدية
- فتح و إغلاق الجلسات مع تسجيل الانحراف (Variance Logging).
- بنية قابلة لإضافة الخصومات – العروض – ضريبة القيمة المضافة مستقبلاً.
- فصل منطقي بين الحفظ المؤقت و الإتمام (Checkout Flow – تحت التطوير).

### 6. الطباعة و التقارير
- توليد فواتير PDF بخط عربي (Noto Naskh Arabic + SF Pro Arabic).
- توليد إيصالات حرارية ESC/POS (مهيأة لدمج الطابعات لاحقاً).
- دعم باركود (barcode_scan2 + barcode) و إعداد لبناء ملصقات.
- مخطط (Charts) و مؤشرات تشغيل أساسية عبر fl_chart.

### 7. الأداء و الاستقرار
- Lazy loading لقيم الخصائص لتقليل استهلاك الذاكرة.
- Normalization للنص العربي لتسريع و دقة البحث.
- التعامل مع mounted context بعد العمليات غير المتزامنة (تم تصحيح حالات حرجة).

### 8. الأمن و التحكم
- طبقة مبدئية للمستخدمين و الأدوار (قابلة للتوسعة).
- تخطيط مستقبلي للتخزين الآمن (flutter_secure_storage) – جاهز ومضاف.

### 9. الاختبارات
- اختبارات وحدة + Widgets لسيناريوهات حقيقية (أخطاء مستخدم – تسجيل دخول – منتقي الخصائص – المحرر).
- التزامن المنخفض في CI لتجنب حالات Race في SQLite.

### 10. أدوات التطوير (Tooling)
- CI مهيأ (تحليل + اختبارات) عبر GitHub Actions.
- مسار إصدار Android تلقائي عند دفع Tag (يُولد Release Notes).
- CHANGELOG منظم مع دورات إصدار واضحة.
- سكربتات مساعدة لتوليد / فحص قاعدة البيانات.

### 11. خارطة الطريق (ملخص مستقبلي)
- مزامنة سحابية / تعدد الفروع.
- محرك عروض/خصومات ذكي.
- تكامل RFID و قارئات UHF.
- اكتشاف طابعات الشبكة آلياً.
- لوحات مراقبة تحليلية تفاعلية.

---

إذا رغبت في إضافة/تصحيح أي وصف للميزات؛ افتح قضية (Issue) داخل المستودع أو نفّذ تعديل مباشر على هذا القسم.

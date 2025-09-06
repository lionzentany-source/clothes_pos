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

<!-- FEATURES_AR_START -->
## 🇴🇲 نظرة شاملة على النظام (Clothes POS)

"Clothes POS" نظام نقاط بيع مخصص لمحلات بيع الملابس والأزياء، مُصمَّم ليكون محلي أولاً (Local‑First) يعمل دون اتصال دائم، مع بنية مرنة لإدارة خصائص المنتجات (المقاس، اللون، الخامة، أي خصائص مخصصة) دون الحاجة لتعديل بنية قاعدة البيانات كل مرة. يعتمد واجهة iOS (Cupertino) نظيفة، ويستهدف سهولة التدريب، السرعة في عمليات البيع، وتخفيض الأخطاء التشغيلية.

يهدف النظام إلى:

- تسريع إدخال وإدارة المنتجات ومتغيراتها.
- تقليل الازدواجية (Duplicate Data) في الخصائص والقيم.
- تمكين التقارير الأساسية والتوسع لاحقاً نحو تحليلات أعمق.
- توفير أساس متين للطباعة (فواتير PDF – إيصالات حرارية – باركود – ملصقات).
- دعم التدرج نحو مزامنة سحابية مستقبلية بدون إعادة كتابة المنظومة.

> هذا الملف هو المصدر الرئيسي (Single Source) لقسم الميزات العربية في README. لا تعدل القسم داخل README مباشرة؛ حدّث هذا الملف ثم شغّل:
>
> ```powershell
> dart run tool/update_features_section.dart
> ```

---

### 🧭 0. ملخص سريع (Executive Summary)

| المجال   | القيمة الأساسية                               |
| -------- | --------------------------------------------- |
| المنتجات | خصائص ديناميكية + متغيرات متعددة              |
| المبيعات | جلسة نقدية + تسجيل انحراف عند الإغلاق         |
| الجرد    | تتبع مخزون المتغيرات وعمليات الإدخال مستقبلاً |
| الطباعة  | PDF عربي + ESC/POS حراري + باركود             |
| الأداء   | محلي، تحميل كسول، Normalization عربي للبحث    |
| التطوير  | CI، ترحيلات منظمة، سكربتات قاعدة بيانات       |

---

### 1. الواجهة و التجربة

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
  - إعادة ترتيب العناصر المختارة (حالياً بأسهم – قابل للتوسعة للسحب لاحقاً).
- دعم صور أو وسائط مستقبلية (واجهة جاهزة للتوسعة).

### 3. قاعدة البيانات و البيانات

- SQLite محلي (sqflite / ffi) يعمل عبر منصات متعددة.
- ملف قاعدة "نظيفة" قياسي `backups/clothes_pos_clean.db`.
- سكربتات توليد/تهيئة/استعلام (create_clean_db / seed_clean_db / query_variant_attributes).
- نسخ احتياطية تلقائية أثناء التطوير.

### 4. المخزون و الجرد

- Seed أولي للمقاسات و الألوان.
- دعم المتغيرات متعددة الخصائص.
- حماية من إدخالات ناقصة عبر منطق تحقق مغطى باختبارات.

### 5. المبيعات و الجلسات النقدية

- فتح/إغلاق جلسة مع تسجيل الانحراف.
- قابلية إضافة الخصومات والضرائب.
- فصل تدفق الحفظ المؤقت عن الإتمام.

### 6. الطباعة و التقارير

- فواتير PDF بخط عربي مدمج (Noto Naskh Arabic + SF Pro Arabic).
- إيصالات حرارية ESC/POS.
- باركود وملصقات (barcode_scan2 + barcode).
- مخططات fl_chart ومؤشرات تشغيل.

### 7. الأداء و الاستقرار

- Lazy loading لقيم الخصائص.
- Normalization عربي للبحث.
- تفادي أخطاء mounted context.

### 8. الأمن و التحكم

- طبقة مستخدمين وأدوار أولية.
- تهيئة تخزين آمن مستقبلية (flutter_secure_storage).

### 9. الاختبارات

- وحدة + Widgets + سيناريوهات أخطاء مستخدم حقيقية.
- ضبط تزامن منخفض لتفادي مشاكل SQLite.

### 10. أدوات التطوير (Tooling)

- CI (تحليل + اختبارات) GitHub Actions.
- مسار إصدار Android عبر Tag.
- CHANGELOG منظم.
- سكربتات قاعدة البيانات.

### 11. خارطة الطريق (مقتطف)

- مزامنة / تعدد الفروع.
- محرك عروض.
- RFID و UHF.
- اكتشاف طابعات الشبكة.
- لوحات تحليلية تفاعلية.

---

### 12. حالات استخدام (Use Cases)

1. إضافة منتج جديد بخصائص خاصة (مثلاً: المقاس الأوروبي + نوع القماش):

- إدخال الاسم الأساسي للمنتج.
- اختيار الخصائص الديناميكية أو إضافة قيم جديدة في المستقبل (واجهة التوسعة مخططة).
- إنشاء المتغيرات (Variants) لكل تركيبة (Size + Color ...).

2. تنفيذ عملية بيع:

- فتح جلسة نقدية (Session) في بداية اليوم.
- مسح باركود المتغير أو البحث النصي.
- إضافة للعربة وحساب المجموع (خصومات مستقبلية).
- طباعة إيصال حراري + (اختياري) فاتورة PDF.

3. إغلاق الجلسة النقدية:

- إدخال الرصيد الفعلي.
- تسجيل الانحراف (Variance) تلقائياً وحفظه للتقارير.

4. جرد سريع (Stocktake) مبدئي:

- (جزء مبدئي في الاختبارات) التحقق من الكميات وعرض أخطاء الإدخال.

5. استخراج تقرير يومي:

- (قابل للتوسع) استخدام واجهة التقارير لعرض مؤشرات المبيعات.

### 13. التصميم المعماري (Architecture)

- طبقة العرض: Widgets تعتمد Cupertino + تقسيم واضح (Inventory / Sales / Settings / Reports).
- إدارة الحالة: Cubits / BLoC مدمج + إمكانية التدرج.
- الاعتمادية (DI): get_it لتجميع الخدمات والمستودعات.
- قاعدة البيانات: SQLite محلي مع ترحيلات تدريجية (Migration رقمية مرتبة).
- فصل منطقي مستقبلي (domain / data / presentation) – مهيأ لكن بعض الأجزاء "planned".

### 14. نموذج البيانات (Data Model) المختصر

| الكيان             | وصف                                  |
| ------------------ | ------------------------------------ |
| products           | المنتج الرئيسي (بدون خصائص تفصيلية). |
| variants           | متغيرات المنتج (كل تركيبة خصائص).    |
| attributes         | تعريف اسم الخاصية (مثلاً: مقاس).     |
| attribute_values   | القيم الممكنة (مثلاً: M / L / أحمر). |
| variant_attributes | ربط (variant ↔ attribute_value).     |
| sessions           | الجلسة النقدية لليوم.                |
| sales / sale_items | (مخطط أو في التوسعة) عمليات البيع.   |

### 15. التقنيات المستخدمة (Tech Stack)

- Flutter (واجهة + منطق مشترك).
- Dart (لغة التنفيذ – سهولة الاختبارات).
- sqflite / sqflite_common_ffi (دعم المنصات المكتبية أثناء التطوير).
- get_it (حقن اعتمادية بسيط).
- barcode_scan2 + barcode (التقاط و توليد باركود لاحقاً).
- pdf + printing (مخرجات PDF + طباعة حرارية عبر ESC/POS).
- fl_chart (مخططات أولية / مؤشرات أداء).
- github actions (تحليل + اختبارات + إصدار Android تلقائي).

### 16. الأداء و الجودة (Quality & Performance Notes)

- التحميل الكسول لقيم الخصائص يمنع تضخم الذاكرة عند تعدد القيم.
- البحث الموحّد Normalized يقلل الضوضاء (ألف همزة/مد – ياء/ألف مقصورة – إلخ).
- فصل النص العربي في الخطوط المدمجة يمنع فقدان الحروف أو المربعات الفارغة في PDF.

### 17. الأمان و الخصوصية

- لا يتم إرسال البيانات إلى خوادم خارجية (محلي أولاً).
- التخزين الآمن للمفاتيح/التوكنات مخطط عبر flutter_secure_storage.
- صلاحيات المستخدمين (Roles) قابلة للتوسعة (نموذج أولي موجود).

### 18. القيود الحالية (Current Limitations)

- لا توجد مزامنة سحابية بعد.
- لا يوجد محرّك خصومات متقدم (خصم يدوي مستقبلاً).
- إدارة المخزون (حركات وارد/صادر) في طور الإعداد.
- عدم تنفيذ سحب وإفلات لتغيير ترتيب المتغيرات (يستخدم أسهم حالياً).
- عدم تفعيل الطباعة الشبكية التلقائية (قيد التخطيط).

### 19. فرص التوسعة (Expansion Opportunities)

- Web Admin Panel لإدارة مركزية.
- دعم أجهزة RFID / قارئات UHF (SDK موجود في المستودع كبداية).
- تجميع تقارير زمنية لحظية (Real‑Time Stream) عند إضافة WebSocket/Sync.
- ذكاء تسعير ديناميكي حسب الموسم.

### 20. سير عمل التطوير (Development Workflow)

1. إنشاء فرع ميزة feature/…
2. تشغيل: `flutter analyze` و `flutter test` قبل أي Commit.
3. تحديث CHANGELOG عند إغلاق الميزة.
4. دمج إلى main ثم إنشاء Tag لإطلاق إصدار Android (Workflow تلقائي).

### 21. معايير القبول (Definition of Done – مختصر)

- الكود يمر التحليل (Lint) بلا أخطاء.
- تغطية اختبار أساسية للمسار الحرج (AttributePicker / Login / جرد).
- لا تحذيرات UI ظاهرة (Logs نظيفة قدر الإمكان).
- تحديث الوثائق (هذا الملف أو README عند لمس الميزات).

### 22. لمحة للمستخدم النهائي

"من شاشة واحدة يمكنك مسح باركود المتغير، ضبط الكمية، إصدار إيصال حراري، ومع نهاية اليوم تغلق الجلسة وتعرف إن كان هناك فرق نقدي." الهدف: وقت تدريب قصير (أقل من 30 دقيقة) لأي موظف جديد.

---

تحرير هذا الملف ثم تشغيل سكربت التحديث سيعيد حقن هذا المحتوى داخل README بين العلامتين:
`<!-- FEATURES_AR_START -->` و `<!-- FEATURES_AR_END -->`.

آخر تحديث تلقائي: سيتم تجديد التاريخ لاحقاً عند أتمتة السكربت (اقتراح مستقبلي بإضافة ختم زمني).

<!-- FEATURES_AR_END -->
`.

<!-- FEATURES_AR_END -->

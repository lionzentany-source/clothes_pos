# خطة تنفيذ نظام الخصائص الديناميكي للمنتجات

هذا المستند يوضح الخطة التفصيلية والآمنة لتعديل نظام خصائص المنتجات من النظام الثابت (مقاس ولون) إلى نظام ديناميكي مرن.

**المبدأ الأساسي:** الإضافة والتحقق قبل الحذف لضمان سلامة البيانات واستقرار المشروع.

---

### المرحلة 0: التحضير والأمان (Preparation & Safety)

**الهدف:** تجهيز بيئة العمل الآمنة والتأكد من وجود خطة تراجع.

- [ ] **إنشاء فرع جديد في Git:**
  - [x] إنشاء فرع جديد باسم `feature/dynamic-attributes` لعزل العمل عن الكود الرئيسي.
- [ ] **أخذ نسخة احتياطية من قاعدة البيانات:**
  - [ ] عمل نسخة كاملة من قاعدة بيانات التطوير قبل البدء.
- [x] عمل نسخة كاملة من قاعدة بيانات التطوير قبل البدء.
- [ ] **تطبيق "مفتاح تفعيل الميزة" (Feature Flag):**
  - [x] إضافة متغير عام في إعدادات التطبيق، وليكن `useDynamicAttributes`.
  - [x] تعيين قيمته المبدئية إلى `false`.

---

### المرحلة 1: تعديل هيكل قاعدة البيانات (بشكل إضافي)

**الهدف:** بناء الجداول الجديدة في قاعدة البيانات دون المساس بالهيكل الحالي.

- [x] **إنشاء ملف ترحيل (Migration Script) جديد:**
  - [x] إضافة أوامر `CREATE TABLE` لإنشاء الجداول التالية:
    - [x] `attributes` (id, name)
    - [x] `attribute_values` (id, attribute_id, value)
    - [x] `variant_attributes` (variant_id, attribute_value_id)
- [x] **تنفيذ الترحيل على قاعدة بيانات التطوير:**
  - [x] تشغيل السكربت لإنشاء الجداول الجديدة.
- [x] **التحقق من الهيكل:**
  - [x] التأكد يدويًا من أن الجداول الجديدة تم إنشاؤها بالحقول الصحيحة.

---

### المرحلة 2: نقل البيانات القديمة (Data Migration)

**الهدف:** ترحيل البيانات من الأعمدة القديمة (`size`, `color`) إلى الهيكل الجديد.

- [x] **كتابة سكربت مخصص لنقل البيانات (e.g., `migrate_legacy_attributes.dart`):**
  - [x] **الخطوة 1:** السكربت يضيف "المقاس" و "اللون" في جدول `attributes`.
  - [x] **الخطوة 2:** السكربت يقرأ كل قيم `size` و `color` الفريدة من `product_variants` ويضيفها في جدول `attribute_values`.
  - [x] **الخطوة 3:** السكربت يمر على كل سجل في `product_variants` ويضيف الروابط المناسبة في جدول `variant_attributes`.
- [ ] **تنفيذ سكربت النقل على قاعدة بيانات التطوير.**
- [x] **تنفيذ سكربت النقل على قاعدة بيانات التطوير.**
- [ ] **التحقق من صحة البيانات المنقولة:**
  - [ ] اختيار عينة من المنتجات والتحقق من أن مقاساتها وألوانها القديمة ممثلة بشكل صحيح في الجداول الجديدة.

---

### المرحلة 3: بناء منطق العمل الخلفي (Backend)

**الهدف:** كتابة الكود المسؤول عن التعامل مع الهيكل الجديد، وتفعيله فقط عبر "مفتاح التفعيل".

- [ ] **إنشاء وحدات الوصول للبيانات (DAOs & Repositories) الجديدة:**
  - [x] بناء `AttributeDao` و `AttributeRepository` لإدارة الخصائص وقيمها. (implemented)
- [ ] **تعديل `ProductRepository` و `ProductDao`:**
- [x] **تعديل `ProductRepository` و `ProductDao`:**
  - [x] استخدام `if (useDynamicAttributes)` للفصل بين المنطق القديم والجديد في الدوال التالية:
    - [x] `createProductWithVariants`
    - [x] `updateProductAndVariants`
    - [x] `searchVariants`
    - [x] `getVariantsByParent`
- [ ] **كتابة اختبارات الوحدات (Unit Tests):**
  - [ ] كتابة اختبارات جديدة مخصصة للكود الجديد للتأكد من أنه يعمل كما هو متوقع.
  - [x] جزء مبدئي من التحقق: أضفنا أداة اختبار تشغيلية (`tool/test_attribute_repository.dart`) تستخدم `sqflite_common_ffi` للتحقق من وظائف الـDAO/Repository بدون الحاجة لتشغيل Flutter.
  - [ ] كتابة اختبارات `flutter_test` كاملة لتغطية المسارات القديمة والجديدة في `ProductRepository`.

### ملاحظات على التقدم (Changes made)

- Feature flag: `lib/core/config/feature_flags.dart`
  - تم تحويل `useDynamicAttributes` إلى قيمة قابلة للتجاوز زمن التشغيل والاختبار (env var `USE_DYNAMIC_ATTRIBUTES` و `FeatureFlags.setForTests`).
- Backend helpers:
  - `lib/data/attributes/attribute_dao.dart` (new)
  - `lib/data/attributes/attribute_repository.dart` (new)
- Test tooling:
  - `tool/test_attribute_repository.dart` (new) — تشغيل مستقل للتحقق من عمليات الإدخال والربط باستخدام `sqflite_common_ffi`.
- Migration & tools (unchanged behavior): discovery/extract/commit tools under `tool/` were extended to accept `--db=` and already used to run discovery/extract/commit on dev DB.

**التحديث الحالي (Status update):**

- تم تنفيذ الجزء الأساسي من المرحلة 3 (Backend) مع أدوات مساعدة جاهزة للعمل محليًا. العمل المنجز يشمل إنشاء DAOs/Repositories الخاصة بالخصائص، أدوات تشغيل مستقلة لإنشاء DB نظيف، تهيئته، واستخراج/استعلام الخصائص.
- تم تعليق/تأجيل ترحيل بيانات legacy لصالح إنشاء قاعدة بيانات نظيفة عند طلب المستخدم؛ لذلك لم نعدل الأعمدة القديمة في قاعدة الإنتاج.

### تقرير التقدم الآن (آخر تحديث: 2025-08-28)

- ملخص التنفيذ حتى الآن:

  - تم إنشاء DAOs وRepositories للـ Attributes (`AttributeDao`, `AttributeRepository`) وتكاملها الأساسي مع منطق المنتجات.
  - تم إضافة أداة إنشاء/تعبئة قاعدة بيانات نظيفة: `tool/create_clean_db.dart`, `tool/seed_clean_db.dart`، وتوحيد المسار إلى `backups/clothes_pos_clean.db`.
  - تمت أدوات تنظيف وإدارة النسخ المكررة من قواعد البيانات داخل `.dart_tool`، وأضيفت قواعد تجاهل `.gitignore` ومنع الالتزام لملفات DB.
  - الواجهة: تم تنفيذ عنصر واجهة `AttributePicker` ودمجه داخل `ProductEditorScreen` (اختياري عبر `FeatureFlags.useDynamicAttributes` ووجود `skipInit` للاختبارات).
  - اختبارات واجهة: أضيفت واختبرت `test/widget/attribute_picker_test.dart` و `test/widget/attribute_picker_reorder_test.dart` (تمرير محلي).

- ملفات وتغييرات ملحوظة (نموذجي):

  - `lib/presentation/inventory/widgets/attribute_picker.dart` — واجهة الاختيار (بحث، اقتراحات، إعادة ترتيب سحب/إفلات بنمط Cupertino، سمات الوصول).
  - `lib/presentation/inventory/screens/product_editor_screen.dart` — ربط واجهة إدارة/اختيار الخصائص للمتغيرات، إضافة `skipInit` للاختبارات.
  - `lib/data/datasources/attribute_dao.dart`, `lib/data/repositories/attribute_repository.dart` — DAOs وRepositories للخصائص.
  - أدوات `tool/` المذكورة أعلى (create/seed/query/cleanup).

- حالة الاختبارات والتكامل:

  - اختبارات وحدة/أداة تشغيل: `tool/test_attribute_repository.dart` متاحة لاختبار DAOs عبر `sqflite_common_ffi`.
  - اختبارات واجهة (Widget): تم تنفيذ اختبارات لعنصر `AttributePicker` محليًا وتمت بنجاح.
  - اختبارات واجهة إضافية: تمت إضافة وتشغيل اختبارات تحقق لحالة الإدخال ورفض الأسماء المكررة على `ManageAttributesScreen`:
    - `test/widget/manage_attributes_validation_test.dart` — تغطية: empty input + duplicate-name (case-insensitive). تم التشغيل محليًا ونجاحها.
  - اختبارات دمج DB-مدعومة (integration tests) لم تُنفذ بعد بصورة شاملة بسبب إدارة دورة حياة DB وDI؛ نوصي بالاعتماد على فحص DI وإعداد DB صريح قبل تشغيلها.

- عناصر مؤقتة/مؤجلة:
  - التحقق اليدوي الشامل لنتائج سكربت الترحيل على مجموعة بيانات حقيقية ما زال معلقًا حتى يُعطى توقيت مناسب.
  - تغطية اختبارات `flutter_test` كاملة لمسارات legacy vs dynamic ما زالت مطلوبة.

### أوامر سريعة لتشغيل الاختبارات المحلية (مثال)

```powershell
flutter test test/widget/attribute_picker_test.dart -r expanded
flutter test test/widget/attribute_picker_reorder_test.dart -r expanded
dart run tool/test_attribute_repository.dart
```

أدوات ومهمات تم تنفيذها وموجودة في المستودع:

- [x] `tool/create_clean_db.dart` — ينشئ `backups/clothes_pos_clean.db` (قاعدة نظيفة بدون أعمدة `size`/`color`).
- [x] `tool/seed_clean_db.dart` — يملأ `backups/clothes_pos_clean.db` بعينات (attributes/attribute_values/variant_attributes).
- [x] `tool/query_variant_attributes.dart` — استعلام سريع لعرض الخصائص المرتبطة بمتغير معين (قبلته args: variantId و optional dbPath).
- [x] `tool/cleanup_db_duplicates.dart` — أداة نظافة لإزالة ملفات .db المكررة داخل `.dart_tool`.
- [x] تم إضافة `.gitignore` لتجاهل `backups/*.db` وملفات DB التي يولدها `sqflite_common_ffi` داخل `.dart_tool`.
- [x] تم تحديث `README.md` لإضافة قسم "Developer: clean DB" مع أوامر قصيرة (create/seed/query).
- [x] تم إزالة نسخ DB المكررة داخل `.dart_tool` وتركنا فقط `backups/clothes_pos_clean.db` كملف Canonical.

### كيف تختبر محليًا (Quick run commands)

تشغيل اختبار الـRepository (in-memory):

```powershell
dart run tool/test_attribute_repository.dart
```

تشغيل اكتشاف المصادر (على DB محدد):

```powershell
dart run tool/generate_discovery_report.dart --db=C:\absolute\path\to\clothes_pos.db
```

تشغيل الاستخراج (dry-run):

```powershell
dart run tool/extract_and_dryrun_migrate.dart --db=C:\absolute\path\to\clothes_pos.db
```

تشغيل التزام الخطط (يتطلب موافقتك الصريحة؛ سيأخذ نسخة احتياطية):

```powershell
dart run tool/commit_planned_inserts.dart --apply --backup --db=C:\absolute\path\to\clothes_pos.db
```

### الترقيم التالي (Next priorities)

1. دمج `AttributeRepository` في `ProductRepository`/`ProductDao` مع الفحص `if (FeatureFlags.useDynamicAttributes)` للحفاظ على التوافق.
2. كتابة اختبارات وحدات كاملة (`flutter_test`) لتغطية الإنشاء/التحديث/البحث لكلتا الحالتين (legacy vs dynamic).
3. توسيع قواعد التطبيع والمرادفات (قوائم أوسع للألوان والأحجام) قبل تشغيل الترحيل على DB حقيقية.
4. بعد نجاح المراحل السابقة وتشغيل الترحيل على staging وإجراء مراجعات يدوية، تنفيذ الترحيل على production ثم تنظيف الأعمدة القديمة في إصدار لاحق.

---

### المرحلة 4: بناء واجهات المستخدم (Frontend)

**الهدف:** تصميم الشاشات الجديدة وتكييف الشاشات الحالية للعمل مع النظام الجديد.

- [x] **بناء شاشة "إدارة الخصائص":** (partially implemented)
  - [x] `ManageAttributesScreen` — CRUD + validation + confirmations implemented.
  - [ ] UX polish, localization, and accessibility review for the screen.
- [ ] **تعديل "شاشة محرر المنتج":**
  - [ ] استخدام `if (useDynamicAttributes)` لعرض الواجهة المناسبة.
  - [ ] **الواجهة الجديدة:**
    - [ ] إضافة قائمة لاختيار الخصائص التي تنطبق على المنتج الأب.
    - [ ] بناء حقول إدخال ديناميكية للمتغيرات بناءً على الخصائص المختارة.
- [ ] **تحديث طريقة عرض بيانات المتغيرات في كل الشاشات:**
  - [ ] تعديل شاشة نقاط البيع (POS).
  - [ ] تعديل شاشة فواتير المشتريات والمبيعات.
  - [ ] تعديل كل التقارير ذات الصلة.
- [ ] **اختبار يدوي كامل (End-to-End Testing):**
  - [ ] تفعيل `useDynamicAttributes` إلى `true` في بيئة التطوير واختبار دورة حياة المنتج كاملة.

---

### المرحلة 5: الإطلاق النهائي والتنظيف (Deployment & Cleanup)

**الهدف:** تفعيل الميزة الجديدة بشكل كامل للمستخدمين وإزالة الكود القديم بأمان.

- [ ] **التخطيط للإطلاق:**
  - [ ] تحديد وقت مناسب لعملية النشر (يفضل في وقت لا يوجد فيه ضغط عمل).
  - [ ] أخذ نسخة احتياطية كاملة من قاعدة البيانات **الحقيقية (Production)**.
- [ ] **تنفيذ نقل البيانات النهائية:**
  - [ ] تشغيل سكربت نقل البيانات (من المرحلة 2) على قاعدة البيانات الحقيقية.
- [ ] **نشر الكود الجديد وتفعيل الميزة:**
  - [ ] نشر النسخة الجديدة من التطبيق.
  - [ ] تغيير قيمة `useDynamicAttributes` إلى `true` بشكل دائم.
- [ ] **المراقبة بعد الإطلاق:**
  - [ ] مراقبة أداء النظام وسجلات الأخطاء عن كثب.
- [ ] **مرحلة التنظيف (تتم في إصدار مستقبلي بعد ضمان الاستقرار):**
  - [ ] **إنشاء سكربت ترحيل جديد للحذف:**
    - [ ] السكربت يحتوي على أمر `ALTER TABLE product_variants DROP COLUMN size`.
    - [ ] السكربت يحتوي على أمر `ALTER TABLE product_variants DROP COLUMN color`.
  - [ ] **إعادة هيكلة الكود (Refactoring):**
    - [ ] إزالة كل الشروط `if (useDynamicAttributes)` والكود القديم المتعلق بها.
    - [ ] إزالة متغير `useDynamicAttributes` نفسه من الكود.

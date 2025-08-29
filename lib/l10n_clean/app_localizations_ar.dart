// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'نقطة بيع الملابس';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginEnterPassword => 'أدخل كلمة المرور';

  @override
  String get loginCancel => 'إلغاء';

  @override
  String get loginContinue => 'متابعة';

  @override
  String get loginInvalid => 'بيانات الدخول غير صحيحة';

  @override
  String get loginNoUsers => 'لا يوجد مستخدمون نشطون';

  @override
  String get posTab => 'المبيعات';

  @override
  String get inventoryTab => 'المخزون';

  @override
  String get reportsTab => 'التقارير';

  @override
  String get settingsTab => 'الإعدادات';

  @override
  String get posTotal => 'الإجمالي';

  @override
  String get posCart => 'السلة';

  @override
  String get sessionNone => 'لا توجد جلسة';

  @override
  String get sessionOpen => 'جلسة #';

  @override
  String get cashSession => 'الجلسة النقدية';

  @override
  String get open => 'فتح';

  @override
  String get close => 'إغلاق';

  @override
  String get deposit => 'إيداع';

  @override
  String get withdraw => 'سحب';

  @override
  String get xReport => 'تقرير X';

  @override
  String get zReport => 'تقرير Z';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get generalSection => 'عام';

  @override
  String get storeInfo => 'معلومات المتجر';

  @override
  String get languageCurrency => 'اللغة والعملة';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get databaseSection => 'قاعدة البيانات';

  @override
  String get dbBackupRestore => 'نسخ/استعادة قاعدة البيانات';

  @override
  String get inventoryPrintRfidSection => 'المخزون والطباعة وRFID';

  @override
  String get inventorySettings => 'إعدادات المخزون';

  @override
  String get printingSettings => 'إعدادات الطباعة';

  @override
  String get rfidSettings => 'إعدادات RFID';

  @override
  String get userAccountSection => 'حساب المستخدم';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutConfirmCloseSessionTitle => 'إغلاق الجلسة';

  @override
  String get logoutConfirmCloseSessionAmount => 'المبلغ الختامي';

  @override
  String get error => 'خطأ';

  @override
  String get enterValidNumber => 'يرجى إدخال رقم صالح';

  @override
  String get endSession => 'إنهاء الجلسة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get posSales => 'المبيعات';

  @override
  String get posScanError => 'خطأ المسح';

  @override
  String get notFound => 'غير موجود';

  @override
  String get noProductForBarcode => 'لم يتم العثور على منتج بهذا الباركود';

  @override
  String get permissionDeniedSale => 'لا تملك صلاحية إجراء عملية بيع';

  @override
  String get noOpenSession => 'لا يوجد جلسة مفتوحة';

  @override
  String get openSessionFirst => 'افتح جلسة قبل إجراء البيع';

  @override
  String get ok => 'حسنًا';

  @override
  String get closeAction => 'إغلاق';

  @override
  String get openAction => 'بدء الجلسة';

  @override
  String get confirm => 'تأكيد';

  @override
  String get multiPaymentTitle => 'سداد متعدد الطرق';

  @override
  String get totalLabel => 'إجمالي:';

  @override
  String get card => 'بطاقة';

  @override
  String get mobile => 'هاتف';

  @override
  String get cash => 'نقدي';

  @override
  String get remainingCashDue => 'المتبقي على النقدي:';

  @override
  String get changeDue => 'الباقي:';

  @override
  String get posTitle => 'نقطة البيع';

  @override
  String get quickItems => 'سريع';

  @override
  String get priceLabel => 'السعر:';

  @override
  String get quantityLabel => 'الكمية:';

  @override
  String get basket => 'السلة';

  @override
  String get editLine => 'تعديل السطر';

  @override
  String get discountAmount => 'الخصم (مبلغ)';

  @override
  String get taxAmount => 'الضريبة (مبلغ)';

  @override
  String get noteLabel => 'ملاحظة';

  @override
  String get exact => 'المبلغ بالضبط';

  @override
  String get item => 'منتج';

  @override
  String get delete => 'حذف';

  @override
  String get addItem => 'إضافة منتج';

  @override
  String get scanRfid => 'مسح RFID';

  @override
  String get rfidCardsOptional => 'بطاقات RFID (اختياري)';

  @override
  String get addRfidCard => '+ إضافة بطاقة';

  @override
  String get addRfidTitle => 'إضافة بطاقة RFID';

  @override
  String get epcPlaceholder => 'EPC';

  @override
  String get stop => 'إيقاف';

  @override
  String get scanning => 'جاري المسح...';

  @override
  String get pressStop => 'اضغط إيقاف عند الانتهاء';

  @override
  String get warning => 'تنبيه';

  @override
  String addedIgnored(Object added, Object ignored) {
    return 'تمت إضافة $added وتجاهل $ignored لتجاوز الكمية';
  }

  @override
  String get notEnabled => 'غير مفعّل';

  @override
  String get enableRfidFirst => 'يرجى تفعيل RFID من الإعدادات أولاً';

  @override
  String get scanError => 'خطأ المسح';

  @override
  String get selectVariant => 'اختيار المنتج';

  @override
  String get quantity => 'الكمية';

  @override
  String get cost => 'التكلفة';

  @override
  String get rfiCardsLimitReached =>
      'لا يمكن إضافة المزيد: عدد البطاقات بلغ الكمية';

  @override
  String get choose => 'اختيار';

  @override
  String get receivedDate => 'تاريخ الاستلام';

  @override
  String get change => 'تغيير';

  @override
  String get done => 'تم';

  @override
  String get items => 'مجموع الكاش';

  @override
  String get purchaseInvoiceTitle => 'فاتورة مشتريات';

  @override
  String get save => 'حفظ';

  @override
  String get supplier => 'المورد';

  @override
  String get select => 'اختيار';

  @override
  String get referenceOptional => 'Reference (اختياري)';

  @override
  String get pickVariant => 'اختر المنتج لكل عنصر';

  @override
  String get qtyMustBePositive => 'الكمية يجب أن تكون رقمًا أكبر من صفر';

  @override
  String get costMustBePositive => 'التكلفة يجب أن تكون رقمًا صفريًا أو أكبر';

  @override
  String rfidExceedsQty(Object count, Object qty) {
    return 'عدد بطاقات RFID ($count) أكبر من الكمية ($qty)';
  }

  @override
  String get addAtLeastOne => 'أضف منتجًا واحدًا على الأقل';

  @override
  String get supplierIdRequired => 'Supplier ID مطلوب';

  @override
  String invoiceSaveFailed(Object error) {
    return 'فشل حفظ الفاتورة: $error';
  }

  @override
  String get saleSuccessTitle => 'تمت العملية';

  @override
  String saleNumber(Object id) {
    return 'رقم البيع: $id';
  }

  @override
  String get printReceipt => 'طباعة الإيصال';

  @override
  String get savePdf => 'حفظ PDF';

  @override
  String get payCash => 'دفع نقدًا';

  @override
  String get permissionDeniedTitle => 'غير مسموح';

  @override
  String get openSessionTitle => 'بدء الجلسة';

  @override
  String get openingFloat => 'الرصيد الافتتاحي';

  @override
  String get actualDrawerAmount => 'المبلغ الفعلي في الدرج';

  @override
  String get closedTitle => 'تم الإغلاق';

  @override
  String variance(Object value) {
    return 'الفرق: $value';
  }

  @override
  String get cashDepositTitle => 'إيداع نقدي';

  @override
  String get cashWithdrawTitle => 'سحب نقدي';

  @override
  String get amount => 'المبلغ';

  @override
  String get reasonOptional => 'السبب (اختياري)';

  @override
  String openingFloatLabel(Object value) {
    return 'الرصيد الافتتاحي: $value';
  }

  @override
  String cashSales(Object value) {
    return 'مبيعات نقدية: $value';
  }

  @override
  String depositsLabel(Object value) {
    return 'إيداعات: $value';
  }

  @override
  String withdrawalsLabel(Object value) {
    return 'سحوبات: $value';
  }

  @override
  String expectedCash(Object value) {
    return 'الرصيد المتوقع: $value';
  }

  @override
  String get cashSessionTitle => 'الجلسة النقدية';

  @override
  String get depositAction => 'إيداع';

  @override
  String get withdrawAction => 'سحب';

  @override
  String get reportsTitle => 'التقارير';

  @override
  String get dailySales90 => 'مبيعات يومية (آخر 90 يومًا)';

  @override
  String get monthlySales24 => 'مبيعات شهرية (آخر 24 شهرًا)';

  @override
  String get topProductsQty => 'أفضل المنتجات (حسب الكمية)';

  @override
  String get staffPerformance => 'أداء الموظفين';

  @override
  String get purchasesTotalPeriod => 'إجمالي المشتريات (حسب الفترة)';

  @override
  String get stockStatusLowFirst => 'حالة المخزون (أقل كمية أولًا)';

  @override
  String get pickEmployee => 'اختر الموظف';

  @override
  String get pickCategory => 'اختر الفئة';

  @override
  String get pickSupplier => 'اختر المورد';

  @override
  String get selectAction => 'تصفية';

  @override
  String get clearFilters => 'مسح المرشحات';

  @override
  String stockLowIndicator(Object qty, Object rp, Object sku) {
    return 'SKU $sku: $qty - RP $rp';
  }

  @override
  String get datePickerSelect => 'اختيار';

  @override
  String get datePickerTitle => 'اختر التاريخ';

  @override
  String get searchPlaceholder => 'ابحث عن المنتج أو امسح الباركود';

  @override
  String get searchProductPlaceholder => 'ابحث عن منتج...';

  @override
  String get sizeLabel => 'المقاس:';

  @override
  String get colorLabel => 'اللون:';

  @override
  String get skuLabel => 'رقم الصنف:';

  @override
  String get barcodeLabel => 'الباركود:';

  @override
  String get stocktakeTitle => 'الجرد';

  @override
  String get countedUnitsLabel => 'مجرود';

  @override
  String get uncountedUnitsLabel => 'غير مجرود';

  @override
  String get countedCostLabel => 'تكلفة المجرود';

  @override
  String get countedProfitLabel => 'الربح';

  @override
  String get startRfid => 'بدء قراءة RFID';

  @override
  String get stopReading => 'إنهاء القراءة';

  @override
  String get addByBarcode => 'إضافة بالباركود';

  @override
  String get categories => 'الفئات';

  @override
  String get checkout => 'إتمام البيع';

  @override
  String get addAction => 'إضافة';

  @override
  String get returnLabel => 'مرتجع';

  @override
  String get currency => 'العملة';

  @override
  String get phoneLabel => 'الهاتف';

  @override
  String get saleReceiptLabel => 'إيصال بيع';

  @override
  String get userLabel => 'المستخدم';

  @override
  String get paymentMethodsLabel => 'طرق الدفع';

  @override
  String get thanksLabel => 'شكرًا لتسوقكم معنا';

  @override
  String get xReportInterim => 'تقرير X (ملخص مؤقت)';

  @override
  String get zReportClosing => 'تقرير Z (إغلاق)';

  @override
  String sessionLabel(Object id) {
    return 'الجلسة: $id';
  }

  @override
  String actualAmountLabel(Object value) {
    return 'المبلغ الفعلي: $value';
  }

  @override
  String get cartEmpty => 'السلة فارغة';

  @override
  String get enableRfidReader => 'تفعيل قارئ RFID';

  @override
  String get debounceWindowMs => 'زمن منع التكرار (مللي ثانية)';

  @override
  String get ignoreSameTagWithinDuration => 'تجاهل نفس الوسم ضمن هذه المدة';

  @override
  String get rfParamsMayRequireRestart =>
      'المعلمات اللاسلكية (قد تتطلب إعادة تشغيل القارئ)';

  @override
  String get transmitPower => 'قوة الإرسال (RF Power)';

  @override
  String get numericValuePerReader => 'قيمة رقمية حسب القارئ';

  @override
  String get regionLabel => 'المنطقة';

  @override
  String get rfidSettingsSaved => 'تم حفظ إعدادات RFID بنجاح';

  @override
  String get pageSizeMm => 'حجم الصفحة (مم)';

  @override
  String get widthPlaceholder58 => 'العرض (58)';

  @override
  String get heightPlaceholder200 => 'الارتفاع (200)';

  @override
  String get marginMm => 'الهامش (مم)';

  @override
  String get marginPlaceholder6 => 'الهامش (6)';

  @override
  String get fontSizePt => 'حجم الخط (نقطة)';

  @override
  String get fontSizePlaceholder10 => 'حجم الخط (10)';

  @override
  String get printingSettingsSaved => 'تم حفظ إعدادات الطباعة';

  @override
  String get lowStockWarningThreshold => 'حد التحذير للمخزون منخفض (بالكمية)';

  @override
  String get example5Placeholder => 'مثال: 5';

  @override
  String get settingsSaved => 'تم حفظ الإعدادات';

  @override
  String get storeNamePlaceholder => 'اسم المتجر';

  @override
  String get addressPlaceholder => 'العنوان';

  @override
  String get currencyPlaceholderLyd => 'العملة (LYD)';

  @override
  String get infoSaved => 'تم حفظ المعلومات';

  @override
  String get backupNow => 'نسخ احتياطي الآن';

  @override
  String get restoreNow => 'استعادة الآن';

  @override
  String get dbFilePathPlaceholder => 'مسار ملف .db';

  @override
  String get chooseFile => 'اختيار ملف';

  @override
  String backupCreatedAt(Object path) {
    return 'تم إنشاء نسخة احتياطية في:\n$path';
  }

  @override
  String get backupFailed => 'فشل النسخ الاحتياطي';

  @override
  String get enterDbPathFirst => 'أدخل مسار ملف .db أولاً';

  @override
  String get fileDoesNotExist => 'الملف غير موجود';

  @override
  String schemaVersionMismatch(Object backup, Object current) {
    return 'إصدار المخطط لا يطابق (الحالي: $current، النسخة: $backup)';
  }

  @override
  String get restoreSuccess => 'تمت الاستعادة بنجاح';

  @override
  String get restoreFailed => 'فشل الاستعادة';

  @override
  String get backupSection => 'نسخ احتياطي';

  @override
  String get restoreSection => 'استعادة';

  @override
  String get restoreVersionPromptTitle => 'اختلاف الإصدار';

  @override
  String restoreVersionPromptMessage(Object backup, Object current) {
    return 'إصدار المخطط الحالي $current مقابل النسخة $backup. هل تريد المتابعة؟ (قد يتعطل التطبيق إن كان غير متوافق)';
  }

  @override
  String get proceed => 'متابعة';

  @override
  String get skip => 'تخطي';

  @override
  String sameVersion(Object version) {
    return 'الإصدارات متطابقة ($version)';
  }

  @override
  String get openPrintDialog => 'إظهار نافذة الطباعة';

  @override
  String get defaultPrinter => 'الطابعة الافتراضية';

  @override
  String get none => 'لا يوجد';

  @override
  String get choosePrinter => 'اختيار طابعة';

  @override
  String get clearDefault => 'مسح الافتراضي';

  @override
  String get testPrinter => 'اختبار الطابعة';

  @override
  String get manageAttributesTitle => 'إدارة الخصائص';

  @override
  String get attributeNoun => 'خاصية';

  @override
  String get noValuesYet => 'لا توجد قيم بعد';

  @override
  String get valueNoun => 'قيمة';

  @override
  String get noAttributesLoaded => 'لم يتم تحميل أي خصائص';

  @override
  String get addNewAttribute => 'إضافة خاصية';

  @override
  String get attributeNamePlaceholder => 'اسم الخاصية';

  @override
  String get nameRequired => 'الاسم مطلوب';

  @override
  String get attributeExists => 'خاصية بهذا الاسم موجودة بالفعل';

  @override
  String get attributeAdded => 'تمت إضافة الخاصية';

  @override
  String get editAttribute => 'تعديل الخاصية';

  @override
  String get attributeSaved => 'تم حفظ الخاصية';

  @override
  String get addNewValue => 'إضافة قيمة';

  @override
  String get valuePlaceholder => 'القيمة';

  @override
  String get valueRequired => 'القيمة مطلوبة';

  @override
  String get valueAdded => 'تمت إضافة القيمة';

  @override
  String get editValue => 'تعديل القيمة';

  @override
  String get valueSaved => 'تم حفظ القيمة';

  @override
  String get confirmDelete => 'تأكيد الحذف';

  @override
  String deleteAttributePrompt(Object name) {
    return 'حذف الخاصية $name?';
  }

  @override
  String deleteValuePrompt(Object value) {
    return 'حذف القيمة $value?';
  }

  @override
  String get attributeDeleted => 'تم حذف الخاصية';

  @override
  String get valueDeleted => 'تم حذف القيمة';
}

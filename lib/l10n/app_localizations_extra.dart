import 'app_localizations.dart';

// Temporary extension providing additional localization keys that are staged
// in proposed ARB files but not yet integrated into the official gen-l10n
// workflow. Once ARB promotion occurs these getters should be removed in
// favor of generated ones.
extension AppLocalizationsExtra on AppLocalizations {
  bool get _isAr => localeName.startsWith('ar');

  String get rfidNotAvailableTitle => _isAr ? 'غير متاح' : 'Not Available';
  String get rfidNotAvailableMessage => _isAr
      ? 'قارئ RFID غير متوفر على هذه المنصة'
      : 'RFID reader not available on this platform';
  String get rfidDisabledTitle => _isAr ? 'غير مفعّل' : 'Disabled';
  String get rfidEnableInSettings => _isAr
      ? 'يرجى تفعيل RFID من الإعدادات أولاً'
      : 'Please enable RFID in settings first';
  String get rfidMockModeTitle => _isAr ? 'وضع تجريبي' : 'Mock Mode';
  String get rfidMockModeMessage => _isAr
      ? 'يتم تشغيل RFID بوضع محاكي بدون جهاز فعلي'
      : 'RFID is running in simulator mode without a physical device';
  String get rfidStop => _isAr ? 'إيقاف RFID' : 'Stop RFID';
  String get rfidStart => _isAr ? 'تشغيل RFID' : 'Start RFID';

  // Return screen temporary keys
  String get returnDoneTitle => _isAr ? 'تم' : 'Done';
  String get returnRecordedMessage =>
      _isAr ? 'تم تسجيل المرتجع' : 'Return has been recorded';
  String get returnSaleTitle => _isAr ? 'مرتجع بيع' : 'Sale Return';
  String get invoiceNumberHint => _isAr
      ? 'أدخل رقم الفاتورة ثم حمّل العناصر'
      : 'Enter invoice number then load items';
  String get loadItems => _isAr ? 'تحميل العناصر' : 'Load Items';
  String get returnReasonPlaceholder =>
      _isAr ? 'سبب المرتجع (اختياري)' : 'Return reason (optional)';
  String get saleItemRemainingTemplate => _isAr
      ? 'SaleItem {id} — المتبقي: {remaining} — السعر: {price}'
      : 'SaleItem {id} — Remaining: {remaining} — Price: {price}';

  // Users management temporary keys
  String get userNamePlaceholder => _isAr ? 'اسم المستخدم' : 'Username';
  String get fullNamePlaceholder => _isAr ? 'الاسم الكامل' : 'Full name';
  String get rolesTitle => _isAr ? 'الأدوار' : 'Roles';
  String get usersManagementTitle =>
      _isAr ? 'إدارة المستخدمين' : 'Users Management';
  String get update => _isAr ? 'تحديث' : 'Update';
  String get active => _isAr ? 'نشط' : 'Active';
  String get inactive => _isAr ? 'غير نشط' : 'Inactive';
  String get rolesLabel => _isAr ? 'الأدوار' : 'Roles';

  // Roles & permissions screen temporary
  String get newRoleTitle => _isAr ? 'دور جديد' : 'New Role';
  String get roleNamePlaceholder => _isAr ? 'اسم الدور' : 'Role name';
  String get editNameTitle => _isAr ? 'تعديل الاسم' : 'Edit Name';
  String permissionsTitle(String roleName) =>
      _isAr ? 'صلاحيات: $roleName' : 'Permissions: $roleName';
  String get rolesPermissionsTitle =>
      _isAr ? 'الأدوار و الصلاحيات' : 'Roles & Permissions';
  String get permissionsLabel => _isAr ? 'الصلاحيات' : 'Permissions';
  String get deleteRoleFailed => _isAr
      ? 'تعذر حذف الدور قد يكون مستخدماً'
      : 'Could not delete role; it may be in use';
  String deleteRoleConfirm(String role) =>
      _isAr ? 'حذف الدور "$role"؟' : 'Delete role "$role"?';

  // Store info preview / receipt header chips
  String get chooseLogo => _isAr ? 'اختيار شعار' : 'Choose Logo';
  String get changeLogo => _isAr ? 'تغيير الشعار' : 'Change Logo';
  String get headerItemsLabel =>
      _isAr ? 'عناصر تظهر في رأس الفاتورة:' : 'Items shown in receipt header:';
  String get logoLabel => _isAr ? 'الشعار' : 'Logo';
  String get shortSloganLabel => _isAr ? 'الشعار المختصر' : 'Short Slogan';
  String get taxIdLabel => _isAr ? 'الرقم الضريبي' : 'Tax ID';
  String get addressLabel => _isAr ? 'العنوان' : 'Address';
  String get phoneShortLabel => _isAr ? 'الهاتف' : 'Phone';
  String get receiptPreviewExperimental =>
      _isAr ? 'معاينة الفاتورة (تجريبية)' : 'Receipt Preview (Experimental)';
  String get largeImageTitle => _isAr ? 'حجم كبير' : 'Large Image';
  String get largeImageMessage => _isAr
      ? 'يرجى اختيار صورة أقل من 150KB للحصول على طباعة أسرع.'
      : 'Please choose an image < 150KB for faster printing.';
  String get testTotalLabel => _isAr ? 'إجمالي تجريبي' : 'Test Total';
  String get saveAndPreviewPdf =>
      _isAr ? 'حفظ + معاينة PDF' : 'Save + Preview PDF';
  String get phoneFormatTemplate => _isAr ? 'هاتف: {phone}' : 'Phone: {phone}';
  String get taxIdFormatTemplate =>
      _isAr ? 'الرقم الضريبي: {taxId}' : 'Tax ID: {taxId}';

  // New tabs & navigation
  String get expensesTab => _isAr ? 'المصروفات' : 'Expenses';
  String get stocktakeTab => _isAr ? 'الجرد' : 'Stocktake';

  // Product editor (temporary)
  String get productDataSection => _isAr ? 'بيانات المنتج' : 'Product Data';
  String get nameLabel => _isAr ? 'الاسم' : 'Name';
  String get descriptionLabel => _isAr ? 'الوصف' : 'Description';
  String get categoryLabel => _isAr ? 'الفئة' : 'Category';
  String get supplierLabelOptional =>
      _isAr ? 'المورد (اختياري)' : 'Supplier (optional)';
  String get brandLabelOptional =>
      _isAr ? 'العلامة التجارية (اختياري)' : 'Brand (optional)';
  String get variantsSection => _isAr
      ? 'المتغيرات (مقاس/لون/سعر/كمية)'
      : 'Variants (Size/Color/Price/Qty)';
  String get addVariant => _isAr ? 'إضافة متغير' : 'Add Variant';
  String get pickCategoryTitle => _isAr ? 'اختر الفئة' : 'Choose category';
  String get addCategoryTitle => _isAr ? 'إضافة فئة جديدة' : 'Add New Category';
  String get categoryNamePlaceholder => _isAr ? 'اسم الفئة' : 'Category name';
  String get pickSupplierTitle => _isAr ? 'اختر المورد' : 'Choose supplier';
  String get addSupplierTitle => _isAr ? 'إضافة مورد جديد' : 'Add New Supplier';
  String get supplierNamePlaceholder => _isAr ? 'اسم المورد' : 'Supplier name';
  String get pickBrandTitle => _isAr ? 'اختر العلامة التجارية' : 'Choose brand';
  String get addBrandTitle => _isAr ? 'إضافة علامة تجارية' : 'Add New Brand';
  String get brandNamePlaceholder => _isAr ? 'اسم العلامة' : 'Brand name';
  String get pickSizeTitle => _isAr ? 'اختر المقاس' : 'Choose size';
  String get addSizeTitle => _isAr ? 'إضافة مقاس' : 'Add Size';
  String get sizeExamplePlaceholder => _isAr ? 'مثال: XXL' : 'Example: XXL';
  String get pickColorTitle => _isAr ? 'اختر اللون' : 'Choose color';
  String get addColorTitle => _isAr ? 'إضافة لون' : 'Add Color';
  String get colorExamplePlaceholder =>
      _isAr ? 'مثال: بنفسجي' : 'Example: Purple';
  String get clearValue => _isAr ? 'مسح القيمة' : 'Clear value';
  String get addNew => _isAr ? 'إضافة جديد' : 'Add New';
  String get clearSelection => _isAr ? 'مسح الاختيار' : 'Clear selection';
  String get variantLabel => _isAr ? 'متغير' : 'Variant';
  String get delete => _isAr ? 'حذف' : 'Delete';
  String get sizeLabel => _isAr ? 'المقاس' : 'Size';
  String get colorLabel => _isAr ? 'اللون' : 'Color';
  String get costLabel => _isAr ? 'التكلفة' : 'Cost';
  String get saleLabel => _isAr ? 'البيع' : 'Sale';
  String get quantityLabel => _isAr ? 'الكمية' : 'Quantity';
  String get reorderPointLabel => _isAr ? 'حد إعادة الطلب' : 'Reorder Point';

  // Product editor validation & misc
  String get requiredNameError => _isAr ? 'الاسم مطلوب' : 'Name is required';
  String get selectCategoryError =>
      _isAr ? 'يجب اختيار الفئة' : 'Category must be selected';
  String get skuRequiredVariant =>
      _isAr ? 'SKU مطلوب لكل متغير' : 'SKU required for each variant';
  String saveFailed(String error) =>
      _isAr ? 'فشل الحفظ: $error' : 'Save failed: $error';
  String get productEditorTitle => _isAr ? 'محرر المنتج' : 'Product Editor';
  String get productNamePlaceholder => _isAr ? 'اسم المنتج' : 'Product name';
  String get productDescPlaceholder =>
      _isAr ? 'وصف (اختياري)' : 'Description (optional)';
  String get chooseCategoryPlaceholder =>
      _isAr ? 'اختر الفئة' : 'Choose category';

  // Store info missing placeholders (temporary until ARB promotion)
  String get taxIdPlaceholder =>
      _isAr ? 'الرقم الضريبي (اختياري)' : 'Tax ID (optional)';
  String get thanksMessagePlaceholder =>
      _isAr ? 'رسالة الشكر في التذييل' : 'Thanks message at footer';

  // Settings home restricted note & manage users title (already partly generated later)
  String get restrictedNoManage => _isAr
      ? 'مقيد: لا تملك صلاحية الإدارة'
      : "Restricted: you don't have management permission";
  String get manageUsersTitle => _isAr ? 'إدارة المستخدمين' : 'Manage Users';

  // Purchase editor view-only banner
  String get purchaseEditorViewOnlyWarning => _isAr
      ? 'عرض فقط: لا تملك صلاحية إنشاء/تعديل فواتير المشتريات'
      : 'View only: no permission to create/edit purchase invoices';

  // Inventory / Expenses temporary keys
  String get viewOnlyAdjustStock => _isAr
      ? 'عرض فقط: لا تملك صلاحية تعديل المخزون'
      : 'View only: no permission to adjust stock';
  String get viewOnlyRecordExpenses => _isAr
      ? 'عرض فقط: لا تملك صلاحية تسجيل المصروفات'
      : 'View only: no permission to record expenses';
  String get addProduct => _isAr ? 'إضافة صنف' : 'Add Product';
  String get purchases => _isAr ? 'المشتريات' : 'Purchases';
  String get add => _isAr ? 'إضافة' : 'Add';
  String get searchProductsPlaceholder =>
      _isAr ? 'بحث عن الأصناف...' : 'Search products...';
  String get select => _isAr ? 'اختر' : 'Select';
  String get scanErrorTitle => _isAr ? 'خطأ المسح' : 'Scan Error';
  String get filterAll => _isAr ? 'الكل' : 'All';
  String get categoryTitle => _isAr ? 'الفئة' : 'Category';
  String get paymentMethodTitle => _isAr ? 'طريقة الدفع' : 'Payment Method';
  String get allMethods => _isAr ? 'كل الطرق' : 'All methods';
  String get cashShort => _isAr ? 'نقد' : 'Cash';
  String get bankShort => _isAr ? 'بنكي' : 'Bank';
  String get otherShort => _isAr ? 'أخرى' : 'Other';
  String get fromLabel => _isAr ? 'من' : 'From';
  String get toLabel => _isAr ? 'إلى' : 'To';
  String get totalLabelExpenses => _isAr ? 'الإجمالي:' : 'Total:';
  String get noData => _isAr ? 'لا توجد بيانات' : 'No data';
  String get deleteExpenseConfirm =>
      _isAr ? 'تأكيد حذف المصروف؟' : 'Confirm delete expense?';
  String get deleteTitle => _isAr ? 'حذف' : 'Delete';
  String get newExpenseTitle => _isAr ? 'مصروف جديد' : 'New Expense';
  String get editExpenseTitle => _isAr ? 'تعديل مصروف' : 'Edit Expense';
  String get amountPlaceholder => _isAr ? 'المبلغ' : 'Amount';
  String get dateLabel => _isAr ? 'التاريخ:' : 'Date:';
  String get descriptionOptional =>
      _isAr ? 'وصف (اختياري)' : 'Description (optional)';
  String get updateAction => _isAr ? 'تحديث' : 'Update';
  String get chooseCategory => _isAr ? 'اختر الفئة' : 'Choose category';
  String get pickAction => _isAr ? 'اختر' : 'Pick';
  String get filterClear => _isAr ? 'مسح المرشحات' : 'Clear filters';
}

class ChecklistItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? iconName;
  final String? helpLink;
  final int difficulty; // 1-3 (سهل، متوسط، متقدم)
  bool isDone;

  ChecklistItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.iconName,
    this.helpLink,
    this.difficulty = 1,
    this.isDone = false,
  });
  
  // نسخة جديدة من العنصر مع تحديث حالة الإنجاز
  ChecklistItem copyWith({bool? isDone}) {
    return ChecklistItem(
      id: id,
      title: title,
      description: description,
      category: category,
      iconName: iconName,
      helpLink: helpLink,
      difficulty: difficulty,
      isDone: isDone ?? this.isDone,
    );
  }
}

// فئات قائمة البدء السريعة
const String categoryBasics = 'أساسيات';
const String categoryInventory = 'المخزون';
const String categorySales = 'المبيعات';
const String categoryFinance = 'المالية';
const String categoryReports = 'التقارير';
const String categoryAdvanced = 'متقدم';

final List<ChecklistItem> checklistItems = [
  // أساسيات
  ChecklistItem(
    id: 'setup_store',
    title: 'إعداد معلومات المتجر',
    description: 'أدخل اسم متجرك وشعاره ومعلومات الاتصال في إعدادات النظام.',
    category: categoryBasics,
    iconName: 'store',
    difficulty: 1,
  ),
  ChecklistItem(
    id: 'add_user',
    title: 'إضافة مستخدم',
    description: 'أضف مستخدمًا جديدًا للنظام وحدد صلاحياته.',
    category: categoryBasics,
    iconName: 'person_add',
    difficulty: 1,
  ),
  ChecklistItem(
    id: 'setup_printer',
    title: 'إعداد الطابعة',
    description: 'قم بإعداد الطابعة لتتمكن من طباعة الفواتير والتقارير.',
    category: categoryBasics,
    iconName: 'print',
    difficulty: 1,
  ),
  
  // المخزون
  ChecklistItem(
    id: 'add_category',
    title: 'إنشاء تصنيف للمنتجات',
    description: 'أنشئ تصنيفًا واحدًا على الأقل لتنظيم منتجاتك.',
    category: categoryInventory,
    iconName: 'category',
    difficulty: 1,
  ),
  ChecklistItem(
    id: 'add_product',
    title: 'إضافة منتج',
    description: 'أضف منتجًا واحدًا على الأقل إلى مخزونك لتبدأ البيع.',
    category: categoryInventory,
    iconName: 'inventory',
    difficulty: 1,
  ),
  ChecklistItem(
    id: 'add_supplier',
    title: 'إضافة مورّد',
    description: 'أضف بيانات مورّد واحد على الأقل لمنتجاتك.',
    category: categoryInventory,
    iconName: 'local_shipping',
    difficulty: 1,
  ),
  ChecklistItem(
    id: 'stock_adjustment',
    title: 'إجراء تعديل على المخزون',
    description: 'قم بتعديل كمية أحد المنتجات في المخزون.',
    category: categoryInventory,
    iconName: 'edit',
    difficulty: 2,
  ),
  ChecklistItem(
    id: 'import_products',
    title: 'استيراد المنتجات',
    description: 'قم باستيراد قائمة المنتجات من ملف Excel أو CSV.',
    category: categoryInventory,
    iconName: 'upload',
    difficulty: 3,
  ),
  
  // المبيعات
  ChecklistItem(
    id: 'open_cash_session',
    title: 'فتح جلسة صندوق',
    description: 'افتح جلسة صندوق جديدة لتسجيل المبيعات النقدية.',
    category: categorySales,
    iconName: 'point_of_sale',
    difficulty: 1,
  ),
  ChecklistItem(
    id: 'make_sale',
    title: 'إجراء عملية بيع',
    description: 'قم ببيع منتج من خلال واجهة نقاط البيع.',
    category: categorySales,
    iconName: 'shopping_cart',
    difficulty: 1,
  ),
  ChecklistItem(
    id: 'apply_discount',
    title: 'تطبيق خصم',
    description: 'طبق خصمًا على إحدى عمليات البيع.',
    category: categorySales,
    iconName: 'discount',
    difficulty: 2,
  ),
  ChecklistItem(
    id: 'process_return',
    title: 'معالجة مرتجع',
    description: 'قم بمعالجة عملية إرجاع منتج.',
    category: categorySales,
    iconName: 'assignment_return',
    difficulty: 2,
  ),
  ChecklistItem(
    id: 'split_payment',
    title: 'تقسيم طرق الدفع',
    description: 'قم ببيع منتج وتقسيم الدفع بين عدة طرق (نقد، كredit، إلخ).',
    category: categorySales,
    iconName: 'credit_card',
    difficulty: 2,
  ),
  
  // المالية
  ChecklistItem(
    id: 'add_expense',
    title: 'إضافة مصروف',
    description: 'سجل مصروفًا لتتبع نفقاتك.',
    category: categoryFinance,
    iconName: 'payments',
    difficulty: 1,
  ),
  ChecklistItem(
    id: 'close_cash_session',
    title: 'إغلاق جلسة صندوق',
    description: 'أغلق جلسة الصندوق وتأكد من تطابق الرصيد.',
    category: categoryFinance,
    iconName: 'account_balance',
    difficulty: 1,
  ),
  ChecklistItem(
    id: 'cash_variance_report',
    title: 'تقرير فرق الصندوق',
    description: 'اعرض تقرير فرق الصندوق لتحديد أي اختلافات في الرصيد.',
    category: categoryFinance,
    iconName: 'report',
    difficulty: 2,
  ),
  
  // التقارير
  ChecklistItem(
    id: 'view_sales_report',
    title: 'عرض تقرير المبيعات',
    description: 'اعرض تقرير المبيعات اليومي وتعرف على أدائك.',
    category: categoryReports,
    iconName: 'bar_chart',
    difficulty: 1,
  ),
  ChecklistItem(
    id: 'view_inventory_report',
    title: 'عرض تقرير المخزون',
    description: 'تحقق من تقرير المخزون لمعرفة المنتجات منخفضة الكمية.',
    category: categoryReports,
    iconName: 'inventory_2',
    difficulty: 1,
  ),
  ChecklistItem(
    id: 'export_report',
    title: 'تصدير تقرير',
    description: 'قم بتصدير أحد التقارير إلى ملف Excel أو PDF.',
    category: categoryReports,
    iconName: 'download',
    difficulty: 2,
  ),
  
  // متقدم
  ChecklistItem(
    id: 'setup_ai_assistant',
    title: 'إعداد المساعد الذكي',
    description: 'قم بتفعيل وإعداد المساعد الذكي للمساعدة في إدارة متجرك.',
    category: categoryAdvanced,
    iconName: 'smart_toy',
    difficulty: 3,
  ),
  ChecklistItem(
    id: 'create_backup',
    title: 'إنشاء نسخة احتياطية',
    description: 'قم بإنشاء نسخة احتياطية من بيانات متجرك للحفاظ عليها.',
    category: categoryAdvanced,
    iconName: 'backup',
    difficulty: 2,
  ),
  ChecklistItem(
    id: 'schedule_report',
    title: 'جدولة تقرير',
    description: 'قم بجدولة إرسال تقرير تلقائيًا عبر البريد الإلكتروني.',
    category: categoryAdvanced,
    iconName: 'schedule',
    difficulty: 3,
  ),
  ChecklistItem(
    id: 'setup_rfid',
    title: 'إعداد قارئ RFID',
    description: 'قم بتوصيل وتهيئة قارئ RFID لتسريع عمليات المخزون.',
    category: categoryAdvanced,
    iconName: 'rfid',
    difficulty: 3,
  ),
];

// الحصول على نسبة إكمال المهام حسب الفئة
double getCategoryCompletionPercentage(String category) {
  final categoryItems = checklistItems.where((item) => item.category == category).toList();
  if (categoryItems.isEmpty) return 0.0;
  
  final completedItems = categoryItems.where((item) => item.isDone).length;
  return completedItems / categoryItems.length;
}

// الحصول على نسبة الإكمال الإجمالية
double getTotalCompletionPercentage() {
  if (checklistItems.isEmpty) return 0.0;
  
  final completedItems = checklistItems.where((item) => item.isDone).length;
  return completedItems / checklistItems.length;
}
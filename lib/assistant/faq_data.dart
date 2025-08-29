// Simple Arabic FAQ knowledge base and matching logic
// No external dependencies; pure Dart.

class KeywordSpec {
  final String keyword; // raw term (will be normalized)
  final double weight; // importance weight
  const KeywordSpec(this.keyword, {this.weight = 1.0});
}

class FaqEntry {
  final String id;
  final String question;
  final String answer;
  final String? category;
  final String? iconName; // اسم الأيقونة المرتبطة بالسؤال
  final List<String>? relatedQuestions; // أسئلة ذات صلة
  final List<KeywordSpec>? keywords; // weighted keywords
  final bool isPopular; // هل هو سؤال شائع
  final String? imageUrl; // رابط الصورة التوضيحية

  const FaqEntry({
    required this.id,
    required this.question,
    required this.answer,
    this.category,
    this.iconName,
    this.relatedQuestions,
    this.keywords,
    this.isPopular = false,
    this.imageUrl,
  });
}

// Basic Arabic normalization to improve keyword matching
String normalizeArabic(String input) {
  var s = input;
  // Lowercase
  s = s.toLowerCase();
  // Remove diacritics (tashkeel) and tatweel (kashida)
  s = s.replaceAll(RegExp('[\u064B-\u0652\u0670\u0640]'), '');
  // Unify alef forms
  s = s.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا');
  // Unify taa marbuta and alef maqsura
  s = s.replaceAll('ة', 'ه').replaceAll('ى', 'ي');
  // Remove punctuation and non-Arabic letters (keep spaces and digits)
  s = s.replaceAll(RegExp('[^\u0621-\u064A0-9 ]'), ' ');
  // Collapse extra whitespace
  s = s.replaceAll(RegExp(' +'), ' ').trim();
  return s;
}

// فئات الأسئلة الشائعة
const String categoryInvoices = 'الفواتير والمبيعات';
const String categoryExpenses = 'المصروفات';
const String categorySettings = 'الإعدادات والبيانات';
const String categoryInventory = 'المنتجات والمخزون';
const String categoryReports = 'التقارير';
const String categoryCustomers = 'العملاء';
const String categorySuppliers = 'الموردين';
const String categoryAI = 'الذكاء الاصطناعي';

// قاعدة بيانات الأسئلة الشائعة (بالعربية). يمكن إضافة المزيد من الأسئلة حسب الحاجة.
const List<FaqEntry> _faq = [
  // فئة الفواتير والمبيعات
  FaqEntry(
    id: 'invoice_create',
    question: 'كيف تنشئ فاتورة؟',
    category: categoryInvoices,
    iconName: 'receipt',
    isPopular: true,
    answer:
        'من تبويب المبيعات (POS)، أضف العناصر إلى السلة ثم اضغط زر إتمام البيع واختر وسيلة الدفع لحفظ الفاتورة.',
    relatedQuestions: ['print_receipt', 'invoice_discount', 'invoice_cancel'],
    keywords: [
      KeywordSpec('فاتوره', weight: 1.2),
      KeywordSpec('فاتورة', weight: 1.2),
      KeywordSpec('بيع', weight: 1.0),
      KeywordSpec('انشاء', weight: 1.0),
      KeywordSpec('سلة', weight: 0.8),
    ],
    imageUrl: 'assets/images/faq/create_invoice.svg',
  ),
  FaqEntry(
    id: 'print_receipt',
    question: 'كيف أطبع فاتورة؟',
    category: categoryInvoices,
    iconName: 'print',
    answer:
        'بعد حفظ البيع، يمكنك طباعة الإيصال من شاشة إتمام البيع أو من تقارير المبيعات لاحقاً.',
    relatedQuestions: ['invoice_create', 'invoice_find'],
    keywords: [
      KeywordSpec('طباعه', weight: 1.1),
      KeywordSpec('طباعة', weight: 1.1),
      KeywordSpec('فاتوره', weight: 1.0),
      KeywordSpec('ايصال', weight: 1.0),
      KeywordSpec('رسيد', weight: 0.7),
    ],
    imageUrl: 'assets/images/faq/print_receipt.svg',
  ),
  FaqEntry(
    id: 'open_cash_session',
    question: 'كيف أفتح جلسة صندوق؟',
    category: categoryInvoices,
    iconName: 'point_of_sale',
    answer:
        'سيُطلب منك فتح جلسة صندوق عند أول عملية بيع. أدخل الرصيد الافتتاحي لتبدأ الجلسة.',
    relatedQuestions: ['close_cash_session'],
    keywords: [
      KeywordSpec('جلسه', weight: 1.0),
      KeywordSpec('صندوق', weight: 1.0),
      KeywordSpec('فتح', weight: 0.8),
      KeywordSpec('رصيد افتتاحي', weight: 0.8),
    ],
    imageUrl: 'assets/images/faq/open_cash_session.svg',
  ),
  FaqEntry(
    id: 'close_cash_session',
    question: 'كيف أغلق جلسة صندوق؟',
    category: categoryInvoices,
    iconName: 'point_of_sale',
    answer:
        'من شاشة الصندوق، اضغط على "إغلاق الجلسة" وأدخل المبلغ الفعلي في الصندوق لمطابقة الحسابات.',
    relatedQuestions: ['open_cash_session'],
    keywords: [
      KeywordSpec('اغلاق', weight: 1.0),
      KeywordSpec('جلسة', weight: 1.0),
      KeywordSpec('صندوق', weight: 1.0),
      KeywordSpec('مطابقة', weight: 0.7),
    ],
    imageUrl: 'assets/images/faq/close_cash_session.svg',
  ),
  FaqEntry(
    id: 'invoice_discount',
    question: 'كيف أضيف خصم على الفاتورة؟',
    category: categoryInvoices,
    iconName: 'percent',
    answer:
        'أثناء إنشاء الفاتورة، يمكنك إضافة خصم على العنصر الواحد أو على إجمالي الفاتورة من خيارات الخصم.',
    relatedQuestions: ['invoice_create'],
    keywords: [
      KeywordSpec('خصم', weight: 1.2),
      KeywordSpec('تخفيض', weight: 1.0),
      KeywordSpec('فاتورة', weight: 0.8),
    ],
    imageUrl: 'assets/images/faq/add_discount.svg',
  ),

  // فئة المصروفات
  FaqEntry(
    id: 'expense_add',
    question: 'كيف أضيف مصروف؟',
    category: categoryExpenses,
    iconName: 'payments',
    isPopular: true,
    answer:
        'من الإعدادات > المصروفات، اضغط علامة + لإضافة مصروف جديد وحدد الفئة والمبلغ والوصف ثم احفظ.',
    relatedQuestions: ['expense_categories', 'expense_report'],
    keywords: [
      KeywordSpec('مصروف', weight: 1.3),
      KeywordSpec('اضافه', weight: 1.0),
      KeywordSpec('ادخال', weight: 1.0),
      KeywordSpec('ادخل', weight: 1.0),
      KeywordSpec('صرف', weight: 0.8),
      KeywordSpec('فاتوره مصروف', weight: 0.6),
    ],
    imageUrl: 'assets/images/faq/add_expense.svg',
  ),

  // فئة الإعدادات والبيانات
  FaqEntry(
    id: 'backup_now',
    question: 'كيف أعمل نسخة احتياطية؟',
    category: categorySettings,
    iconName: 'backup',
    isPopular: true,
    answer:
        'اذهب إلى الإعدادات > قاعدة البيانات، واختر "نسخ احتياطي الآن" لإنشاء نسخة احتياطية فورية.',
    relatedQuestions: ['restore_backup'],
    keywords: [
      KeywordSpec('نسخه', weight: 1.0),
      KeywordSpec('احتياطي', weight: 1.0),
      KeywordSpec('باك', weight: 0.8),
      KeywordSpec('backup', weight: 0.9),
      KeywordSpec('حفظ البيانات', weight: 0.7),
    ],
    imageUrl: 'assets/images/faq/backup_data.svg',
  ),

  // فئة المنتجات والمخزون
  FaqEntry(
    id: 'add_product',
    question: 'كيف أضيف منتج جديد؟',
    category: categoryInventory,
    iconName: 'inventory',
    isPopular: true,
    answer:
        'من تبويب المخزون، افتح شاشة إدارة المنتجات ثم اضغط إضافة منتج وحدد التفاصيل واحفظ.',
    relatedQuestions: ['edit_product', 'product_barcode'],
    keywords: [
      KeywordSpec('منتج', weight: 1.2),
      KeywordSpec('اضافه منتج', weight: 1.0),
      KeywordSpec('صنف جديد', weight: 1.0),
      KeywordSpec('ادارة المنتجات', weight: 0.8),
    ],
    imageUrl: 'assets/images/faq/add_product.svg',
  ),

  // فئة التقارير
  FaqEntry(
    id: 'sales_report',
    question: 'كيف أعرض تقرير المبيعات؟',
    category: categoryReports,
    iconName: 'analytics',
    answer:
        'من تبويب التقارير، اختر "تقرير المبيعات" وحدد الفترة الزمنية المطلوبة لعرض التقرير.',
    keywords: [
      KeywordSpec('تقرير', weight: 1.2),
      KeywordSpec('مبيعات', weight: 1.0),
      KeywordSpec('احصائيات', weight: 0.8),
    ],
    imageUrl: 'assets/images/faq/sales_report.svg',
  ),

  // فئة الذكاء الاصطناعي
  FaqEntry(
    id: 'ai_setup',
    question: 'كيف أعد المساعد الذكي؟',
    category: categoryAI,
    iconName: 'smart_toy',
    answer:
        'من الإعدادات > الذكاء الاصطناعي، أدخل مفتاح API الخاص بك واختر النموذج المناسب ثم احفظ الإعدادات.',
    keywords: [
      KeywordSpec('ذكاء', weight: 1.2),
      KeywordSpec('اصطناعي', weight: 1.0),
      KeywordSpec('مساعد', weight: 0.8),
      KeywordSpec('اعداد', weight: 0.7),
    ],
    imageUrl: 'assets/images/faq/setup_ai_assistant.svg',
  ),

  // فئة العملاء
  FaqEntry(
    id: 'add_customer',
    question: 'كيف أضيف عميل جديد؟',
    category: categoryCustomers,
    iconName: 'person_add',
    answer:
        'من تبويب العملاء، اضغط على زر + لإضافة عميل جديد وأدخل بياناته الأساسية مثل الاسم ورقم الهاتف.',
    keywords: [
      KeywordSpec('عميل', weight: 1.2),
      KeywordSpec('زبون', weight: 1.0),
      KeywordSpec('اضافة', weight: 0.8),
      KeywordSpec('جديد', weight: 0.7),
    ],
    imageUrl: 'assets/images/faq/add_customer.svg',
  ),

  // فئة الموردين
  FaqEntry(
    id: 'add_supplier',
    question: 'كيف أضيف مورد جديد؟',
    category: categorySuppliers,
    iconName: 'local_shipping',
    answer:
        'من تبويب الموردين، اضغط على زر + لإضافة مورد جديد وأدخل بياناته الأساسية مثل الاسم وتفاصيل الاتصال.',
    keywords: [
      KeywordSpec('مورد', weight: 1.2),
      KeywordSpec('موردين', weight: 1.0),
      KeywordSpec('اضافة', weight: 0.8),
      KeywordSpec('جديد', weight: 0.7),
    ],
    imageUrl: 'assets/images/faq/add_supplier.svg',
  ),
];

// --- Matching helpers ---

const _stopWords = <String>{
  'في',
  'على',
  'من',
  'الى',
  'إلى',
  'عن',
  'ما',
  'ماذا',
  'كيف',
  'هل',
  'ثم',
  'او',
  'أو',
  'مع',
  'تم',
  'هو',
  'هي',
  'هذا',
  'هذه',
  'ذلك',
  'تلك',
  'ال',
  'أن',
  'إن',
  'لقد',
  'قد',
  'كما',
  'بعد',
  'قبل',
  'اذا',
  'إذا',
  'عند',
  'عندي',
  'عندك',
  'كان',
  'كانت',
};

Iterable<String> _tokenize(String text) sync* {
  for (final w in text.split(' ')) {
    final t = w.trim();
    if (t.isEmpty) continue;
    if (_stopWords.contains(t)) continue;
    yield t;
  }
}

String _lightStem(String word) {
  // Simple Arabic light stemming (remove common suffixes)
  if (word.endsWith('ات')) return word.substring(0, word.length - 2);
  if (word.endsWith('ان')) return word.substring(0, word.length - 2);
  if (word.endsWith('ين')) return word.substring(0, word.length - 2);
  if (word.endsWith('ون')) return word.substring(0, word.length - 2);
  if (word.endsWith('ها')) return word.substring(0, word.length - 2);
  if (word.endsWith('هم')) return word.substring(0, word.length - 2);
  if (word.endsWith('هن')) return word.substring(0, word.length - 2);
  return word;
}

Iterable<String> _charNGrams(String s, int n) sync* {
  if (s.length < n) return;
  for (int i = 0; i <= s.length - n; i++) {
    yield s.substring(i, i + n);
  }
}

class FaqMatcherResult {
  final FaqEntry? entry;
  final double score;
  final String normalizedInput;

  const FaqMatcherResult({
    this.entry,
    required this.score,
    required this.normalizedInput,
  });
}

FaqMatcherResult matchFaq(String userText, {double threshold = 0.45}) {
  final norm = normalizeArabic(userText);
  if (norm.isEmpty) {
    return FaqMatcherResult(entry: null, score: 0, normalizedInput: norm);
  }

  final userTokens = _tokenize(norm).map(_lightStem).toSet();
  if (userTokens.isEmpty) {
    return FaqMatcherResult(entry: null, score: 0, normalizedInput: norm);
  }

  FaqEntry? bestMatch;
  double bestScore = 0;

  for (final faq in _faq) {
    double score = 0;

    // Check question match
    final questionTokens = _tokenize(
      normalizeArabic(faq.question),
    ).map(_lightStem).toSet();
    final questionOverlap = userTokens.intersection(questionTokens).length;
    if (questionOverlap > 0) {
      score += (questionOverlap / userTokens.length) * 0.6;
    }

    // Check keywords match
    if (faq.keywords != null) {
      for (final keyword in faq.keywords!) {
        final keywordTokens = _tokenize(
          normalizeArabic(keyword.keyword),
        ).map(_lightStem).toSet();
        final keywordOverlap = userTokens.intersection(keywordTokens).length;
        if (keywordOverlap > 0) {
          score += (keywordOverlap / userTokens.length) * keyword.weight * 0.4;
        }
      }
    }

    // Character n-gram similarity for fuzzy matching
    final userNGrams = _charNGrams(norm, 3).toSet();
    final questionNGrams = _charNGrams(
      normalizeArabic(faq.question),
      3,
    ).toSet();
    final ngramOverlap = userNGrams.intersection(questionNGrams).length;
    if (ngramOverlap > 0 && userNGrams.isNotEmpty) {
      score += (ngramOverlap / userNGrams.length) * 0.2;
    }

    if (score > bestScore) {
      bestScore = score;
      bestMatch = faq;
    }
  }

  return FaqMatcherResult(
    entry: bestScore >= threshold ? bestMatch : null,
    score: bestScore,
    normalizedInput: norm,
  );
}

// Public API functions
List<FaqEntry> allFaq() => List.unmodifiable(_faq);

List<FaqEntry> getFaqByCategory(String category) {
  return _faq.where((faq) => faq.category == category).toList();
}

List<FaqEntry> getPopularFaq() {
  return _faq.where((faq) => faq.isPopular).toList();
}

List<FaqEntry> getRelatedFaq(String faqId) {
  final faq = _faq.where((f) => f.id == faqId).firstOrNull;
  if (faq?.relatedQuestions == null || faq!.relatedQuestions!.isEmpty) {
    return [];
  }
  return _faq.where((f) => faq.relatedQuestions!.contains(f.id)).toList();
}

List<String> getAllFaqCategories() {
  return _faq.map((faq) => faq.category).whereType<String>().toSet().toList()
    ..sort();
}

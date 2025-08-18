// Simple Arabic FAQ knowledge base and matching logic
// No external dependencies; pure Dart.

class KeywordSpec {
  final String term; // raw term (will be normalized)
  final double weight; // importance weight
  const KeywordSpec(this.term, {this.weight = 1.0});
}

class FaqEntry {
  final String id;
  final String question;
  final String answer;
  final String? category;
  final List<KeywordSpec> keywords; // weighted keywords
  const FaqEntry({
    required this.id,
    required this.question,
    required this.answer,
    this.category,
    required this.keywords,
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

// Small curated KB (Arabic). Add more entries as needed.
const List<FaqEntry> _faq = [
  FaqEntry(
    id: 'invoice_create',
    question: 'كيف تنشئ فاتورة؟',
    category: 'الفواتير والمبيعات',
    answer:
        'من تبويب المبيعات (POS)، أضف العناصر إلى السلة ثم اضغط زر إتمام البيع واختر وسيلة الدفع لحفظ الفاتورة.',
    keywords: [
      KeywordSpec('فاتوره', weight: 1.2),
      KeywordSpec('فاتورة', weight: 1.2),
      KeywordSpec('بيع', weight: 1.0),
      KeywordSpec('انشاء', weight: 1.0),
      KeywordSpec('سلة', weight: 0.8),
    ],
  ),
  FaqEntry(
    id: 'expense_add',
    question: 'كيف تدخل مصروف؟',
    category: 'المصروفات',
    answer:
        'من الإعدادات > المصروفات، اضغط علامة + لإضافة مصروف جديد وحدد الفئة والمبلغ والوصف ثم احفظ.',
    keywords: [
      KeywordSpec('مصروف', weight: 1.3),
      KeywordSpec('اضافه', weight: 1.0),
      KeywordSpec('ادخال', weight: 1.0),
      KeywordSpec('ادخل', weight: 1.0),
      KeywordSpec('صرف', weight: 0.8),
      KeywordSpec('فاتوره مصروف', weight: 0.6),
    ],
  ),
  FaqEntry(
    id: 'backup_now',
    question: 'كيف أعمل نسخة احتياطية؟',
    category: 'الإعدادات والبيانات',
    answer:
        'اذهب إلى الإعدادات > قاعدة البيانات، واختر "نسخ احتياطي الآن" لإنشاء نسخة احتياطية فورية.',
    keywords: [
      KeywordSpec('نسخه', weight: 1.0),
      KeywordSpec('احتياطي', weight: 1.0),
      KeywordSpec('باك', weight: 0.8),
      KeywordSpec('backup', weight: 0.9),
      KeywordSpec('حفظ البيانات', weight: 0.7),
    ],
  ),
  FaqEntry(
    id: 'print_receipt',
    question: 'كيف أطبع فاتورة؟',
    category: 'الفواتير والمبيعات',
    answer:
        'بعد حفظ البيع، يمكنك طباعة الإيصال من شاشة إتمام البيع أو من تقارير المبيعات لاحقاً.',
    keywords: [
      KeywordSpec('طباعه', weight: 1.1),
      KeywordSpec('طباعة', weight: 1.1),
      KeywordSpec('فاتوره', weight: 1.0),
      KeywordSpec('ايصال', weight: 1.0),
      KeywordSpec('رسيد', weight: 0.7),
    ],
  ),
  FaqEntry(
    id: 'add_product',
    question: 'كيف أضيف منتج جديد؟',
    category: 'المنتجات والمخزون',
    answer:
        'من تبويب المخزون، افتح شاشة إدارة المنتجات ثم اضغط إضافة منتج وحدد التفاصيل واحفظ.',
    keywords: [
      KeywordSpec('منتج', weight: 1.2),
      KeywordSpec('اضافه منتج', weight: 1.0),
      KeywordSpec('صنف جديد', weight: 1.0),
      KeywordSpec('ادارة المنتجات', weight: 0.8),
    ],
  ),
  FaqEntry(
    id: 'open_cash_session',
    question: 'كيف أفتح جلسة صندوق؟',
    category: 'الفواتير والمبيعات',
    answer:
        'سيُطلب منك فتح جلسة صندوق عند أول عملية بيع. أدخل الرصيد الافتتاحي لتبدأ الجلسة.',
    keywords: [
      KeywordSpec('جلسه', weight: 1.0),
      KeywordSpec('صندوق', weight: 1.0),
      KeywordSpec('فتح', weight: 0.8),
      KeywordSpec('رصيد افتتاحي', weight: 0.8),
    ],
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

String _lightStem(String token) {
  var t = token;
  // Remove Arabic definite article "ال" prefix when appropriate
  if (t.length > 3 && t.startsWith('ال')) t = t.substring(2);
  // Remove common prefixes
  for (final p in ['و', 'ف', 'ب', 'ك', 'ل']) {
    if (t.length > 3 && t.startsWith(p)) {
      t = t.substring(1);
    }
  }
  // Remove common suffixes
  for (final s in ['ه', 'ها', 'هم', 'كما', 'كم', 'نا', 'ون', 'ين', 'ات', 'ة']) {
    if (t.length > s.length + 1 && t.endsWith(s)) {
      t = t.substring(0, t.length - s.length);
    }
  }
  return t;
}

Iterable<String> _charNGrams(String s, int n) sync* {
  if (s.length < n) return;
  for (int i = 0; i <= s.length - n; i++) {
    yield s.substring(i, i + n);
  }
}

class FaqMatcherResult {
  final FaqEntry? entry;
  final double score; // 0..1 simple heuristic
  final String normalizedInput;
  const FaqMatcherResult({
    this.entry,
    required this.score,
    required this.normalizedInput,
  });
}

// Weighted composite matcher: keyword weights + token overlap + char n-grams (3)
FaqMatcherResult matchFaq(String userText, {double threshold = 0.45}) {
  final norm = normalizeArabic(userText);
  if (norm.isEmpty) {
    return FaqMatcherResult(entry: null, score: 0, normalizedInput: norm);
  }
  // Tokenization with stop words removal & light stemming
  final tokens = _tokenize(norm).map(_lightStem).toList();
  final tokenSet = tokens.toSet();
  final grams = _charNGrams(norm, 3).toSet();

  double bestScore = 0;
  FaqEntry? best;
  for (final e in _faq) {
    // 1) Weighted keyword score
    double kwScore = 0;
    double kwTotal = 0;
    for (final kw in e.keywords) {
      final kwNorm = normalizeArabic(kw.term);
      kwTotal += kw.weight;
      if (kwNorm.isEmpty) continue;
      if (norm.contains(kwNorm)) {
        kwScore += kw.weight;
      }
    }
    final kwPart = kwTotal == 0 ? 0.0 : (kwScore / kwTotal);

    // 2) Token overlap (Jaccard)
    final qTokens = _tokenize(
      normalizeArabic(e.question),
    ).map(_lightStem).toSet();
    final inter = tokenSet.intersection(qTokens).length.toDouble();
    final union = tokenSet.union(qTokens).length.toDouble();
    final tokenPart = union == 0 ? 0.0 : inter / union;

    // 3) Char 3-gram Jaccard between input and question
    final eGrams = _charNGrams(normalizeArabic(e.question), 3).toSet();
    final gInter = grams.intersection(eGrams).length.toDouble();
    final gUnion = grams.union(eGrams).length.toDouble();
    final gramPart = gUnion == 0 ? 0.0 : gInter / gUnion;

    // Composite score with weights
    final score = (0.5 * kwPart) + (0.3 * tokenPart) + (0.2 * gramPart);
    if (score > bestScore) {
      bestScore = score;
      best = e;
    }
  }
  if (bestScore < threshold) {
    return FaqMatcherResult(
      entry: null,
      score: bestScore,
      normalizedInput: norm,
    );
  }
  return FaqMatcherResult(entry: best, score: bestScore, normalizedInput: norm);
}

List<FaqEntry> allFaq() => List.unmodifiable(_faq);

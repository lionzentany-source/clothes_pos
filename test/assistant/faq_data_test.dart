import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/assistant/faq_data.dart';

void main() {
  group('Arabic normalization', () {
    test('normalizes alef variants and diacritics', () {
      final s = normalizeArabic('آلِـف إ أ');
      expect(s, 'الف ا ا');
    });
  });

  group('FAQ matching', () {
    test('matches expense add intent', () {
      final r = matchFaq('كيف ادخل مصروف؟');
      expect(r.entry?.id, 'expense_add');
      expect(r.score, greaterThan(0.4));
    });

    test('matches invoice create intent with variant words', () {
      final r = matchFaq('ابي اسوي فاتوره بيع');
      expect(r.entry?.id, 'invoice_create');
    });

    test('returns null for unrelated', () {
      final r = matchFaq('ما هو الطقس اليوم؟');
      expect(r.entry, isNull);
    });
  });
}


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

    test('matches invoice find', () {
      final r = matchFaq('ابي ادور رقم فاتورة قديمه');
      expect(r.entry?.id, anyOf('invoice_find', 'print_receipt'));
    });

    test('matches invoice cancel', () {
      final r = matchFaq('كيف الغي فاتورة البيع؟');
      expect(r.entry?.id, 'invoice_cancel');
    });

    test('matches restore backup', () {
      final r = matchFaq('كيف استعيد النسخه الاحتياطيه؟');
      expect(r.entry?.id, 'restore_backup');
    });

    test('matches edit product', () {
      final r = matchFaq('ابي اعدل سعر المنتج');
      expect(r.entry?.id, 'edit_product');
    });

    test('matches product barcode', () {
      final r = matchFaq('كيف اطبع باركود للمنتج؟');
      expect(r.entry?.id, 'product_barcode');
    });

    test('matches expense categories', () {
      final r = matchFaq('فين ادير فئات المصروفات؟');
      expect(r.entry?.id, 'expense_categories');
    });

    test('matches expense report', () {
      final r = matchFaq('ابي تقرير مصروفات الشهر');
      expect(r.entry?.id, 'expense_report');
    });
  });
}

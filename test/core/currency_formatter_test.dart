import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/core/format/currency_formatter.dart';

void main() {
  group('CurrencyFormatter.format', () {
    test('formats LYD with Arabic symbol', () {
      final s = CurrencyFormatter.format(1234.56, currency: 'LYD', locale: 'ar');
      expect(s, contains('د.ل'));
    });

    test('formats USD with \$ symbol', () {
      final s = CurrencyFormatter.format(99.5, currency: 'USD', locale: 'ar');
      expect(s, contains(r'\$'));
    });

    test('falls back to code for unknown currency', () {
      final s = CurrencyFormatter.format(10, currency: 'ABC', locale: 'ar');
      expect(s, contains('ABC'));
    });
  });
}


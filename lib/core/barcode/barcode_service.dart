/// Supported barcode types
enum BarcodeType { code128, ean13 }

class BarcodeService {
  const BarcodeService();

  /// Validates [value] for the given [type]. For Code128 we accept any non-empty.
  bool validate(String value, BarcodeType type) {
    if (value.isEmpty) return false;
    switch (type) {
      case BarcodeType.code128:
        return true; // any ASCII is okay
      case BarcodeType.ean13:
        return _isValidEan13(value);
    }
  }

  bool _isValidEan13(String v) {
    if (v.length != 13 || int.tryParse(v) == null) return false;
    final digits = v.split('').map(int.parse).toList();
    final check = digits.last;
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      final d = digits[i];
      sum += d * ((i % 2 == 0) ? 1 : 3);
    }
    final calc = (10 - (sum % 10)) % 10;
    return calc == check;
  }

  /// Generates a valid EAN-13 from a 12-digit numeric base by adding a checksum.
  /// If [base12] is shorter, it will be left-padded with zeros. If longer, it
  /// will be truncated to 12 digits.
  String generateEan13FromBase(String base12) {
    final onlyDigits = base12.replaceAll(RegExp(r'\D'), '');
    final normalized = onlyDigits.padLeft(12, '0').substring(0, 12);
    final digits = normalized.split('').map(int.parse).toList();
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      sum += digits[i] * ((i % 2 == 0) ? 1 : 3);
    }
    final check = (10 - (sum % 10)) % 10;
    return normalized + check.toString();
  }
}

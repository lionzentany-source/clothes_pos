import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/core/hardware/uhf/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TagRead model is constructible', () async {
    final t = TagRead(epc: 'x', timestamp: DateTime.now());
    expect(t.epc, 'x');
  });
}


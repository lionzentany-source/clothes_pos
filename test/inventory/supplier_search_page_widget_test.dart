import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/brand_repository.dart';
import 'package:clothes_pos/data/repositories/supplier_repository.dart';
import 'package:clothes_pos/presentation/purchases/screens/supplier_search_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() {
    sl.registerSingleton<SupplierRepository>(FakeSupplierRepository());
    sl.registerSingleton<BrandRepository>(FakeBrandRepository());
  });
  testWidgets('SupplierSearchPage renders and search field exists', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(CupertinoApp(home: SupplierSearchPage()));
    // ...existing code...
  });
}

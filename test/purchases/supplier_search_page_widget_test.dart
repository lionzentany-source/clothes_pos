import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/purchases/screens/supplier_search_page.dart';
import 'package:clothes_pos/data/repositories/supplier_repository.dart';
import '../helpers/test_helpers.dart';
import 'package:clothes_pos/core/di/locator.dart';

void main() {
  setUpAll(() {
    sl.registerSingleton<SupplierRepository>(FakeSupplierRepository());
  });

  testWidgets('SupplierSearchPage renders and search field exists', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(CupertinoApp(home: SupplierSearchPage()));

    // تحقق من وجود حقل البحث
    expect(find.byType(CupertinoSearchTextField), findsOneWidget);

    // يمكنك هنا محاكاة إدخال نص والبحث عن مورد
    // await tester.enterText(find.byType(CupertinoSearchTextField), 'مورد');
    // await tester.pumpAndSettle();
    // تحقق من ظهور نتائج البحث
  });
}

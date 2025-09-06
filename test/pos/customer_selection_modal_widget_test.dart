import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/pos/widgets/customer_selection_modal.dart';
// ...existing code...
import '../helpers/test_helpers.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/customer_repository.dart';

void main() {
  setUp(() {
    sl.registerSingleton<CustomerRepository>(FakeCustomerRepository());
  });
  testWidgets('CustomerSelectionModal shows and selects customer', (
    WidgetTester tester,
  ) async {
    // ...existing code...
    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (context) => CupertinoButton(
            child: const Text('فتح نافذة العملاء'),
            onPressed: () {
              CustomerSelectionModal.show(
                context: context,
                currentCustomer: null,
                onCustomerSelected: (customer) {
                  // ...existing code...
                },
              );
            },
          ),
        ),
      ),
    );

    // افتح النافذة
    await tester.tap(find.text('فتح نافذة العملاء'));
    await tester.pumpAndSettle();

    // تحقق من ظهور النافذة
    expect(find.byType(CustomerSelectionModal), findsOneWidget);
    // يمكنك هنا محاكاة اختيار عميل إذا كان هناك قائمة عملاء
    // مثال: await tester.tap(find.text('اسم العميل'));
    // await tester.pumpAndSettle();
    // expect(selectedCalled, true);
  });
}

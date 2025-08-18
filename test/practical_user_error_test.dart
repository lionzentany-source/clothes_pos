import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/auth/screens/login_screen.dart';
import 'package:clothes_pos/presentation/inventory/screens/product_editor_screen.dart';
import 'package:clothes_pos/presentation/pos/screens/pos_screen.dart';
import 'package:clothes_pos/presentation/inventory/screens/inventory_list_screen.dart';
import 'package:clothes_pos/presentation/common/widgets/app_labeled_field.dart';
import 'helpers/test_helpers.dart';

void main() {
  // Ensure the binding is initialized
  TestWidgetsFlutterBinding.ensureInitialized();

  // Set up all dependencies before running tests
  setUpAll(() async {
    await setupTestDependencies();
  });

  group('Practical User Error Scenarios', () {
    testWidgets('Login with empty fields shows error', (tester) async {
      await tester.pumpWidget(const CupertinoApp(home: LoginScreen()));
      await tester.tap(find.text('دخول'));
      await tester.pumpAndSettle();
      expect(find.textContaining('خطأ'), findsWidgets);
    });

    testWidgets('Add product with missing data shows error', (tester) async {
      await tester.pumpWidget(CupertinoApp(home: ProductEditorScreen()));
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();
      expect(find.textContaining('مطلوب'), findsWidgets);
    });

    testWidgets('POS: Try to sell with no product selected', (tester) async {
      await tester.pumpWidget(CupertinoApp(home: PosScreen()));
      await tester.tap(find.text('بيع'));
      await tester.pumpAndSettle();
      expect(find.textContaining('اختر منتج'), findsWidgets);
    });

    testWidgets('Inventory: Add product with negative quantity', (
      tester,
    ) async {
      await tester.pumpWidget(CupertinoApp(home: ProductEditorScreen()));
      await tester.enterText(find.byType(AppLabeledField).first, '-5');
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();
      expect(find.textContaining('كمية موجبة'), findsWidgets);
    });

    testWidgets('Inventory: Try to delete non-existent product', (
      tester,
    ) async {
      await tester.pumpWidget(CupertinoApp(home: InventoryListScreen()));
      await tester.enterText(
        find.byType(CupertinoSearchTextField),
        'منتجغيرموجود',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف'));
      await tester.pumpAndSettle();
      expect(find.textContaining('غير موجود'), findsWidgets);
    });

    testWidgets('Fast navigation and random taps do not crash app', (
      tester,
    ) async {
      await tester.pumpWidget(CupertinoApp(home: InventoryListScreen()));
      await tester.tap(find.byType(CupertinoButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CupertinoListTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoApp), findsOneWidget);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/presentation/inventory/screens/product_editor_screen.dart';
import 'package:clothes_pos/core/config/feature_flags.dart';
import 'package:flutter/cupertino.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Product editor shows manage attributes button when feature enabled',
    (tester) async {
      // Enable the feature flag for tests (preferred test hook)
      FeatureFlags.setForTests(true);

      await tester.pumpWidget(
        const CupertinoApp(home: ProductEditorScreen(skipInit: true)),
      );

      // Allow build
      await tester.pumpAndSettle();

      // The UI may render one or more ActionButtons when the feature is on.
      // Accept either the button by key or any Text widget containing the
      // Arabic word for "attributes" to make this test tolerant to small UI
      // changes introduced by the feature.
      final byKey = find.byKey(const Key('manage-attributes-button'));
      final textFinder = find.byWidgetPredicate(
        (w) => w is Text && ((w.data ?? '').contains('خصائص')),
      );

      final found =
          byKey.evaluate().isNotEmpty || textFinder.evaluate().isNotEmpty;
      expect(
        found,
        isTrue,
        reason:
            'Expected manage-attributes button by key or a Text containing "خصائص"',
      );
    },
  );
}

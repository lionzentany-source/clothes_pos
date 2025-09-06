import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/presentation/inventory/widgets/attribute_picker.dart';
import 'package:clothes_pos/data/models/attribute.dart';
import 'package:flutter/cupertino.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AttributePicker loads attributes and allows selection', (
    tester,
  ) async {
    final attributes = [
      Attribute(id: 1, name: 'Size'),
      Attribute(id: 2, name: 'Color'),
    ];
    final values = {
      1: [
        AttributeValue(id: 11, attributeId: 1, value: 'S'),
        AttributeValue(id: 12, attributeId: 1, value: 'M'),
      ],
      2: [
        AttributeValue(id: 21, attributeId: 2, value: 'Red'),
        AttributeValue(id: 22, attributeId: 2, value: 'Blue'),
      ],
    };

    await tester.pumpWidget(
      CupertinoApp(
        home: Builder(
          builder: (ctx) {
            return CupertinoButton(
              child: const Text('Open'),
              onPressed: () {
                showCupertinoModalPopup(
                  context: ctx,
                  builder: (_) => AttributePicker(
                    loadAttributes: () async => attributes,
                    loadAttributeValues: (id) async => values[id] ?? [],
                    onDone: (_) {},
                  ),
                );
              },
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Expect attribute names to appear
    expect(find.text('Size'), findsOneWidget);
    expect(find.text('Color'), findsOneWidget);

    // Tap a value chip
    expect(find.text('S'), findsOneWidget);
    await tester.tap(find.text('S'));
    await tester.pump();

    // Now search for 'Red'
    await tester.enterText(find.byType(CupertinoSearchTextField), 'Red');
    await tester.pumpAndSettle();

    // The search field also contains the text 'Red', so locate the result button inside the ListView
    final redBtn = find.descendant(
      of: find.byType(ListView),
      matching: find.widgetWithText(CupertinoButton, 'Red'),
    );
    expect(redBtn, findsOneWidget);
    await tester.tap(redBtn);
    await tester.pump();

    // Selected chips should appear (by value text) - allow multiple occurrences (search field, list, chip)
    expect(find.text('S'), findsWidgets);
    expect(find.text('Red'), findsWidgets);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/presentation/inventory/widgets/attribute_picker.dart';
import 'package:clothes_pos/data/models/attribute.dart';
import 'package:flutter/cupertino.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'AttributePicker suggestions + fallback reorder preserves order in onDone',
    (tester) async {
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

      List<AttributeValue>? doneResult;

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
                      onDone: (sel) => doneResult = sel,
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

      // Select 'S' from grouped list
      await tester.tap(find.text('S').first);
      await tester.pump();

      // Search for 'Red' to show suggestions
      await tester.enterText(find.byType(CupertinoSearchTextField), 'Red');
      await tester.pumpAndSettle();

      // Suggestions are rendered inside a SizedBox(height: 40)
      final suggestionsBox = find.byWidgetPredicate(
        (w) => w is SizedBox && w.height == 40,
      );
      expect(suggestionsBox, findsOneWidget);
      final redSuggestion = find.descendant(
        of: suggestionsBox,
        matching: find.text('Red'),
      );
      expect(redSuggestion, findsOneWidget);
      await tester.tap(redSuggestion);
      await tester.pump();

      // Verify selected fallback containers exist
      expect(find.byKey(const ValueKey('sel-fallback-11')), findsOneWidget);
      expect(find.byKey(const ValueKey('sel-fallback-21')), findsOneWidget);

      // Use the fallback right-chevron on 'S' to move it right (swap with Red)
      final sRightChevron = find.byKey(const ValueKey('sel-right-11'));
      expect(sRightChevron, findsOneWidget);
      await tester.tap(sRightChevron);
      await tester.pump();

      // Press done
      await tester.tap(find.text('تم'));
      await tester.pumpAndSettle();

      expect(doneResult, isNotNull);
      expect(doneResult!.length, 2);
      // After moving S right, Red (id 21) should be first
      expect(doneResult![0].id, 21);
      expect(doneResult![1].id, 11);
    },
  );
}

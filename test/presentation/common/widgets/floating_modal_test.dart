import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/presentation/common/widgets/floating_modal.dart';

void main() {
  test('throws when scrollable:true with Column having Flexible/Expanded', () {
    expect(
      () => FloatingModal(
        title: 'Bad',
        scrollable: true,
        child: Column(children: const [Expanded(child: SizedBox())]),
      ),
      throwsFlutterError,
    );
  });

  testWidgets('allows scrollable:false with Column having Flexible/Expanded', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CupertinoApp(home: _Host()));

    // Should render the title without throwing.
    expect(find.text('Safe'), findsOneWidget);
  });
}

class _Host extends StatelessWidget {
  const _Host();
  @override
  Widget build(BuildContext context) {
    return FloatingModal(
      title: 'Safe',
      // Critical: no scroll wrapper around a Column with Expanded
      scrollable: false,
      modalSize: ModalSize.small,
      child: Column(
        children: [
          Expanded(child: Container(color: CupertinoColors.activeBlue)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';

class FilterPills extends StatelessWidget {
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onPickUser;
  final VoidCallback onPickCategory;
  final VoidCallback onPickSupplier;
  final VoidCallback onReset;

  const FilterPills({
    super.key,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onPickUser,
    required this.onPickCategory,
    required this.onPickSupplier,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 8), onPressed: onPickStart, child: const Text('من')),
          CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 8), onPressed: onPickEnd, child: const Text('إلى')),
          CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 8), onPressed: onPickUser, child: const Text('الموظف')),
          CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 8), onPressed: onPickCategory, child: const Text('الفئة')),
          CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 8), onPressed: onPickSupplier, child: const Text('المورد')),
          CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 8), onPressed: onReset, child: const Text('مسح')),
        ],
      ),
    );
  }
}


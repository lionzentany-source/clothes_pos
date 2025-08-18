import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/data/models/brand.dart';
import 'package:clothes_pos/l10n/app_localizations.dart';

class BrandPickerSheet extends StatelessWidget {
  final List<Brand> brands;
  final void Function(Brand) onSelected;
  final VoidCallback onAddNew;
  final VoidCallback? onClear;
  const BrandPickerSheet({
    super.key,
    required this.brands,
    required this.onSelected,
    required this.onAddNew,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return CupertinoActionSheet(
      title: Text(l?.selectAction ?? 'Select'),
      actions: [
        ...brands.map(
          (b) => CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              onSelected(b);
            },
            child: Text(b.name),
          ),
        ),
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(context).pop();
            onAddNew();
          },
          child: Text(l?.addAction ?? 'Add'),
        ),
        if (onClear != null)
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              onClear!.call();
            },
            isDestructiveAction: true,
            child: Text(l?.clearFilters ?? 'Clear'),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(context).pop(),
        isDefaultAction: true,
        child: Text(l?.cancel ?? 'Cancel'),
      ),
    );
  }
}

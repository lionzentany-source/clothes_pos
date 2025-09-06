import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';

class FilterChipsBar extends StatelessWidget {
  final List<String> sizes;
  final List<String> colors;
  final List<String> brands;
  final String? selectedSize;
  final String? selectedColor;
  final String? selectedBrand;
  final void Function(String? size)? onSizeChanged;
  final void Function(String? color)? onColorChanged;
  final void Function(String? brand)? onBrandChanged;
  final EdgeInsetsGeometry padding;
  const FilterChipsBar({
    super.key,
    required this.sizes,
    required this.colors,
    required this.brands,
    this.selectedSize,
    this.selectedColor,
    this.selectedBrand,
    this.onSizeChanged,
    this.onColorChanged,
    this.onBrandChanged,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.xs,
      vertical: AppSpacing.xxs,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget chip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) => GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? c.primary : c.surfaceAlt,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? c.primaryHover : c.border),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? CupertinoColors.white : c.textPrimary,
          ),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );

    List<Widget> group({
      required String title,
      required List<String> values,
      required String? selectedValue,
      required void Function(String? v)? onChanged,
    }) {
      if (values.isEmpty) return [];
      final widgets = <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: c.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ];
      for (final val in values.take(24)) {
        widgets.add(
          chip(
            label: val,
            selected: selectedValue == val,
            onTap: () => onChanged?.call(selectedValue == val ? null : val),
          ),
        );
      }
      return widgets;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          ...group(
            title: 'S',
            values: sizes,
            selectedValue: selectedSize,
            onChanged: onSizeChanged,
          ),
          if (sizes.isNotEmpty && (colors.isNotEmpty || brands.isNotEmpty))
            const SizedBox(width: AppSpacing.sm),
          ...group(
            title: 'C',
            values: colors,
            selectedValue: selectedColor,
            onChanged: onColorChanged,
          ),
          if (colors.isNotEmpty && brands.isNotEmpty)
            const SizedBox(width: AppSpacing.sm),
          ...group(
            title: 'B',
            values: brands,
            selectedValue: selectedBrand,
            onChanged: onBrandChanged,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:clothes_pos/data/models/inventory_item_row.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:clothes_pos/presentation/pos/widgets/shimmer.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';
import 'package:clothes_pos/presentation/design/system/app_typography.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/presentation/design/system/ui_density.dart';
import 'package:clothes_pos/presentation/common/money.dart';

/// Single product/variant tile for the POS product results grid.
/// Expects a dynamic [variant] row with at least: id, salePrice, name/parent_name/sku.
class ProductGridItem extends StatelessWidget {
  final dynamic variant;
  final VoidCallback? onTap;
  final double? width; // optional fixed width override
  final bool showStockBadge;
  final bool loading;
  final bool square; // enforce square card layout
  const ProductGridItem({
    super.key,
    required this.variant,
    this.onTap,
    this.width,
    this.showStockBadge = true,
    this.loading = false,
    this.square = false,
  });

  T? _read<T>(dynamic v, String key) {
    try {
      if (v is Map<String, Object?>) return v[key] as T?; // standard map row
      // Fallback: some row types (QueryRow) support [] via dynamic
      return (v as dynamic)[key] as T?;
    } catch (_) {
      return null;
    }
  }

  String _displayName(dynamic v) {
    // Order: parent_name -> name -> sku -> fallback
    if (v is InventoryItemRow) {
      if (v.parentName.isNotEmpty) return v.parentName;
      return v.variant.sku ?? 'Item ${v.variant.id ?? ''}';
    }
    if (v is ProductVariant) {
      return v.sku ?? 'Item ${v.id ?? ''}';
    }
    final parent = _read<Object?>(v, 'parent_name');
    final name = _read<Object?>(v, 'name');
    final sku = _read<Object?>(v, 'sku');
    return (parent ?? name ?? sku ?? 'Item').toString();
  }

  double _salePrice(dynamic v) {
    if (v is InventoryItemRow) return v.variant.salePrice;
    if (v is ProductVariant) return v.salePrice;
    final p = _read<num>(v, 'sale_price') ?? _read<num>(v, 'salePrice');
    return (p ?? 0).toDouble();
  }

  int? _quantity(dynamic v) {
    if (v is InventoryItemRow) return v.variant.quantity;
    if (v is ProductVariant) return v.quantity;
    return _read<num>(v, 'quantity')?.toInt();
  }

  String? _size(dynamic v) {
    if (v is InventoryItemRow) return v.variant.size;
    if (v is ProductVariant) return v.size;
    return _read<Object?>(v, 'size')?.toString();
  }

  String? _color(dynamic v) {
    if (v is InventoryItemRow) return v.variant.color;
    if (v is ProductVariant) return v.color;
    return _read<Object?>(v, 'color')?.toString();
  }

  @override
  Widget build(BuildContext context) {
    final name = loading ? '' : _displayName(variant);
    final price = loading ? 0.0 : _salePrice(variant);
    final qty = loading ? null : _quantity(variant); // may be null
    final c = context.colors;
    final density = DensityConfig.of(context);
    final thumbH = DensityConfig.productThumb(density);
    final content = Column(
      mainAxisAlignment: square
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (square)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.border),
              ),
              alignment: Alignment.center,
              child: loading
                  ? const Shimmer(width: 48, height: 32)
                  : SvgPicture.asset(
                      'assets/svg/product_placeholder.svg',
                      width: 36,
                      height: 36,
                      colorFilter: ColorFilter.mode(
                        c.textSecondary.withOpacity(.45),
                        BlendMode.srcIn,
                      ),
                    ),
            ),
          )
        else
          Container(
            height: thumbH,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.border),
            ),
            alignment: Alignment.center,
            child: loading
                ? const Shimmer(width: 48, height: 32)
                : SvgPicture.asset(
                    'assets/svg/product_placeholder.svg',
                    width: 40,
                    height: 40,
                    colorFilter: ColorFilter.mode(
                      c.textSecondary.withOpacity(.45),
                      BlendMode.srcIn,
                    ),
                  ),
          ),
        SizedBox(height: square ? 3 : AppSpacing.xxs),
        if (!loading)
          _VariantBadges(
            data: {'size': _size(variant), 'color': _color(variant)},
            density: density,
          ),
        if (!loading) const SizedBox(height: 2),
        if (!loading)
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyStrong.copyWith(
              color: c.textPrimary,
              fontSize: square ? 11 : null,
            ),
          )
        else
          const Shimmer(width: 80, height: 12),
        SizedBox(height: square ? 1 : AppSpacing.xxs),
        if (!loading)
          Text(
            money(context, price),
            style: AppTypography.caption.copyWith(
              color: c.textSecondary,
              fontSize: square ? 10 : null,
            ),
          )
        else
          const Shimmer(width: 50, height: 10),
        if (showStockBadge && qty != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxs + 2,
                  vertical: AppSpacing.xxs / 2,
                ),
                decoration: BoxDecoration(
                  color: qty > 0 ? c.successContainer : c.dangerContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  qty > 0 ? 'Stock: ${qty.toInt()}' : 'Out',
                  style: AppTypography.caption.copyWith(
                    color: qty > 0 ? c.success : c.danger,
                    fontSize: AppTypography.fs10,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    return SizedBox(
      width: width,
      child: CupertinoButton(
        padding: EdgeInsets.all(square ? 6 : AppSpacing.sm),
        color: c.surfaceAlt,
        onPressed: onTap,
        child: square ? content : content,
      ),
    );
  }
}

class _VariantBadges extends StatelessWidget {
  final Map<String, Object?> data;
  final UIDensity density;
  const _VariantBadges({required this.data, required this.density});
  @override
  Widget build(BuildContext context) {
    final size = (data['size'] ?? '').toString();
    final color = (data['color'] ?? '').toString();
    if (size.isEmpty && color.isEmpty) return const SizedBox.shrink();
    final c = context.colors;
    final pads = DensityConfig.tilePadding(density) - 2;
    List<Widget> chips = [];
    Widget chip(String text) => Container(
      padding: EdgeInsets.symmetric(horizontal: pads, vertical: 2),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppTypography.micro.copyWith(color: c.textSecondary),
      ),
    );
    if (size.isNotEmpty) chips.add(chip(size));
    if (color.isNotEmpty) chips.add(chip(color));
    return Wrap(spacing: 4, children: chips);
  }
}

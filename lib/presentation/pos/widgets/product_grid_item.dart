import 'package:clothes_pos/core/config/feature_flags.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:clothes_pos/presentation/pos/widgets/shimmer.dart';
import 'package:clothes_pos/presentation/design/system/app_typography.dart';
import 'package:clothes_pos/presentation/common/widgets/variant_attributes_display.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/presentation/common/money.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:clothes_pos/data/models/inventory_item_row.dart';
import 'dart:io';

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
      return v.variant.sku ?? 'Variant';
    }
    if (v is ProductVariant) {
      return v.sku ?? 'Variant';
    }
    final parent = _read<Object?>(v, 'parent_name');
    final name = _read<Object?>(v, 'name');
    final sku = _read<Object?>(v, 'sku');
    return (parent ?? name ?? sku ?? 'Variant').toString();
  }

  double _salePrice(dynamic v) {
    if (v is InventoryItemRow) return v.variant.salePrice;
    if (v is ProductVariant) return v.salePrice;
    final p = _read<num>(v, 'sale_price') ?? _read<num>(v, 'salePrice');
    return (p ?? 0).toDouble();
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
    final c = context.colors;
    final colorStr = _color(variant);
    Color? borderColor;
    if (colorStr != null && colorStr.trim().isNotEmpty) {
      // Try to parse known color names or hex
      final lower = colorStr.toLowerCase().trim();
      const colorMap = {
        // 12 Basic Colors (English & Arabic)
        'red': 0xFFFF0000,
        'أحمر': 0xFFFF0000,
        'blue': 0xFF0000FF,
        'أزرق': 0xFF0000FF,
        'green': 0xFF008000,
        'أخضر': 0xFF008000,
        'yellow': 0xFFFFFF00,
        'أصفر': 0xFFFFFF00,
        'orange': 0xFFFFA500,
        'برتقالي': 0xFFFFA500,
        'purple': 0xFF800080,
        'بنفسجي': 0xFF800080,
        'pink': 0xFFFFC0CB,
        'وردي': 0xFFFFC0CB,
        'brown': 0xFFA52A2A,
        'بني': 0xFFA52A2A,
        'black': 0xFF000000,
        'أسود': 0xFF000000,
        'white': 0xFFFFFFFF,
        'أبيض': 0xFFFFFFFF,
        'grey': 0xFF808080,
        'gray': 0xFF808080,
        'رمادي': 0xFF808080,
        // ...باقي الألوان السابقة...
        'silver': 0xFFC0C0C0,
        'رصاصي': 0xFFC0C0C0,
        'فضي': 0xFFC0C0C0,
        'ذهبي': 0xFFFFD700,
        'كحلي': 0xFF001F3F,
        'سماوي': 0xFF81D4FA,
        'عنابي': 0xFF800000,
        'زيتي': 0xFF556B2F,
        'موف': 0xFFB39DDB,
        'تركواز': 0xFF1DE9B6,
        'بيج': 0xFFF5F5DC,
        'أخضر فاتح': 0xFFB2FF59,
        'أخضر غامق': 0xFF388E3C,
        'أزرق فاتح': 0xFF90CAF9,
        'أزرق غامق': 0xFF0D47A1,
        'وردي فاتح': 0xFFF8BBD0,
        'وردي غامق': 0xFFC2185B,
        'برتقالي فاتح': 0xFFFFE0B2,
        'برتقالي غامق': 0xFFF57C00,
        'بني فاتح': 0xFFD7CCC8,
        'بني غامق': 0xFF4E342E,
      };
      if (colorMap.containsKey(lower)) {
        borderColor = Color(colorMap[lower]!);
      } else if (RegExp(r'^#?([0-9a-fA-F]{6})').hasMatch(lower)) {
        final hex = RegExp(r'^#?([0-9a-fA-F]{6})').firstMatch(lower);
        borderColor = Color(int.parse('0xFF${hex!.group(1)}'));
      } else {
        borderColor = c.border;
      }
    }
    if (borderColor == null || (colorStr == null || colorStr.trim().isEmpty)) {
      borderColor = c.border;
    }

    // Debug info removed - use AppLogger.d if needed for debugging

    // Extract variables
    String? size;
    String? color;
    int? quantity;
    if (variant is InventoryItemRow) {
      size = variant.variant.size;
      color = variant.variant.color;
      quantity = variant.variant.quantity;
    } else if (variant is ProductVariant) {
      size = variant.size;
      color = variant.color;
      quantity = variant.quantity;
    } else {
      size = _read<Object?>(variant, 'size')?.toString();
      color = _read<Object?>(variant, 'color')?.toString();
      quantity = _read<num>(variant, 'quantity')?.toInt();
    }

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product image on the right
          if (!loading)
            _buildProductImage(context, variant)
          else
            const Shimmer(width: 44, height: 36),

          const SizedBox(width: 8),

          // Text content on the left
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!loading)
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyStrong.copyWith(
                      color: c.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  const Shimmer(width: 80, height: 14),

                if (!loading)
                  Text(
                    money(context, price),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyStrong.copyWith(
                      color: c.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  const Shimmer(width: 50, height: 12),

                if (!loading && quantity != null)
                  Text(
                    'الكمية: $quantity',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyStrong.copyWith(
                      color: c.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                if (!loading)
                  if (FeatureFlags.useDynamicAttributes)
                    _buildAttributes(context, variant)
                  else if (size != null || color != null)
                    Text(
                      [
                        if (color != null && color.isNotEmpty) 'اللون: $color',
                        if (size != null && size.isNotEmpty) 'المقاس: $size',
                      ].join(' • '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyStrong.copyWith(
                        color: c.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );

    return SizedBox(
      width: width,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: _borderWrapper(
          context: context,
          child: content,
          borderColor: borderColor,
        ),
      ),
    );
  }

  Widget _buildAttributes(BuildContext context, dynamic variant) {
    // Support multiple shapes: model objects, InventoryItemRow, or raw Map rows
    List<dynamic>? attributes;
    if (variant is InventoryItemRow) {
      attributes = variant.variant.attributes;
    } else if (variant is ProductVariant) {
      attributes = variant.attributes;
    } else {
      // Try reading 'attributes' key from map-like rows
      try {
        final raw = _read<dynamic>(variant, 'attributes');
        if (raw is List) attributes = raw.cast<dynamic>();
      } catch (_) {
        attributes = null;
      }
    }

    if (attributes == null || attributes.isEmpty)
      return const SizedBox.shrink();

    // Delegate rendering to VariantAttributesDisplay which accepts dynamic lists
    return VariantAttributesDisplay(attributes: attributes);
  }

  Widget _borderWrapper({
    required BuildContext context,
    required Widget child,
    required Color borderColor,
  }) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: c.surface,
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
    );
  }

  Widget _buildProductImage(BuildContext context, dynamic variant) {
    String? imagePath;

    // Try to get image path from variant
    if (variant is ProductVariant) {
      imagePath = variant.imagePath;
    } else if (variant is InventoryItemRow) {
      imagePath = variant.variant.imagePath;
    } else {
      // For map-based rows
      imagePath = _read<String>(variant, 'image_path');
    }

    // If we have an image path and the file exists, display it
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      // تحقق من المسار ووجود الملف
      debugPrint(
        '[ProductGridItem] imagePath: $imagePath, exists: ${file.existsSync()}',
      );
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.file(file, width: 44, height: 44, fit: BoxFit.cover),
        );
      }
    }

    // Fallback to placeholder
    return SvgPicture.asset(
      'assets/svg/product_placeholder.svg',
      width: 44,
      height: 44,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(
        context.colors.textSecondary.withValues(alpha: 0.45),
        BlendMode.srcIn,
      ),
    );
  }
}

// Removed unused _VariantBadges

// Removed unused _HalfBorder

// Removed unused _HalfBorderPainter

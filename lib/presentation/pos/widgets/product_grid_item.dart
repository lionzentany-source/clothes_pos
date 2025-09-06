import 'package:clothes_pos/core/config/feature_flags.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:clothes_pos/presentation/pos/widgets/shimmer.dart';
import 'package:clothes_pos/presentation/design/system/app_typography.dart';
import 'package:clothes_pos/presentation/inventory/widgets/item_details_modal.dart';
import 'package:clothes_pos/core/di/locator.dart' show sl;
import 'package:clothes_pos/data/repositories/inventory_repository.dart';
import 'package:clothes_pos/presentation/pos/utils/cart_helpers.dart';
import 'package:flutter/services.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/presentation/common/money.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:clothes_pos/data/models/inventory_item_row.dart';
import 'package:clothes_pos/data/datasources/attribute_dao.dart';
import 'dart:io';

/// Single product/variant tile for the POS product results grid.
/// Expects a dynamic [variant] row with at least: id, salePrice, name/parent_name/sku.
class ProductGridItem extends StatefulWidget {
  final dynamic variant;
  final VoidCallback? onTap;
  final double? width; // optional fixed width override
  final bool showStockBadge;
  final bool loading;
  final bool square; // enforce square card layout
  final bool showImage;
  const ProductGridItem({
    super.key,
    required this.variant,
    this.onTap,
    this.width,
    this.showStockBadge = true,
    this.loading = false,
    this.square = false,
    this.showImage = true,
  });

  @override
  State<ProductGridItem> createState() => _ProductGridItemState();

  // Simple in-memory cache for resolved InventoryItemRow by variant id.
  static final Map<int, InventoryItemRow?> _resolvedRowCache = {};
}

class _ProductGridItemState extends State<ProductGridItem> {
  bool _resolving = false;
  int? _resolvingId;

  T? _read<T>(dynamic v, String key) {
    try {
      if (v is Map<String, Object?>) return v[key] as T?; // standard map row
      // Fallback: some row types (QueryRow) support [] via dynamic
      return (v as dynamic)[key] as T?;
    } catch (_) {
      return null;
    }
  }

  // Ensure we have details for this variant by resolving a full
  // InventoryItemRow in the background when the quick row lacks
  // attributes AND color/size AND sku. This works even if dynamic
  // attributes feature is disabled.
  void _ensureAttributesResolved(dynamic v) {
    final id = _variantId(v);
    if (id == null) return;

    bool hasAttrs = false;
    try {
      // Attributes present?
      List<dynamic>? attrs;
      if (v is InventoryItemRow) {
        attrs = v.variant.attributes;
        // color/size/sku values aren't required to decide now
      } else if (v is ProductVariant) {
        attrs = v.attributes;
        // color/size/sku values aren't required to decide now
      } else {
        final rawAttrs = _read<dynamic>(v, 'attributes');
        if (rawAttrs is List) attrs = rawAttrs.cast<dynamic>();
        // color/size/sku values aren't required to decide now
      }
      hasAttrs = (attrs != null && attrs.isNotEmpty);
    } catch (_) {}

    // If we already have attributes, no need to resolve further.
    if (hasAttrs) return;

    // If cache has a row WITH attributes, we can skip resolving.
    if (ProductGridItem._resolvedRowCache.containsKey(id)) {
      final cached = ProductGridItem._resolvedRowCache[id];
      if (cached != null && (cached.variant.attributes?.isNotEmpty ?? false)) {
        return; // already have enriched row
      }
      // else: cached row exists but without attributes -> try resolving again
    }

    // Resolve after the current frame to avoid setState during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _resolveRowIfNeeded(id);
    });
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

  int? _variantId(dynamic v) {
    try {
      if (v is InventoryItemRow) return v.variant.id;
      if (v is ProductVariant) return v.id;
      // Support both 'id' and 'variant_id' shapes from different queries
      final id = _read<int>(v, 'id');
      if (id != null) return id;
      final vidInt = _read<int>(v, 'variant_id');
      if (vidInt != null) return vidInt;
      // Some drivers return numbers as num/double; coerce when needed
      final vidNum = _read<num>(v, 'variant_id');
      if (vidNum != null) return vidNum.toInt();
      final idNum = _read<num>(v, 'id');
      if (idNum != null) return idNum.toInt();
      // Fallback: try dynamic dot properties
      try {
        final dyn = v as dynamic;
        final dId = dyn.id as int?;
        if (dId != null) return dId;
      } catch (_) {}
      try {
        final dyn = v as dynamic;
        final dVid = dyn.variant_id as int?;
        if (dVid != null) return dVid;
      } catch (_) {}
      return null;
    } catch (_) {
      return null;
    }
  }

  String? _sku(dynamic v) {
    if (v is InventoryItemRow) return v.variant.sku;
    if (v is ProductVariant) return v.sku;
    final s = _read<Object?>(v, 'sku')?.toString();
    if (s != null && s.isNotEmpty) return s;
    try {
      return (v as dynamic).sku?.toString();
    } catch (_) {
      return null;
    }
  }

  String? _color(dynamic v) {
    if (v is InventoryItemRow) return v.variant.color;
    if (v is ProductVariant) return v.color;
    return _read<Object?>(v, 'color')?.toString();
  }

  Future<InventoryItemRow?> _resolveRowIfNeeded(int id) async {
    // If we already have a cached row WITH attributes, reuse it; otherwise try to fetch again
    if (ProductGridItem._resolvedRowCache.containsKey(id)) {
      final cached = ProductGridItem._resolvedRowCache[id];
      if (cached != null && (cached.variant.attributes?.isNotEmpty ?? false)) {
        return cached;
      }
    }
    setState(() {
      _resolving = true;
      _resolvingId = id;
    });
    try {
      var row = await sl<InventoryRepository>().getInventoryItemByVariantId(id);
      // Fallback: if repo returned without attributes, try direct AttributeDao
      if (row != null &&
          (row.variant.attributes == null || row.variant.attributes!.isEmpty)) {
        try {
          final vals = await sl<AttributeDao>().getAttributeValuesForVariant(
            id,
          );
          if (vals.isNotEmpty) {
            row = InventoryItemRow(
              variant: row.variant.copyWith(attributes: vals),
              parentName: row.parentName,
              brandName: row.brandName,
            );
            debugPrint(
              '[ProductGridItem] direct attribute fetch used for id=$id, count=${vals.length}',
            );
          }
        } catch (_) {}
      }
      ProductGridItem._resolvedRowCache[id] = row;
      return row;
    } catch (_) {
      ProductGridItem._resolvedRowCache[id] = null;
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _resolving = false;
          _resolvingId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final variant = widget.variant;
    // If attributes are missing on this quick row, kick off a background
    // resolve so we can render them when ready.
    _ensureAttributesResolved(variant);
    final name = widget.loading ? '' : _displayName(variant);
    final price = widget.loading ? 0.0 : _salePrice(variant);
    final c = context.colors;
    final colorStr = _color(variant);
    Color? borderColor;
    if (colorStr != null && colorStr.trim().isNotEmpty) {
      // Try to parse known color names or hex
      final lower = colorStr.toLowerCase().trim();
      const colorMap = {
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

    // Grid-style square card layout when requested (used in POS grid)
    Widget content;
    if (widget.square) {
      content = Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image ~75% height, no cropping (contain)
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: widget.loading
                        ? const SizedBox.shrink()
                        : (widget.showImage
                              ? _buildProductImageSquareContain(
                                  context,
                                  variant,
                                )
                              : SvgPicture.asset(
                                  'assets/svg/product_placeholder.svg',
                                  fit: BoxFit.contain,
                                )),
                  ),
                  // Top-right badges: quantity and attributes chip side-by-side
                  if (!widget.loading)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Directionality(
                        textDirection: Directionality.of(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (quantity != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: quantity > 0
                                      ? CupertinoColors.activeGreen
                                      : CupertinoColors.systemGrey,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: context.colors.surface,
                                  ),
                                ),
                                child: Text(
                                  quantity.toString(),
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 4),
                            // Compact attributes chip if we have anything to show
                            Builder(
                              builder: (ctx) {
                                final parts = _extractDisplayAttributes(
                                  variant,
                                  max: 2,
                                );
                                String? text = parts.isNotEmpty
                                    ? parts.join(' • ')
                                    : null;
                                // Progressive fallbacks: SKU -> display name -> #ID -> dash
                                text ??= _sku(variant);
                                if (text == null || text.isEmpty) {
                                  try {
                                    text = _displayName(variant);
                                  } catch (_) {}
                                }
                                if (text == null || text.isEmpty) {
                                  final id = _variantId(variant);
                                  if (id != null) text = '#$id';
                                }
                                text ??= '-';
                                final c = ctx.colors;
                                return ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 132,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: c.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: c.border),
                                    ),
                                    child: Text(
                                      text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: AppTypography.bodyStrong.copyWith(
                                        color: c.textPrimary,
                                        fontSize: 9,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Bottom: right-aligned block with name, attributes, then price (all on the RIGHT in RTL)
            Expanded(
              // Give extra space so name, price, and attributes all fit
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!widget.loading)
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: AppTypography.bodyStrong.copyWith(
                          color: c.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      )
                    else
                      const Shimmer(width: 90, height: 12),
                    const SizedBox(height: 2),
                    // Attributes moved to top-right next to quantity badge
                    const SizedBox(height: 2),
                    if (!widget.loading)
                      Text(
                        money(context, price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: AppTypography.bodyStrong.copyWith(
                          color: c.textSecondary,
                          fontSize: 12,
                          height: 1.1,
                        ),
                      )
                    else
                      const Shimmer(width: 60, height: 10),
                    const SizedBox(height: 1),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product image on the right (optional)
            if (widget.loading)
              const Shimmer(width: 44, height: 36)
            else if (widget.showImage)
              _buildProductImage(context, variant)
            else
              const SizedBox.shrink(),

            if (widget.loading || widget.showImage) const SizedBox(width: 8),

            // Text content on the left
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!widget.loading)
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

                  if (!widget.loading)
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

                  if (!widget.loading && quantity != null)
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

                  if (!widget.loading)
                    if (FeatureFlags.useDynamicAttributes)
                      _buildAttributes(context, variant)
                    else if (size != null || color != null)
                      Text(
                        [
                          if (color != null && color.isNotEmpty)
                            'اللون: $color',
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
    }

    final idForResolve = _variantId(variant);
    final showOverlay =
        _resolving &&
        _resolvingId != null &&
        idForResolve != null &&
        _resolvingId == idForResolve;

    return SizedBox(
      width: widget.width,
      child: _PressableCard(
        onLongPress: () {
          HapticFeedback.vibrate();
          try {
            if (variant is InventoryItemRow) {
              ItemDetailsModal.open(context, variant);
              return;
            }
            final id = _variantId(variant);
            if (id != null) {
              final currentContext = context;
              // Fire and forget resolver which shows an inline loader if it takes time
              _resolveRowIfNeeded(id)
                  .then((row) {
                    if (!currentContext.mounted) return;
                    if (row != null) ItemDetailsModal.open(currentContext, row);
                  })
                  .catchError((_) {});
            }
          } catch (_) {}
        },
        onTap: () async {
          if (widget.onTap != null) return widget.onTap!();
          // If attributes feature is enabled and the variant requires attributes,
          // open the item details modal instead of quick-adding.
          try {
            if (FeatureFlags.useDynamicAttributes) {
              if (variant is InventoryItemRow) {
                final v = variant;
                if ((v.variant.attributes ?? []).isNotEmpty) {
                  ItemDetailsModal.open(context, v);
                  return;
                }
              } else {
                final id = _variantId(variant);
                if (id != null) {
                  final currentContext = context;
                  final row = await _resolveRowIfNeeded(id);
                  if (!currentContext.mounted) return;
                  if (row != null &&
                      (row.variant.attributes ?? []).isNotEmpty) {
                    ItemDetailsModal.open(currentContext, row);
                    return;
                  }
                }
              }
            }
          } catch (_) {}
          final id = _variantId(variant);
          if (id != null) {
            final currentContext = context;
            if (!currentContext.mounted) return;
            await safeAddToCart(currentContext, id, price);
          }
        },
        child: _borderWrapper(
          context: context,
          child: Stack(
            children: [
              content,
              if (showOverlay)
                Positioned.fill(
                  child: Container(
                    color: Color.fromRGBO(0, 0, 0, 0.28),
                    child: const Center(child: CupertinoActivityIndicator()),
                  ),
                ),
            ],
          ),
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

    if (attributes == null || attributes.isEmpty) {
      return const SizedBox.shrink();
    }

    // Extract first few attributes for compact display
    final displayAttributes = <String>[];
    for (final attr in attributes.take(2)) {
      // Only show first 2 attributes
      if (attr is Map && attr.containsKey('value')) {
        final value = attr['value']?.toString();
        if (value != null && value.isNotEmpty) {
          displayAttributes.add(value);
        }
      } else if (attr is String && attr.isNotEmpty) {
        displayAttributes.add(attr);
      }
    }

    if (displayAttributes.isEmpty) return const SizedBox.shrink();

    return Text(
      displayAttributes.join(' • '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.bodyStrong.copyWith(
        color: context.colors.textPrimary,
        fontSize: 9,
        height: 1.1,
      ),
    );
  }

  // Extract up to [max] attribute strings for compact display, falling back
  // to color/size when dynamic attributes are disabled or empty.
  List<String> _extractDisplayAttributes(dynamic variant, {int max = 2}) {
    final out = <String>[];
    List<dynamic>? attributes;
    if (variant is InventoryItemRow) {
      attributes = variant.variant.attributes;
    } else if (variant is ProductVariant) {
      attributes = variant.attributes;
    } else {
      try {
        final raw = _read<dynamic>(variant, 'attributes');
        if (raw is List) attributes = raw.cast<dynamic>();
      } catch (_) {}
    }

    // If attributes are not present on the incoming row, try the resolved cache
    if (attributes == null || attributes.isEmpty) {
      final id = _variantId(variant);
      if (id != null) {
        final cached = ProductGridItem._resolvedRowCache[id];
        if (cached != null) {
          attributes = cached.variant.attributes;
        }
      }
    }

    // If attributes are present (from quick row or resolved cache), use them
    if (attributes != null && attributes.isNotEmpty) {
      for (final attr in attributes) {
        if (attr is Map && attr.containsKey('value')) {
          final value = attr['value']?.toString();
          if (value != null && value.isNotEmpty) out.add(value);
        } else if (attr is String && attr.isNotEmpty) {
          out.add(attr);
        } else {
          // Support model objects with a `.value` getter
          try {
            final dyn = attr as dynamic;
            final v = dyn.value?.toString();
            if (v != null && v.isNotEmpty) out.add(v);
          } catch (_) {}
        }
        if (out.length >= max) break;
      }
      return out;
    }

    // Fallback to color/size
    String? size;
    String? color;
    if (variant is InventoryItemRow) {
      size = variant.variant.size;
      color = variant.variant.color;
    } else if (variant is ProductVariant) {
      size = variant.size;
      color = variant.color;
    } else {
      try {
        size = _read<Object?>(variant, 'size')?.toString();
        color = _read<Object?>(variant, 'color')?.toString();
      } catch (_) {}
    }

    // Try dynamic dot properties if missing
    if ((size == null || size.isEmpty)) {
      try {
        size = (variant as dynamic).size?.toString();
      } catch (_) {}
    }
    if ((color == null || color.isEmpty)) {
      try {
        color = (variant as dynamic).color?.toString();
      } catch (_) {}
    }

    // If not present on the incoming row, try the resolved cache
    if ((size == null || size.isEmpty) || (color == null || color.isEmpty)) {
      final id = _variantId(variant);
      if (id != null) {
        final cached = ProductGridItem._resolvedRowCache[id];
        if (cached != null) {
          size ??= cached.variant.size;
          color ??= cached.variant.color;
        }
      }
    }
    if (color != null && color.isNotEmpty) out.add(color);
    if (size != null && size.isNotEmpty) out.add(size);
    // Debug aid: log what we ended up extracting
    try {
      debugPrint(
        '[ProductGridItem] attrs parts=${out.join(' • ')} for id=${_variantId(variant)}',
      );
    } catch (_) {}
    return out.take(max).toList();
  }

  // _buildAttributesLine removed (attributes chip shown near quantity badge)

  Widget _borderWrapper({
    required BuildContext context,
    required Widget child,
    required Color borderColor,
  }) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1.2),
        borderRadius: BorderRadius.circular(12),
        color: c.surface,
        boxShadow: [
          BoxShadow(
            color: c.overlaySoft,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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

  // Square cover image that fills its parent (used in older layout)
  // ignore: unused_element
  Widget _buildProductImageSquare(BuildContext context, dynamic variant) {
    String? imagePath;
    if (variant is ProductVariant) {
      imagePath = variant.imagePath;
    } else if (variant is InventoryItemRow) {
      imagePath = variant.variant.imagePath;
    } else {
      imagePath = _read<String>(variant, 'image_path');
    }

    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    return SvgPicture.asset(
      'assets/svg/product_placeholder.svg',
      fit: BoxFit.cover,
      colorFilter: ColorFilter.mode(
        context.colors.textSecondary.withValues(alpha: 0.45),
        BlendMode.srcIn,
      ),
    );
  }

  // New: square image shown without cropping (contain) to satisfy request
  Widget _buildProductImageSquareContain(
    BuildContext context,
    dynamic variant,
  ) {
    String? imagePath;
    if (variant is ProductVariant) {
      imagePath = variant.imagePath;
    } else if (variant is InventoryItemRow) {
      imagePath = variant.variant.imagePath;
    } else {
      imagePath = _read<String>(variant, 'image_path');
    }

    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return FittedBox(fit: BoxFit.contain, child: Image.file(file));
      }
    }

    return FittedBox(
      fit: BoxFit.contain,
      child: SvgPicture.asset(
        'assets/svg/product_placeholder.svg',
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(
          context.colors.textSecondary.withValues(alpha: 0.45),
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

// Removed unused _VariantBadges

// Removed unused _HalfBorder

// Removed unused _HalfBorderPainter

class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  const _PressableCard({required this.child, this.onTap, this.onLongPress});

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _ctrl.addListener(() => setState(() => _scale = 1 - (_ctrl.value * 0.04)));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTapDown(_) => _ctrl.forward();
  void _handleTapUp(_) => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: () => _ctrl.reverse(),
      onLongPress: widget.onLongPress,
      child: Transform.scale(scale: _scale, child: widget.child),
    );
  }
}

import 'dart:io';

import 'package:clothes_pos/data/models/inventory_item_row.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';
import 'package:clothes_pos/presentation/design/system/app_typography.dart';
import 'package:clothes_pos/presentation/common/money.dart';
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/common/widgets/variant_attributes_display.dart';
import 'package:clothes_pos/presentation/inventory/widgets/attribute_picker.dart';
import 'package:clothes_pos/presentation/common/widgets/floating_modal.dart';
import 'package:clothes_pos/core/di/locator.dart' show sl;
import 'package:clothes_pos/data/repositories/attribute_repository.dart';
import 'package:clothes_pos/data/models/attribute.dart';
import 'package:clothes_pos/presentation/pos/utils/cart_helpers.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/pos/bloc/cart_cubit.dart';
import 'package:flutter/services.dart';

class ItemDetailsModal extends StatelessWidget {
  final InventoryItemRow row;
  const ItemDetailsModal({super.key, required this.row});

  static Future<void> open(BuildContext context, InventoryItemRow row) {
    return FloatingModal.showWithSize<void>(
      context: context,
      title: 'تفاصيل المنتج',
      size: ModalSize.medium,
      child: _ItemDetailsContent(row: row),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Not used directly; use static open for convenience
    return Container();
  }
}

class _ItemDetailsContent extends StatefulWidget {
  final InventoryItemRow row;
  const _ItemDetailsContent({required this.row});

  @override
  State<_ItemDetailsContent> createState() => _ItemDetailsContentState();
}

class _ItemDetailsContentState extends State<_ItemDetailsContent> {
  int _qty = 1;
  List<AttributeValue> _selectedAttributes = [];
  String? _validationError;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.row.variant;
    final canAdjust =
        context.read<AuthCubit>().state.user?.permissions.contains(
          'adjust_stock',
        ) ??
        false;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.row.parentName, style: AppTypography.h3),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${widget.row.variant.sku ?? ''} - ${money(context, v.salePrice)}',
                  ),
                ],
              ),
            ),
            if (v.imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(v.imagePath!),
                  width: 140,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              )
            else
              const SizedBox(width: 140, height: 140),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Attributes as chips (color / size)
        if ((v.attributes ?? []).isNotEmpty)
          VariantAttributesDisplay(attributes: v.attributes!),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Text('Quantity:'),
            const SizedBox(width: 12),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
              child: const Icon(CupertinoIcons.minus_circled),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('$_qty'),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => setState(() => _qty++),
              child: const Icon(CupertinoIcons.add_circled),
            ),
            const Spacer(),
            CupertinoButton.filled(
              onPressed: () async {
                final c = context;
                // Build attributes map from selected attributes (if any), else fall back to variant attributes
                Map<String, String>? attributesMap;
                // Build attribute map using attribute names as keys for readability
                final attrRepo = sl<AttributeRepository>();
                final src = _selectedAttributes.isNotEmpty
                    ? _selectedAttributes
                    : (v.attributes ?? []);
                if (src.isNotEmpty) {
                  final m = <String, String>{};
                  // Resolve attribute names for keys
                  // collect unique attribute ids
                  final attrIds = src
                      .map((e) => e.attributeId)
                      .toSet()
                      .toList();
                  final Map<int, String> idToName = {};
                  for (final id in attrIds) {
                    try {
                      final a = await attrRepo.getAttributeById(id);
                      idToName[id] = a.name;
                    } catch (_) {
                      idToName[id] = id.toString();
                    }
                  }
                  for (final a in src) {
                    final key =
                        idToName[a.attributeId] ?? a.attributeId.toString();
                    m[key] = a.value.toString();
                  }
                  attributesMap = m;
                }
                // Prefer CartCubit's bulk API when available and pass attributes
                // Validate required attributes: ensure one selected per attribute present on variant
                _validationError = null;
                final requiredAttrIds = (v.attributes ?? [])
                    .map((e) => e.attributeId)
                    .toSet();
                final selectedAttrIds =
                    (_selectedAttributes.isNotEmpty
                            ? _selectedAttributes
                            : (v.attributes ?? []))
                        .map((e) => e.attributeId)
                        .toSet();
                if (requiredAttrIds.isNotEmpty &&
                    !selectedAttrIds.containsAll(requiredAttrIds)) {
                  setState(
                    () => _validationError =
                        'Please select values for all attributes',
                  );
                  return;
                }
                // Guard the exact BuildContext we will use after awaits
                if (!c.mounted) return;
                try {
                  c.read<CartCubit>().addQuantity(
                    v.id!,
                    _qty,
                    v.salePrice,
                    attributes: attributesMap,
                    resolvedVariantId: v.id,
                    priceOverride: null,
                  );
                } catch (_) {
                  // Fallback to safeAddToCart loop if CartCubit isn't available
                  for (var i = 0; i < _qty; i++) {
                    if (!c.mounted) return;
                    await safeAddToCart(c, v.id!, v.salePrice);
                  }
                }
                HapticFeedback.selectionClick();
                if (!c.mounted) return;
                Navigator.of(c).pop();
              },
              child: const Text('Add to Cart'),
            ),
          ],
        ),
        if (_validationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _validationError!,
              style: const TextStyle(color: CupertinoColors.destructiveRed),
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        if (canAdjust)
          Row(
            children: [
              CupertinoButton(onPressed: () {}, child: const Text('Edit')),
            ],
          ),
        const SizedBox(height: AppSpacing.xs),
        // Attribute selection action
        if ((v.attributes ?? []).isNotEmpty)
          Row(
            children: [
              CupertinoButton(
                onPressed: () async {
                  final attrRepo = sl<AttributeRepository>();
                  final c = context;
                  if (!c.mounted) return;
                  final picked =
                      await showCupertinoModalPopup<List<AttributeValue>>(
                        context: c,
                        builder: (ctx) => AttributePicker(
                          loadAttributes: () async =>
                              await attrRepo.getAllAttributes(),
                          loadAttributeValues: (int id) async =>
                              await attrRepo.getAttributeValues(id),
                          initialSelected: _selectedAttributes,
                          onDone: (sel) => Navigator.of(ctx).pop(sel),
                        ),
                      );
                  if (!c.mounted) return;
                  if (picked != null) {
                    setState(() => _selectedAttributes = picked);
                  }
                },
                child: Text(
                  _selectedAttributes.isEmpty
                      ? 'Select attributes'
                      : 'Edit attributes',
                ),
              ),
            ],
          ),
      ],
    );
  }
}

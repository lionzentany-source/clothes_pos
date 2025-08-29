import 'package:clothes_pos/presentation/inventory/bloc/inventory_cubit.dart';
import 'package:clothes_pos/data/models/inventory_item_row.dart';
import 'package:clothes_pos/presentation/common/money.dart';
import 'package:flutter/cupertino.dart';
import 'product_editor_screen.dart';
import 'package:clothes_pos/presentation/common/widgets/action_button.dart';

import 'package:clothes_pos/presentation/purchases/screens/purchase_editor_screen.dart';
import 'package:clothes_pos/presentation/purchases/screens/purchase_history_screen.dart';

import 'package:clothes_pos/l10n_clean/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/core/auth/permissions.dart';
import 'package:clothes_pos/presentation/common/view_only_banner.dart';
import 'package:clothes_pos/presentation/common/widgets/variant_attributes_display.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<InventoryCubit>().load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state.user;
    final perms = auth?.permissions ?? const <String>[];
    final canAdjust = perms.contains(AppPermissions.adjustStock);
    final canPurchase = perms.contains(AppPermissions.performPurchases);
    final canAddProduct =
        canAdjust; // product creation/editing tied to adjustStock
    return CupertinoPageScaffold(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(AppLocalizations.of(context).inventoryTab),
            transitionBetweenRoutes: false,
            trailing: ActionButton(
              label: AppLocalizations.of(context).addAction,
              onPressed: !(canAddProduct || canPurchase)
                  ? null
                  : () async {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (sheetCtx) {
                          final l = AppLocalizations.of(context);
                          final actions = <Widget>[];
                          if (canAddProduct) {
                            actions.add(
                              CupertinoActionSheetAction(
                                onPressed: () async {
                                  Navigator.of(sheetCtx).pop();
                                  final cubit = context.read<InventoryCubit>();
                                  final q = _controller.text;
                                  final refreshed = await Navigator.of(context)
                                      .push(
                                        CupertinoPageRoute(
                                          builder: (_) =>
                                              const ProductEditorScreen(),
                                        ),
                                      );
                                  if (!mounted) return;
                                  if (refreshed == true) cubit.load(query: q);
                                },
                                child: Text(l.addItem),
                              ),
                            );
                          }
                          if (canPurchase) {
                            actions.add(
                              CupertinoActionSheetAction(
                                onPressed: () async {
                                  Navigator.of(sheetCtx).pop();
                                  final cubit = context.read<InventoryCubit>();
                                  final q = _controller.text;
                                  final refreshed = await Navigator.of(context)
                                      .push(
                                        CupertinoPageRoute(
                                          builder: (_) =>
                                              const PurchaseEditorScreen(),
                                        ),
                                      );
                                  if (!mounted) return;
                                  if (refreshed == true) cubit.load(query: q);
                                },
                                child: Text(l.purchaseInvoiceTitle),
                              ),
                            );
                          }
                          actions.add(
                            CupertinoActionSheetAction(
                              onPressed: () async {
                                Navigator.of(sheetCtx).pop();
                                await Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (_) =>
                                        const PurchaseHistoryScreen(),
                                  ),
                                );
                              },
                              child: Text(l.purchasesTotalPeriod),
                            ),
                          );
                          return CupertinoActionSheet(
                            title: Text(l.addAction),
                            message: !(canAddProduct || canPurchase)
                                ? const Text(
                                    'عرض فقط: لا تملك صلاحيات الإضافة',
                                    textDirection: TextDirection.rtl,
                                  )
                                : null,
                            actions: actions,
                            cancelButton: CupertinoActionSheetAction(
                              onPressed: () => Navigator.of(sheetCtx).pop(),
                              isDefaultAction: true,
                              child: Text(l.cancel),
                            ),
                          );
                        },
                      );
                    },
            ),
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (!canAdjust)
                  const ViewOnlyBanner(
                    message: 'عرض فقط: لا تملك صلاحية تعديل المخزون',
                    margin: EdgeInsets.fromLTRB(12, 8, 12, 4),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: CupertinoSearchTextField(
                    controller: _controller,
                    onChanged: (v) => context.read<InventoryCubit>().load(
                      query: v,
                      brandId: context.read<InventoryCubit>().state.brandId,
                    ),
                    placeholder: AppLocalizations.of(
                      context,
                    ).searchProductPlaceholder,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      // تم حذف زر التصفية والعلامات التجارية
                    ],
                  ),
                ),
                BlocBuilder<InventoryCubit, InventoryState>(
                  builder: (context, state) {
                    if (state.loading) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CupertinoActivityIndicator()),
                      );
                    }
                    // Always show a message if no items found after clearing filters
                    if (state.items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).notFound,
                            style: const TextStyle(
                              fontSize: 16,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final row in state.items) ...[
                          _InventoryRow(
                            row: row,
                            canAdjust: canAdjust,
                            onTap: () async {
                              if (!canAdjust) return;
                              final cubit = context.read<InventoryCubit>();
                              final q = _controller.text;
                              final refreshed = await Navigator.of(context)
                                  .push(
                                    CupertinoPageRoute(
                                      builder: (_) => ProductEditorScreen(
                                        parentId: row.variant.parentProductId,
                                      ),
                                    ),
                                  );
                              if (!mounted) return;
                              if (refreshed == true) cubit.load(query: q);
                            },
                          ),
                          Container(
                            height: 1,
                            color: CupertinoColors.separator,
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryRow extends StatelessWidget {
  final InventoryItemRow row;
  final bool canAdjust;
  final VoidCallback onTap;
  const _InventoryRow({
    required this.row,
    required this.canAdjust,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final v = row.variant;
    final brand = row.brandName;
    final l = AppLocalizations.of(context);
    final parts = <String>[];
    if (brand != null && brand.trim().isNotEmpty) parts.add(brand);
    if ((v.size ?? '').isNotEmpty) parts.add('${l.sizeLabel} ${v.size}');
    if ((v.color ?? '').isNotEmpty) parts.add('${l.colorLabel} ${v.color}');
    parts.add('${l.skuLabel} ${v.sku ?? ''}');
    if ((v.barcode ?? '').isNotEmpty)
      parts.add('${l.barcodeLabel} ${v.barcode}');
    final subtitle = parts.join('  •  ');
    final qty =
        '${l.quantityLabel} ${v.quantity} - ${l.priceLabel} ${money(context, v.salePrice)}';
    final style = row.isLowStock
        ? const TextStyle(color: CupertinoColors.systemRed)
        : const TextStyle(color: CupertinoColors.label);
    return CupertinoListTile(
      onTap: canAdjust ? onTap : null,
      title: Text(
        row.parentName,
        style: style,
        textDirection: TextDirection.rtl,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, textDirection: TextDirection.rtl),
          VariantAttributesDisplay(attributes: v.attributes),
        ],
      ),
      trailing: Text(qty, style: style),
    );
  }
}

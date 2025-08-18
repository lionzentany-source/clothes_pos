import 'package:clothes_pos/presentation/inventory/bloc/inventory_cubit.dart';
import 'package:clothes_pos/data/models/inventory_item_row.dart';
import 'package:clothes_pos/presentation/common/money.dart';
import 'package:flutter/cupertino.dart';
import 'product_editor_screen.dart';
import 'package:clothes_pos/data/repositories/brand_repository.dart';
import 'package:clothes_pos/data/models/brand.dart';
import 'brand_picker_sheet.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/presentation/purchases/screens/purchase_editor_screen.dart';
import 'package:clothes_pos/presentation/purchases/screens/purchase_history_screen.dart';

import 'package:clothes_pos/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/core/auth/permissions.dart';
import 'package:clothes_pos/presentation/common/view_only_banner.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final _controller = TextEditingController();
  Brand? _selectedBrand;
  List<Brand> _brands = const [];

  @override
  void initState() {
    super.initState();
    _loadBrands();
    context.read<InventoryCubit>().load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    final repo = sl<BrandRepository>();
    final list = await repo.listAll(limit: 500);
    if (!mounted) return;
    setState(() => _brands = list);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state.user;
    final perms = auth?.permissions ?? const [];
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
            largeTitle: Text(
              AppLocalizations.of(context)?.inventoryTab ?? 'Inventory',
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
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
                                child: Text(l?.addItem ?? 'Add Product'),
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
                                child: Text(
                                  l?.purchaseInvoiceTitle ?? 'Purchase Invoice',
                                ),
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
                              child: Text(
                                l?.purchasesTotalPeriod ?? 'Purchases',
                              ),
                            ),
                          );
                          return CupertinoActionSheet(
                            title: Text(l?.addAction ?? 'Add'),
                            message: !(canAddProduct || canPurchase)
                                ? Text(
                                    (l?.viewOnlyAdjustStock ??
                                        'View only: no permission to adjust stock'),
                                  )
                                : null,
                            actions: actions,
                            cancelButton: CupertinoActionSheetAction(
                              onPressed: () => Navigator.of(sheetCtx).pop(),
                              isDefaultAction: true,
                              child: Text(l?.cancel ?? 'Cancel'),
                            ),
                          );
                        },
                      );
                    },
              child: Icon(
                CupertinoIcons.add,
                color: (canAddProduct || canPurchase)
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.inactiveGray,
              ),
            ),
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (!canAdjust)
                  ViewOnlyBanner(
                    message:
                        AppLocalizations.of(context)?.viewOnlyAdjustStock ??
                        'عرض فقط: لا تملك صلاحية تعديل المخزون',
                    margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: CupertinoSearchTextField(
                    controller: _controller,
                    onChanged: (v) => context.read<InventoryCubit>().load(
                      query: v,
                      brandId: context.read<InventoryCubit>().state.brandId,
                    ),
                    placeholder:
                        AppLocalizations.of(
                          context,
                        )?.searchProductsPlaceholder ??
                        'Search products...',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    onPressed: () async {
                      await showCupertinoModalPopup(
                        context: context,
                        builder: (ctx) => BrandPickerSheet(
                          brands: _brands,
                          onSelected: (b) {
                            Navigator.of(ctx).pop();
                            setState(() => _selectedBrand = b);
                            context.read<InventoryCubit>().load(
                              query: _controller.text,
                              brandId: b.id,
                            );
                          },
                          onAddNew: () async {},
                          onClear: () {
                            Navigator.of(ctx).pop();
                            setState(() => _selectedBrand = null);
                            context.read<InventoryCubit>().load(
                              query: _controller.text,
                              brandId: null,
                            );
                          },
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.tag, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          _selectedBrand?.name ??
                              (AppLocalizations.of(context)?.select ??
                                  'Select'),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
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
                    if (state.items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)?.notFound ??
                                'Not Found',
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
    final subtitle = [
      if (brand != null && brand.trim().isNotEmpty) brand,
      if ((v.size ?? '').isNotEmpty) '${l?.sizeLabel ?? 'Size:'} ${v.size}',
      if ((v.color ?? '').isNotEmpty) '${l?.colorLabel ?? 'Color:'} ${v.color}',
      '${l?.skuLabel ?? 'SKU:'} ${v.sku}',
      if ((v.barcode ?? '').isNotEmpty)
        '${l?.barcodeLabel ?? 'Barcode:'} ${v.barcode}',
    ].join('  •  ');
    final qty =
        '${l?.quantityLabel ?? 'Qty:'} ${v.quantity} — ${l?.priceLabel ?? 'Price:'} ${money(context, v.salePrice)}';
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
      subtitle: Text(subtitle, textDirection: TextDirection.rtl),
      trailing: Text(qty, style: style),
    );
  }
}

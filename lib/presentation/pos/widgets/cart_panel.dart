import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/pos/bloc/pos_cubit.dart';
import 'package:clothes_pos/presentation/inventory/bloc/inventory_cubit.dart';
import 'package:clothes_pos/presentation/common/money.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';
import 'package:clothes_pos/presentation/design/system/app_typography.dart';
import 'package:clothes_pos/presentation/pos/widgets/quantity_control.dart';
import 'package:clothes_pos/presentation/pos/widgets/empty_state.dart';
import 'package:clothes_pos/presentation/pos/widgets/customer_selection_modal.dart';
import 'package:clothes_pos/presentation/common/widgets/variant_attributes_display.dart';
import 'package:clothes_pos/data/models/customer.dart';
import 'package:clothes_pos/data/repositories/cash_repository.dart';
import 'package:clothes_pos/core/di/locator.dart';

class CartPanel extends StatefulWidget {
  final void Function(CartLine) onEdit;
  final VoidCallback onCheckout;
  final bool canCheckout;
  final Customer? selectedCustomer;
  final Function(Customer?) onCustomerChanged;
  final VoidCallback? onSaleCompleted;

  /// Whether to show the footer summary (items / total / checkout).
  /// Set to false when a parent widget already renders a summary & checkout
  /// action to avoid duplication (e.g. collapsed panel handle in narrow POS
  /// layout).
  final bool showSummaryFooter;
  const CartPanel({
    super.key,
    required this.onEdit,
    required this.onCheckout,
    required this.canCheckout,
    this.selectedCustomer,
    required this.onCustomerChanged,
    this.onSaleCompleted,
    this.showSummaryFooter = true,
  });
  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  final _listKey = GlobalKey<AnimatedListState>();
  List<int> _variantIds = [];
  Map<int, Map<String, Object?>> _variantRows = {};
  bool _initialized = false;
  final CashRepository _cashRepo = sl<CashRepository>();
  double _currentCash = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCurrentCash();
  }

  Future<void> _loadCurrentCash() async {
    try {
      final session = await _cashRepo.getOpenSession();
      if (session != null) {
        final summary = await _cashRepo.getSessionSummary(session['id'] as int);
        if (mounted) {
          setState(() {
            _currentCash =
                (summary['expected_cash'] as num?)?.toDouble() ?? 0.0;
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void refreshCash() {
    _loadCurrentCash();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final cart = context.read<PosCubit>().state.cart;
      _variantIds = cart.map((e) => e.variantId).toList();
      // Prefetch variant rows for cart items to avoid N+1 DB calls per line
      _prefetchVariantRows(_variantIds);
      _initialized = true;
    }
  }

  Future<void> _prefetchVariantRows(List<int> ids) async {
    try {
      if (ids.isEmpty) return;
      final repo = context.read<PosCubit>().products;
      // Use getVariantsByIds which populates attribute values when the feature
      // flag is enabled. Convert to a lightweight row map used by CartLineItem.
      final variants = await repo.dao.getVariantsByIds(ids);
      setState(() {
        _variantRows = {
          for (var v in variants)
            v.id!: {
              'size': v.size,
              'color': v.color,
              'sku': v.sku,
              'attributes': v.attributes ?? [],
            },
        };
      });
    } catch (_) {}
  }

  void _updateLines(List<CartLine> newCart) {
    final listState = _listKey.currentState;
    final newIds = newCart.map((e) => e.variantId).toList();
    if (listState == null) {
      _variantIds = newIds;
      return;
    }
    // removals
    for (var i = _variantIds.length - 1; i >= 0; i--) {
      final id = _variantIds[i];
      if (!newIds.contains(id)) {
        _variantIds.removeAt(i);
        listState.removeItem(
          i,
          (ctx, anim) => _AnimatedCartLineWrapper(
            animation: anim,
            child: const SizedBox.shrink(),
          ),
          duration: const Duration(milliseconds: 200),
        );
      }
    }
    // insertions in order
    for (var i = 0; i < newIds.length; i++) {
      final id = newIds[i];
      if (!_variantIds.contains(id)) {
        _variantIds.insert(i, id);
        listState.insertItem(i, duration: const Duration(milliseconds: 200));
      }
    }
    // updates require no action; individual line widgets reselect state.
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.basket,
                style: AppTypography.bodyStrong.copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'الرصيد الحالي: ${money(context, _currentCash)}',
                style: AppTypography.body.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              // Customer selection button
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                color: widget.selectedCustomer != null
                    ? CupertinoColors.activeGreen.withOpacity(0.1)
                    : CupertinoColors.systemGrey6,
                onPressed: () {
                  CustomerSelectionModal.show(
                    context: context,
                    currentCustomer: widget.selectedCustomer,
                    onCustomerSelected: widget.onCustomerChanged,
                  );
                },
                child: Row(
                  children: [
                    Icon(
                      widget.selectedCustomer != null
                          ? CupertinoIcons.person_fill
                          : CupertinoIcons.person,
                      size: 16,
                      color: widget.selectedCustomer != null
                          ? CupertinoColors.activeGreen
                          : CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        widget.selectedCustomer?.name ?? 'اختيار عميل',
                        style: TextStyle(
                          fontSize: AppTypography.fs14,
                          color: widget.selectedCustomer != null
                              ? CupertinoColors.activeGreen
                              : CupertinoColors.systemGrey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.selectedCustomer != null)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(20, 20),
                        onPressed: () => widget.onCustomerChanged(null),
                        child: const Icon(
                          CupertinoIcons.clear_circled,
                          size: 16,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocConsumer<PosCubit, PosState>(
            listener: (context, state) => _updateLines(state.cart),
            builder: (context, state) {
              if (state.cart.isEmpty && _variantIds.isEmpty) {
                return const EmptyState(
                  title: 'السلة فارغة',
                  message: 'أضف منتجات بالنقر على عنصر من القائمة.',
                  icon: CupertinoIcons.cart,
                );
              }
              return AnimatedList(
                key: _listKey,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                initialItemCount: _variantIds.length,
                itemBuilder: (context, index, animation) {
                  final id = _variantIds[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == _variantIds.length - 1
                          ? 0
                          : AppSpacing.xxs + 2,
                    ),
                    child: _AnimatedCartLineWrapper(
                      animation: animation,
                      child: CartLineItem(
                        variantId: id,
                        onEdit: widget.onEdit,
                        prefetchRows: _variantRows,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(height: 1, color: c.border),
        if (widget.showSummaryFooter)
          BlocBuilder<PosCubit, PosState>(
            builder: (context, state) {
              final total = state.cart.fold<double>(
                0,
                (s, l) =>
                    s + (l.price * l.quantity) - l.discountAmount + l.taxAmount,
              );
              return Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(color: c.surface),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // عدد المنتجات في السلة
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: c.border),
                          ),
                          child: Text(
                            'عدد المنتجات: ${state.cart.fold<int>(0, (sum, l) => sum + l.quantity).toString().padLeft(3, '0')}',
                            style: AppTypography.bodyStrong.copyWith(
                              color: c.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${l.posTotal}  ${money(context, total)}',
                          style: AppTypography.bodyStrong.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    CupertinoButton.filled(
                      onPressed: widget.canCheckout ? widget.onCheckout : null,
                      child: Text(l.checkout),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class CartLineItem extends StatelessWidget {
  final int variantId;
  final void Function(CartLine) onEdit;
  final Map<int, Map<String, Object?>> prefetchRows;
  const CartLineItem({
    super.key,
    required this.variantId,
    required this.onEdit,
    this.prefetchRows = const {},
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PosCubit, PosState, CartLine?>(
      selector: (s) {
        try {
          return s.cart.firstWhere((l) => l.variantId == variantId);
        } catch (_) {
          return null;
        }
      },
      builder: (context, line) {
        if (line == null) return const SizedBox.shrink();
        final c = context.colors;
        final posCubit = context.read<PosCubit>();
        final nameFuture = posCubit.resolveVariantName(line.variantId);
        final lineTotal = money(
          context,
          line.price * line.quantity - line.discountAmount + line.taxAmount,
        );
        // Extract product variables from state
        String? size;
        String? color;
        String? sku;
        final inventoryState = context.read<InventoryCubit>().state;
        final item =
            inventoryState.items
                .where((i) => i.variant.id == line.variantId)
                .isNotEmpty
            ? inventoryState.items.firstWhere(
                (i) => i.variant.id == line.variantId,
              )
            : null;
        if (item != null) {
          size = item.variant.size;
          color = item.variant.color;
          sku = item.variant.sku;
        }
        // If not found, fallback to pre-fetched variant rows, else DAO
        Future<Map<String, String?>>? variablesFuture;
        if (item == null) {
          final row = prefetchRows[variantId];
          if (row != null) {
            variablesFuture = Future.value({
              'size': row['size']?.toString(),
              'color': row['color']?.toString(),
              'sku': row['sku']?.toString(),
            });
          } else {
            final repo = context.read<PosCubit>().products;
            variablesFuture = repo.dao.getVariantRowById(line.variantId).then((
              row,
            ) {
              if (row == null) return {};
              return {
                'size': row['size']?.toString(),
                'color': row['color']?.toString(),
                'sku': row['sku']?.toString(),
              };
            });
          }
        }
        return Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: c.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<String?>(
                          future: nameFuture,
                          builder: (ctx, snap) {
                            final name = snap.data ?? 'Variant';
                            if (item != null) {
                              final variables = [
                                if (color != null && color.isNotEmpty)
                                  'اللون: $color',
                                if (size != null && size.isNotEmpty)
                                  'المقاس: $size',
                                if (sku != null && sku.isNotEmpty) 'SKU: $sku',
                              ].join(' • ');
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: AppTypography.bodyStrong.copyWith(
                                      color: c.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (variables.isNotEmpty)
                                    Text(
                                      variables,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodyStrong.copyWith(
                                        color: c.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  // Render dynamic attribute chips when available
                                  if ((prefetchRows[variantId]?['attributes']
                                              as List?)
                                          ?.isNotEmpty ??
                                      false)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: VariantAttributesDisplay(
                                        // prefetchRows stores attributes as a List<AttributeValue>
                                        attributes:
                                            (prefetchRows[variantId]!['attributes']
                                                    as List)
                                                .cast(),
                                      ),
                                    )
                                  else if (item != null &&
                                      item.variant.attributes?.isNotEmpty ==
                                          true)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: VariantAttributesDisplay(
                                        attributes: item.variant.attributes!,
                                      ),
                                    ),
                                ],
                              );
                            } else if (variablesFuture != null) {
                              return FutureBuilder<Map<String, String?>>(
                                future: variablesFuture,
                                builder: (ctx, varSnap) {
                                  final vars = varSnap.data ?? {};
                                  final variables = [
                                    if (vars['color'] != null &&
                                        vars['color']!.isNotEmpty)
                                      'اللون: ${vars['color']}',
                                    if (vars['size'] != null &&
                                        vars['size']!.isNotEmpty)
                                      'المقاس: ${vars['size']}',
                                    if (vars['sku'] != null &&
                                        vars['sku']!.isNotEmpty)
                                      'SKU: ${vars['sku']}',
                                  ].join(' • ');
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: AppTypography.bodyStrong
                                            .copyWith(
                                              color: c.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (variables.isNotEmpty)
                                        Text(
                                          variables,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.bodyStrong
                                              .copyWith(
                                                color: c.textSecondary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                    ],
                                  );
                                },
                              );
                            } else {
                              return Text(
                                name,
                                style: AppTypography.bodyStrong.copyWith(
                                  color: c.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                          child: Text(
                            '${money(context, line.price)} × ${line.quantity} = $lineTotal',
                            key: ValueKey(
                              'q${line.variantId}-${line.quantity}-${line.discountAmount}-${line.taxAmount}',
                            ),
                            style: AppTypography.caption.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  QuantityControl(
                    value: line.quantity,
                    onDecrement: () => context.read<PosCubit>().changeQty(
                      line.variantId,
                      line.quantity - 1,
                    ),
                    onIncrement: () => context.read<PosCubit>().changeQty(
                      line.variantId,
                      line.quantity + 1,
                    ),
                  ),
                  Column(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => onEdit(line),
                        child: const Icon(CupertinoIcons.pencil, size: 20),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () =>
                            context.read<PosCubit>().removeLine(line.variantId),
                        child: const Icon(
                          CupertinoIcons.delete_simple,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SizeTransition(
                    sizeFactor: anim,
                    axisAlignment: -1,
                    child: child,
                  ),
                ),
                child: (line.note != null && line.note!.isNotEmpty)
                    ? Padding(
                        key: ValueKey('n${line.variantId}-${line.note}'),
                        padding: const EdgeInsets.only(top: AppSpacing.xxs),
                        child: Text(
                          line.note!,
                          style: AppTypography.caption.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedCartLineWrapper extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const _AnimatedCartLineWrapper({
    required this.animation,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: .98, end: 1).animate(curved),
        child: SizeTransition(
          sizeFactor: curved,
          axisAlignment: -1,
          child: child,
        ),
      ),
    );
  }
}

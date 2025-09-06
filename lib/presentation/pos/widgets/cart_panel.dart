import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/pos/bloc/pos_cubit.dart';
import 'package:clothes_pos/presentation/pos/bloc/cart_cubit.dart';
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
import 'package:clothes_pos/presentation/common/widgets/app_buttons.dart';
import 'package:clothes_pos/presentation/common/widgets/floating_modal.dart';
import 'package:clothes_pos/presentation/common/overlay/app_toast.dart';
import 'package:clothes_pos/data/models/customer.dart';
import 'package:clothes_pos/data/repositories/cash_repository.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/held_sales_repository.dart';

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
  bool _expanded = true; // for narrow layout collapse/expand
  // Held-sales are persisted via HeldSalesRepository so slots survive restarts.
  final HeldSalesRepository _heldRepo = sl<HeldSalesRepository>();
  // Cached held-sales summaries loaded when opening the held-sales modal.
  List<Map<String, Object?>> _heldSales = [];
  int _heldCount = 0; // number of held invoices for dynamic UI

  @override
  void initState() {
    super.initState();
    _loadCurrentCash();
    _refreshHeldCount();
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

  Future<void> _handleHoldOrShowWaiting(BuildContext context) async {
    final c = context;
    final l = AppLocalizations.of(c);

    // Get cubit references before any async operations
    late final CartCubit cartCubit;
    late final PosCubit posCubit;
    try {
      cartCubit = c.read<CartCubit>();
      posCubit = c.read<PosCubit>();
    } catch (e) {
      return; // Failed to get cubits, exit early
    }

    // Check if we have items in cart to hold
    List<Map<String, Object?>> items = [];
    try {
      final cart = cartCubit.state.cart;
      items = cart
          .map(
            (ci) => {
              'variant_id': ci.variantId,
              'quantity': ci.quantity,
              'price': ci.price,
              'attributes': ci.attributes,
              'price_override': ci.priceOverride,
              'resolved_variant_id': ci.resolvedVariantId,
            },
          )
          .toList();
    } catch (_) {
      // Fallback to PosCubit's CartLine list
      final currentLines = posCubit.state.cart;
      items = currentLines
          .map(
            (l) => {
              'variant_id': l.variantId,
              'quantity': l.quantity,
              'price': l.price,
              'attributes': (l as dynamic).attributes,
              'price_override': (l as dynamic).priceOverride,
            },
          )
          .toList();
    }

    if (items.isEmpty) {
      // No items to hold, show waiting sales instead
      await _showWaitingSalesModal(c);
      return;
    }

    // Ask for optional hold name
    final nameCtrl = TextEditingController();
    final name = await showCupertinoDialog<String?>(
      context: c,
      builder: (dctx) => CupertinoAlertDialog(
        title: const Text('حفظ فاتورة للانتظار'),
        content: Column(
          children: [
            const SizedBox(height: 12),
            const Text(
              'يمكنك إدخال اسم مخصص لهذه الفاتورة أو تركه فارغاً لاستخدام الوقت الحالي',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: nameCtrl,
              placeholder: 'اسم الفاتورة (اختياري)',
              textAlign: TextAlign.center,
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey4),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'عدد العناصر في السلة: ${items.length}',
                style: const TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dctx).pop(null),
            child: const Text('إلغاء'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(
              dctx,
            ).pop(nameCtrl.text.trim().isEmpty ? '' : nameCtrl.text.trim()),
            child: const Text('حفظ للانتظار'),
          ),
        ],
      ),
    );
    if (!c.mounted) return;
    if (name == null) return; // user cancelled

    final slotName = name.isEmpty
        ? 'انتظار @ ${DateTime.now().toIso8601String().split('T')[0]} ${DateTime.now().toIso8601String().split('T')[1].split('.')[0]}'
        : name;

    // Save held snapshot to DB
    bool saved = false;
    try {
      await _heldRepo.saveHeldSale(slotName, items);
      saved = true;
    } catch (e) {
      if (c.mounted) {
        await showCupertinoDialog<void>(
          context: c,
          builder: (err) => CupertinoAlertDialog(
            title: const Text('تعذر الحفظ'),
            content: Text('فشل حفظ الفاتورة في الانتظار:\n$e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('موافق'),
                onPressed: () => Navigator.of(err).pop(),
              ),
            ],
          ),
        );
      }
    }
    if (!saved) return;
    await _refreshHeldCount();

    // Clear active cart
    try {
      cartCubit.clear();
    } catch (_) {
      try {
        final lines = List<CartLine>.from(posCubit.state.cart);
        for (final l in lines) {
          posCubit.removeLine(l.variantId);
        }
      } catch (_) {}
    }

    if (c.mounted) {
      AppToast.show(c, message: l.holdSaved, type: ToastType.success);
    }
  }

  Future<void> _showWaitingSalesModal(BuildContext context) async {
    // Load persisted held-sales summaries
    try {
      _heldSales = await _heldRepo.listHeldSales();
    } catch (_) {
      _heldSales = [];
    }
    if (mounted) setState(() => _heldCount = _heldSales.length);

    if (!context.mounted) return;
    await FloatingModal.showWithSize<void>(
      context: context,
      title: 'فواتير الانتظار',
      size: ModalSize.medium,
      child: Container(
        padding: const EdgeInsets.all(16),
        // Pass the host (CartPanel) context to the body so actions can access Bloc providers
        child: _buildWaitingSalesBody(context),
      ),
    );
  }

  Widget _buildWaitingSalesBody(BuildContext hostCtx) {
    if (_heldSales.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.clock,
            size: 64,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد فواتير في الانتظار',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'سيتم عرض الفواتير المحفوظة هنا عندما تقوم بوضع فاتورة في الانتظار',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              child: const Text('إغلاق'),
              onPressed: () => Navigator.of(hostCtx).maybePop(),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.clock_fill,
                color: CupertinoColors.systemBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'عدد الفواتير في الانتظار: ${_heldSales.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label,
                ),
              ),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _heldSales.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (modalCtx, i) {
              final slot = _heldSales[i];
              // Use modalCtx for Navigator (modal), hostCtx for Cubits
              return _buildHeldSaleTile(hostCtx, modalCtx, slot);
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            child: const Text('إغلاق'),
            onPressed: () => Navigator.of(hostCtx).maybePop(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeldSaleTile(
    BuildContext hostCtx,
    BuildContext modalCtx,
    Map<String, Object?> slot,
  ) {
    final name = slot['name'] as String;
    final timestamp = slot['ts'] as String;
    // Query uses alias items_count
    final itemCount = (slot['items_count'] as int?) ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () async {
          final nav = Navigator.of(modalCtx);
          await _restoreWaitingSale(hostCtx, slot);
          if (!modalCtx.mounted) return;
          await nav.maybePop();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  CupertinoIcons.doc_text,
                  color: CupertinoColors.systemBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'عدد العناصر: $itemCount',
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timestamp,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.tertiaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  SizedBox(
                    width: 80,
                    height: 32,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      color: CupertinoColors.systemGreen,
                      borderRadius: BorderRadius.circular(6),
                      onPressed: () async {
                        final nav = Navigator.of(modalCtx);
                        await _restoreWaitingSale(hostCtx, slot);
                        if (!modalCtx.mounted) return;
                        await nav.maybePop();
                      },
                      child: const Text(
                        'استعادة',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 80,
                    height: 32,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      color: CupertinoColors.systemRed,
                      borderRadius: BorderRadius.circular(6),
                      onPressed: () async {
                        final confirmed = await showCupertinoDialog<bool>(
                          context: modalCtx,
                          builder: (ddctx) {
                            return CupertinoAlertDialog(
                              title: const Text('تأكيد الحذف'),
                              content: Text(
                                'هل تريد حذف فاتورة الانتظار: "$name"؟',
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  onPressed: () =>
                                      Navigator.of(ddctx).pop(false),
                                  child: const Text('إلغاء'),
                                ),
                                CupertinoDialogAction(
                                  isDestructiveAction: true,
                                  onPressed: () =>
                                      Navigator.of(ddctx).pop(true),
                                  child: const Text('حذف'),
                                ),
                              ],
                            );
                          },
                        );
                        if (!modalCtx.mounted) return;
                        if (confirmed == true) {
                          try {
                            final nav = Navigator.of(modalCtx);
                            await _heldRepo.deleteHeldSale(slot['id'] as int);
                            _heldSales = await _heldRepo.listHeldSales();
                            if (!modalCtx.mounted) return;
                            await nav.maybePop();
                            if (!hostCtx.mounted) return;
                            await _showWaitingSalesModal(hostCtx);
                          } catch (e) {
                            if (!modalCtx.mounted) return;
                            await showCupertinoDialog<void>(
                              context: modalCtx,
                              builder: (errCtx) {
                                return CupertinoAlertDialog(
                                  title: const Text('خطأ'),
                                  content: Text('فشل في حذف الفاتورة: $e'),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text('موافق'),
                                      onPressed: () =>
                                          Navigator.of(errCtx).pop(),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        }
                      },
                      child: const Text(
                        'حذف',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _restoreWaitingSale(
    BuildContext context,
    Map<String, Object?> slot,
  ) async {
    // Get cubit references before any async operations
    late final CartCubit cartCubit;
    late final PosCubit posCubit;
    try {
      cartCubit = context.read<CartCubit>();
      posCubit = context.read<PosCubit>();
    } catch (e) {
      return; // Failed to get cubits, exit early
    }

    // Restore: clear active cart in both cubits, then fetch saved items and add
    try {
      cartCubit.clear();
    } catch (_) {}
    try {
      final lines = List<CartLine>.from(posCubit.state.cart);
      for (final l in lines) {
        posCubit.removeLine(l.variantId);
      }
    } catch (_) {}

    // Fetch items for this held slot
    List<Map<String, Object?>> savedItems = [];
    try {
      savedItems = await _heldRepo.getItemsForHeldSale(slot['id'] as int);
    } catch (_) {
      savedItems = [];
    }

    // Build CartItems from saved rows
    final items = savedItems
        .map(
          (it) => CartItem(
            variantId: (it['resolved_variant_id'] ?? it['variant_id']) as int,
            quantity: (it['quantity'] as int?) ?? 1,
            price: (it['price'] as num?)?.toDouble() ?? 0.0,
            attributes: () {
              final raw = it['attributes'];
              if (raw == null) return null;
              try {
                if (raw is String) {
                  final dec = jsonDecode(raw);
                  if (dec is Map) {
                    return Map<String, String>.from(
                      dec.map((k, v) => MapEntry(k.toString(), v?.toString())),
                    );
                  }
                  if (dec is List) {
                    final out = <String, String>{};
                    for (final e in dec) {
                      if (e is Map) {
                        final name = e['name']?.toString();
                        final value = e['value']?.toString();
                        if (name != null && value != null) out[name] = value;
                      } else if (e is String) {
                        out[e] = e;
                      }
                    }
                    return out.isEmpty ? null : out;
                  }
                }
                if (raw is Map) return raw.cast<String, String>();
              } catch (_) {}
              return null;
            }(),
            resolvedVariantId:
                (it['resolved_variant_id'] as int?) ??
                (it['resolvedVariantId'] as int?),
            priceOverride: (it['price_override'] ?? it['priceOverride']) is num
                ? ((it['price_override'] ?? it['priceOverride']) as num)
                      .toDouble()
                : null,
          ),
        )
        .toList();

    // Seed CartCubit in one operation
    try {
      cartCubit.seedCart(items);
    } catch (_) {}

    // Populate PosCubit to keep checkout logic in sync
    for (final item in items) {
      final qty = item.quantity;
      final price = (item.priceOverride ?? item.price);
      for (var k = 0; k < qty; k++) {
        try {
          await posCubit.addToCart(item.variantId, price);
        } catch (_) {}
      }
    }

    // Delete held sale now that it's restored
    try {
      await _heldRepo.deleteHeldSale(slot['id'] as int);
    } catch (_) {}
    await _refreshHeldCount();
  }

  Future<void> _refreshHeldCount() async {
    try {
      final list = await _heldRepo.listHeldSales();
      if (mounted) setState(() => _heldCount = list.length);
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      // Prefer CartCubit if available, else fallback to PosCubit's cart lines
      try {
        final cartCubit = context.read<CartCubit>();
        _variantIds = cartCubit.state.cart.map((e) => e.variantId).toList();
      } catch (_) {
        final cart = context.read<PosCubit>().state.cart;
        _variantIds = cart.map((e) => e.variantId).toList();
      }
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
      if (!mounted) return;
      setState(() {
        final map = <int, Map<String, Object?>>{};
        for (final v in variants) {
          final vid = v.id;
          if (vid == null) continue;
          map[vid] = {
            'size': v.size,
            'color': v.color,
            'sku': v.sku,
            'attributes': v.attributes ?? [],
          };
        }
        _variantRows = map;
      });
    } catch (_) {}
  }

  void _updateLines(List<CartLine> newCart) {
    // debugPrint('[CartPanel] _updateLines called with ${newCart.length} items');
    final listState = _listKey.currentState;
    final newIds = newCart.map((e) => e.variantId).toList();
    // debugPrint('[CartPanel] newIds: $newIds, current _variantIds: $_variantIds');

    if (listState == null) {
      _variantIds = newIds;
      // debugPrint('[CartPanel] listState is null, setting _variantIds to $newIds');
      return;
    }

    // removals
    for (var i = _variantIds.length - 1; i >= 0; i--) {
      final id = _variantIds[i];
      if (!newIds.contains(id)) {
        // debugPrint('[CartPanel] Removing item at index $i with variantId $id');
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
        // debugPrint('[CartPanel] Inserting item at index $i with variantId $id');
        _variantIds.insert(i, id);
        listState.insertItem(i, duration: const Duration(milliseconds: 200));
      }
    }
    // debugPrint('[CartPanel] _updateLines completed, _variantIds: $_variantIds');
    // updates require no action; individual line widgets reselect state.
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    // Responsive: collapse to compact header on narrow screens
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width <= kPosNarrowBreakpoint;

    Widget fullContent() => Column(
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
              AppPrimaryButton(
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
                      AppIconButton(
                        size: 36,
                        onPressed: () => widget.onCustomerChanged(null),
                        icon: const Icon(
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
          child: Builder(
            builder: (context) {
              // Use CartCubit when present to render cart; otherwise use PosCubit
              bool hasCartCubit = false;
              try {
                context.read<CartCubit>();
                hasCartCubit = true;
              } catch (_) {
                hasCartCubit = false;
              }
              Widget buildAnimatedList() {
                return AnimatedList(
                  key: _listKey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
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
                        child: hasCartCubit
                            ? CartCubitLineItem(
                                variantId: id,
                                onEdit: widget.onEdit,
                                prefetchRows: _variantRows,
                              )
                            : CartLineItem(
                                variantId: id,
                                onEdit: widget.onEdit,
                                prefetchRows: _variantRows,
                              ),
                      ),
                    );
                  },
                );
              }

              if (hasCartCubit) {
                return BlocConsumer<CartCubit, CartState>(
                  listener: (context, state) {
                    // Convert CartItem to CartLine for _updateLines compatibility
                    final cartLines = state.cart
                        .map(
                          (ci) => CartLine(
                            variantId: ci.variantId,
                            quantity: ci.quantity,
                            price: ci.price,
                            discountAmount: ci.discountAmount,
                            taxAmount: ci.taxAmount,
                          ),
                        )
                        .toList();
                    _updateLines(cartLines);
                  },
                  builder: (context, state) {
                    // debugPrint('[CartPanel] Building with CartCubit state: ${state.cart.length} items');
                    if (state.cart.isEmpty && _variantIds.isEmpty) {
                      return const EmptyState(
                        title: 'السلة فارغة',
                        message: 'أضف منتجات بالنقر على عنصر من القائمة.',
                        icon: CupertinoIcons.cart,
                      );
                    }
                    return buildAnimatedList();
                  },
                );
              }
              // Fallback to existing PosCubit-based rendering
              return BlocConsumer<PosCubit, PosState>(
                listener: (context, state) => _updateLines(state.cart),
                builder: (context, state) {
                  if (state.cart.isEmpty && _variantIds.isEmpty) {
                    return const EmptyState(
                      title: 'السلة فارغة',
                      message: 'أضف منتجات بالنقر على عنصر من القائمة.',
                      icon: CupertinoIcons.cart,
                    );
                  }
                  return buildAnimatedList();
                },
              );
            },
          ),
        ),
        Container(height: 1, color: c.border),
        if (widget.showSummaryFooter)
          Builder(
            builder: (ctx) {
              // Prefer CartCubit for totals/counts
              try {
                final cartState = ctx.watch<CartCubit>().state;
                final total = cartState.cart.fold<double>(
                  0,
                  (s, l) =>
                      s +
                      (l.price * l.quantity) -
                      l.discountAmount +
                      l.taxAmount,
                );
                final count = cartState.cart.fold<int>(
                  0,
                  (sum, l) => sum + l.quantity,
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
                              'عدد المنتجات: ${count.toString().padLeft(3, '0')}',
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
                      // Clear and Hold/Restore (dynamic) buttons
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              color: CupertinoColors.systemRed,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              onPressed: () async {
                                final sc = context; // capture
                                final l = AppLocalizations.of(sc);
                                final confirmed =
                                    await showCupertinoDialog<bool>(
                                      context: sc,
                                      builder: (dctx) => CupertinoAlertDialog(
                                        title: Text(l.confirm),
                                        content: Text(l.clearCartConfirmation),
                                        actions: [
                                          CupertinoDialogAction(
                                            onPressed: () =>
                                                Navigator.of(dctx).pop(false),
                                            child: Text(l.cancel),
                                          ),
                                          CupertinoDialogAction(
                                            isDestructiveAction: true,
                                            onPressed: () =>
                                                Navigator.of(dctx).pop(true),
                                            child: Text(l.clearCart),
                                          ),
                                        ],
                                      ),
                                    );
                                if (!sc.mounted) return;
                                if (confirmed == true) {
                                  try {
                                    sc.read<CartCubit>().clear();
                                  } catch (_) {
                                    // fallback to PosCubit: remove each line
                                    try {
                                      final pos = sc.read<PosCubit>();
                                      final lines = List<CartLine>.from(
                                        pos.state.cart,
                                      );
                                      for (final l in lines) {
                                        pos.removeLine(l.variantId);
                                      }
                                    } catch (_) {}
                                  }
                                  if (!sc.mounted) return;
                                  AppToast.show(
                                    sc,
                                    message: l.cartCleared,
                                    type: ToastType.success,
                                  );
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    CupertinoIcons.trash,
                                    size: 16,
                                    color: CupertinoColors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppLocalizations.of(context).clearCart,
                                    style: const TextStyle(
                                      color: CupertinoColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          if (_heldCount > 0)
                            Expanded(
                              child: Container(
                                height: 38,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: CupertinoColors.systemOrange,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Row(
                                  children: [
                                    // Hold segment (60%)
                                    Expanded(
                                      flex: 3,
                                      child: CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        color: CupertinoColors.systemOrange,
                                        onPressed: () async {
                                          await _handleHoldOrShowWaiting(
                                            context,
                                          );
                                        },
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              CupertinoIcons.clock,
                                              size: 16,
                                              color: CupertinoColors.white,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              AppLocalizations.of(
                                                context,
                                              ).holdCart,
                                              style: const TextStyle(
                                                color: CupertinoColors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Restore segment (40%) with icon
                                    Expanded(
                                      flex: 2,
                                      child: CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        color: CupertinoColors.systemOrange
                                            .withValues(alpha: 0.85),
                                        onPressed: () async {
                                          await _showWaitingSalesModal(context);
                                        },
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            const Center(
                                              child: Icon(
                                                CupertinoIcons
                                                    .arrow_turn_up_left,
                                                size: 18,
                                                color: CupertinoColors.white,
                                              ),
                                            ),
                                            // Small badge with held count
                                            Positioned(
                                              right: -2,
                                              top: -2,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 1,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      CupertinoColors.systemRed,
                                                  borderRadius:
                                                      BorderRadius.circular(9),
                                                  border: Border.all(
                                                    color:
                                                        CupertinoColors.white,
                                                    width: 1,
                                                  ),
                                                ),
                                                constraints:
                                                    const BoxConstraints(
                                                      minWidth: 16,
                                                      minHeight: 16,
                                                    ),
                                                child: Text(
                                                  _heldCount > 99
                                                      ? '99+'
                                                      : _heldCount.toString(),
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color:
                                                        CupertinoColors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    height: 1.0,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: CupertinoButton(
                                color: CupertinoColors.systemOrange,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                onPressed: () async {
                                  await _handleHoldOrShowWaiting(context);
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      CupertinoIcons.clock,
                                      size: 16,
                                      color: CupertinoColors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      AppLocalizations.of(context).holdCart,
                                      style: const TextStyle(
                                        color: CupertinoColors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppPrimaryButton(
                        onPressed: widget.canCheckout
                            ? widget.onCheckout
                            : null,
                        child: Text(l.checkout),
                      ),
                    ],
                  ),
                );
              } catch (_) {
                return BlocBuilder<PosCubit, PosState>(
                  builder: (context, state) {
                    final total = state.cart.fold<double>(
                      0,
                      (s, l) =>
                          s +
                          (l.price * l.quantity) -
                          l.discountAmount +
                          l.taxAmount,
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
                          AppPrimaryButton(
                            onPressed: widget.canCheckout
                                ? widget.onCheckout
                                : null,
                            child: Text(l.checkout),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
            },
          ),
      ],
    );

    Widget compactHeader() {
      // compact header shows title, items count and total, with toggle
      return Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        color: c.surface,
        child: Row(
          children: [
            Expanded(
              child: Text(
                l.basket,
                style: AppTypography.bodyStrong.copyWith(color: c.textPrimary),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // items count and total
            Builder(
              builder: (ctx) {
                try {
                  final cs = ctx.watch<CartCubit>().state;
                  final itemsCount = cs.cart.fold<int>(
                    0,
                    (s, l) => s + l.quantity,
                  );
                  final total = cs.cart.fold<double>(
                    0,
                    (s, l) =>
                        s +
                        (l.price * l.quantity) -
                        l.discountAmount +
                        l.taxAmount,
                  );
                  return Row(
                    children: [
                      Text(
                        itemsCount.toString().padLeft(3, '0'),
                        style: AppTypography.bodyStrong.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        money(context, total),
                        style: AppTypography.bodyStrong.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  );
                } catch (_) {
                  return BlocBuilder<PosCubit, PosState>(
                    builder: (ctx2, state) {
                      final itemsCount = state.cart.fold<int>(
                        0,
                        (s, l) => s + l.quantity,
                      );
                      final total = state.cart.fold<double>(
                        0,
                        (s, l) =>
                            s +
                            (l.price * l.quantity) -
                            l.discountAmount +
                            l.taxAmount,
                      );
                      return Row(
                        children: [
                          Text(
                            itemsCount.toString().padLeft(3, '0'),
                            style: AppTypography.bodyStrong.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            money(context, total),
                            style: AppTypography.bodyStrong.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
            const SizedBox(width: AppSpacing.xs),
            // Quick actions: Clear and Hold
            AppIconButton(
              size: 36,
              onPressed: () async {
                final c0 = context;
                final l = AppLocalizations.of(c0);
                final confirmed = await showCupertinoDialog<bool>(
                  context: c0,
                  builder: (dctx) => CupertinoAlertDialog(
                    title: Text(l.confirm),
                    content: const Text('Clear cart?'),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(dctx).pop(false),
                        child: Text(l.cancel),
                      ),
                      CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: () => Navigator.of(dctx).pop(true),
                        child: Text(l.ok),
                      ),
                    ],
                  ),
                );
                if (!c0.mounted) return;
                if (confirmed == true) {
                  try {
                    c0.read<CartCubit>().clear();
                  } catch (_) {
                    // fallback to PosCubit: remove each line
                    try {
                      final pos = c0.read<PosCubit>();
                      final lines = List<CartLine>.from(pos.state.cart);
                      for (final l in lines) {
                        pos.removeLine(l.variantId);
                      }
                    } catch (_) {}
                  }
                  if (!c0.mounted) return;
                  AppToast.show(
                    c0,
                    message: 'Cart cleared',
                    type: ToastType.info,
                  );
                }
              },
              icon: const Icon(CupertinoIcons.trash, size: 18),
            ),
            const SizedBox(width: AppSpacing.xxs),
            AppIconButton(
              size: 36,
              onPressed: () async {
                final c1 = context; // capture
                final l = AppLocalizations.of(c1);
                // Capture current cart and convert to held-sale item maps
                List<Map<String, Object?>> items = [];
                try {
                  final cart = c1.read<CartCubit>().state.cart;
                  items = cart
                      .map(
                        (ci) => {
                          'variant_id': ci.variantId,
                          'quantity': ci.quantity,
                          'price': ci.price,
                          'attributes': ci.attributes,
                          'price_override': ci.priceOverride,
                          'resolved_variant_id': ci.resolvedVariantId,
                        },
                      )
                      .toList();
                } catch (_) {
                  // Fallback to PosCubit's CartLine list; try to include attributes if present
                  final currentLines = c1.read<PosCubit>().state.cart;
                  items = currentLines
                      .map(
                        (l) => {
                          'variant_id': l.variantId,
                          'quantity': l.quantity,
                          'price': l.price,
                          // Some PosCart lines may include attributes; include if present
                          'attributes': (l as dynamic).attributes,
                          'price_override': (l as dynamic).priceOverride,
                        },
                      )
                      .toList();
                }
                if (items.isEmpty) {
                  if ((c1 as Element).mounted) {
                    AppToast.show(
                      c1,
                      message: l.cartEmpty,
                      type: ToastType.info,
                    );
                  }
                  return;
                }
                // Ask for optional hold name
                final nameCtrl = TextEditingController();
                final name = await showCupertinoDialog<String?>(
                  context: c1,
                  builder: (dctx) => CupertinoAlertDialog(
                    title: Text(l.heldSalesTitle),
                    content: Column(
                      children: [
                        const SizedBox(height: 8),
                        CupertinoTextField(
                          controller: nameCtrl,
                          placeholder: l.holdNamePlaceholder,
                        ),
                      ],
                    ),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(dctx).pop(null),
                        child: Text(l.cancel),
                      ),
                      CupertinoDialogAction(
                        isDefaultAction: true,
                        onPressed: () => Navigator.of(dctx).pop(
                          nameCtrl.text.trim().isEmpty
                              ? null
                              : nameCtrl.text.trim(),
                        ),
                        child: Text(l.ok),
                      ),
                    ],
                  ),
                );
                if (!c1.mounted) return;
                final slotName =
                    name ?? 'Held @ ${DateTime.now().toIso8601String()}';
                // Save held snapshot to DB (items already prepared)
                try {
                  await _heldRepo.saveHeldSale(slotName, items);
                } catch (_) {
                  // ignore persistence errors for now
                }
                // Ensure context is still mounted before using it after the await
                if (!c1.mounted) return;
                // Clear active cart
                try {
                  c1.read<CartCubit>().clear();
                } catch (_) {
                  try {
                    final pos = c1.read<PosCubit>();
                    final lines = List<CartLine>.from(pos.state.cart);
                    for (final l in lines) {
                      pos.removeLine(l.variantId);
                    }
                  } catch (_) {}
                }
                // Refresh held count so the footer button updates immediately
                await _refreshHeldCount();
                if (!c1.mounted) return;
                AppToast.show(c1, message: l.holdSaved, type: ToastType.info);
              },
              icon: const Icon(CupertinoIcons.archivebox, size: 18),
            ),
            const SizedBox(width: AppSpacing.xxs),
            // Button to open held-sales modal
            AppIconButton(
              size: 36,
              onPressed: () async {
                final c2 = context; // capture
                // Load persisted held-sales summaries
                try {
                  _heldSales = await _heldRepo.listHeldSales();
                } catch (_) {
                  _heldSales = [];
                }

                if (!c2.mounted) return;
                await _showWaitingSalesModal(c2);
              },
              icon: const Icon(CupertinoIcons.rectangle_stack, size: 18),
            ),
            const SizedBox(width: AppSpacing.xs),
            AppIconButton(
              size: 40,
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded
                    ? CupertinoIcons.chevron_down
                    : CupertinoIcons.chevron_up,
              ),
            ),
          ],
        ),
      );
    }

    // If narrow, show compact header with animated expand; otherwise show full
    if (isNarrow) {
      return Column(
        children: [
          compactHeader(),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: fullContent(),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      );
    }

    // Wide layout: always expanded
    return fullContent();
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
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CupertinoColors.separator, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemGrey4.withValues(alpha: 0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
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
                                      color: CupertinoColors.label,
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
                                        color: CupertinoColors.secondaryLabel,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
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
                                  else if ((item
                                          .variant
                                          .attributes
                                          ?.isNotEmpty ??
                                      false))
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
                                              color: CupertinoColors.label,
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
                                                color: CupertinoColors
                                                    .secondaryLabel,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
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
                                  color: CupertinoColors.label,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  QuantityControl(
                    value: line.quantity,
                    onDecrement: () {
                      try {
                        context.read<CartCubit>().updateQty(
                          line.variantId,
                          line.quantity - 1,
                        );
                        return;
                      } catch (_) {}
                      context.read<PosCubit>().changeQty(
                        line.variantId,
                        line.quantity - 1,
                      );
                    },
                    onIncrement: () {
                      try {
                        context.read<CartCubit>().updateQty(
                          line.variantId,
                          line.quantity + 1,
                        );
                        return;
                      } catch (_) {}
                      context.read<PosCubit>().changeQty(
                        line.variantId,
                        line.quantity + 1,
                      );
                    },
                  ),
                  Column(
                    children: [
                      AppIconButton(
                        onPressed: () => onEdit(line),
                        icon: const Icon(CupertinoIcons.pencil, size: 20),
                        size: 40,
                      ),
                      AppIconButton(
                        onPressed: () {
                          try {
                            context.read<CartCubit>().removeItem(
                              line.variantId,
                            );
                            return;
                          } catch (_) {
                            context.read<PosCubit>().removeLine(line.variantId);
                          }
                        },
                        icon: const Icon(
                          CupertinoIcons.delete_simple,
                          size: 20,
                        ),
                        size: 40,
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

/// Widget for displaying cart items from CartCubit state
class CartCubitLineItem extends StatelessWidget {
  final int variantId;
  final void Function(CartLine) onEdit;
  final Map<int, Map<String, Object?>> prefetchRows;

  const CartCubitLineItem({
    super.key,
    required this.variantId,
    required this.onEdit,
    this.prefetchRows = const {},
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CartCubit, CartState, CartItem?>(
      selector: (state) {
        try {
          return state.cart.firstWhere((item) => item.variantId == variantId);
        } catch (_) {
          return null;
        }
      },
      builder: (context, cartItem) {
        if (cartItem == null) return const SizedBox.shrink();

        final c = context.colors;
        final posCubit = context.read<PosCubit>();
        final nameFuture = posCubit.resolveVariantName(cartItem.variantId);
        final lineTotal = money(
          context,
          cartItem.price * cartItem.quantity -
              cartItem.discountAmount +
              cartItem.taxAmount,
        );

        // Convert CartItem to CartLine for onEdit compatibility
        final cartLine = CartLine(
          variantId: cartItem.variantId,
          quantity: cartItem.quantity,
          price: cartItem.price,
          discountAmount: cartItem.discountAmount,
          taxAmount: cartItem.taxAmount,
        );

        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String?>(
                      future: nameFuture,
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Text(
                            snapshot.data!,
                            style: AppTypography.bodyStrong.copyWith(
                              color: CupertinoColors.label,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        } else {
                          return Text(
                            'Product #${cartItem.variantId}',
                            style: AppTypography.bodyStrong.copyWith(
                              color: CupertinoColors.label,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
                        '${money(context, cartItem.price)} × ${cartItem.quantity} = $lineTotal',
                        key: ValueKey(
                          'q${cartItem.variantId}-${cartItem.quantity}-${cartItem.discountAmount}-${cartItem.taxAmount}',
                        ),
                        style: AppTypography.caption.copyWith(
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              QuantityControl(
                value: cartItem.quantity,
                onDecrement: () {
                  context.read<CartCubit>().updateQty(
                    cartItem.variantId,
                    cartItem.quantity - 1,
                  );
                },
                onIncrement: () {
                  context.read<CartCubit>().updateQty(
                    cartItem.variantId,
                    cartItem.quantity + 1,
                  );
                },
              ),
              Column(
                children: [
                  AppIconButton(
                    onPressed: () => onEdit(cartLine),
                    icon: const Icon(CupertinoIcons.pencil, size: 20),
                    size: 40,
                  ),
                  AppIconButton(
                    onPressed: () {
                      context.read<CartCubit>().removeItem(cartItem.variantId);
                    },
                    icon: const Icon(CupertinoIcons.delete_simple, size: 20),
                    size: 40,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

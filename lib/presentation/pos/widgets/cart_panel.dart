import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/pos/bloc/pos_cubit.dart';
import 'package:clothes_pos/presentation/common/money.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';
import 'package:clothes_pos/presentation/design/system/app_typography.dart';
import 'package:clothes_pos/presentation/pos/widgets/quantity_control.dart';
import 'package:clothes_pos/presentation/pos/widgets/empty_state.dart';

class CartPanel extends StatefulWidget {
  final void Function(CartLine) onEdit;
  final VoidCallback onCheckout;
  final bool canCheckout;

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
    this.showSummaryFooter = true,
  });
  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  final _listKey = GlobalKey<AnimatedListState>();
  List<int> _variantIds = [];
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final cart = context.read<PosCubit>().state.cart;
      _variantIds = cart.map((e) => e.variantId).toList();
      _initialized = true;
    }
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
          child: Text(
            l.basket,
            style: AppTypography.bodyStrong.copyWith(color: c.textPrimary),
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
                      child: CartLineItem(variantId: id, onEdit: widget.onEdit),
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
              final items = state.cart.fold<int>(0, (s, l) => s + l.quantity);
              return Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(color: c.surface),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${l.items}: $items',
                          style: AppTypography.caption.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                        Text(
                          money(context, total),
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
  const CartLineItem({
    super.key,
    required this.variantId,
    required this.onEdit,
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
                          builder: (ctx, snap) => Text(
                            snap.data ?? 'Item ${line.variantId}',
                            style: AppTypography.bodyStrong.copyWith(
                              color: c.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs / 2),
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

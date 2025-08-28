// Reconstructed POS screen file after corruption. Clean implementation below.
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/design/system/app_typography.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:printing/printing.dart';

import 'package:clothes_pos/presentation/pos/bloc/pos_cubit.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/presentation/settings/bloc/settings_cubit.dart';
import 'package:clothes_pos/presentation/pos/widgets/category_sidebar.dart';
import 'package:clothes_pos/presentation/pos/widgets/product_grid_item.dart';
import 'package:clothes_pos/presentation/pos/widgets/cart_panel.dart';
import 'package:clothes_pos/presentation/pos/widgets/rfid_toggle.dart';
import 'package:clothes_pos/presentation/pos/widgets/filter_chips_bar.dart';
import 'package:clothes_pos/presentation/pos/screens/advanced_product_search_screen.dart';
import 'package:clothes_pos/presentation/pos/widgets/payment_modal.dart';
import 'package:clothes_pos/presentation/pos/widgets/empty_state.dart';
// duplicate product_grid_item import avoided (already imported above)
import 'package:clothes_pos/presentation/common/money.dart';
import 'package:clothes_pos/presentation/common/view_only_banner.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/presentation/common/widgets/action_button.dart';
import 'package:clothes_pos/presentation/common/overlay/app_toast.dart';
import 'package:clothes_pos/core/printing/receipt_pdf_service.dart';
import 'package:clothes_pos/core/printing/system_pdf_printer.dart';
import 'package:clothes_pos/data/repositories/audit_repository.dart';
import 'package:clothes_pos/data/repositories/cash_repository.dart';
import 'package:clothes_pos/data/repositories/product_repository.dart';
import 'package:clothes_pos/data/models/payment.dart';
import 'package:clothes_pos/core/format/currency_formatter.dart';
import 'package:clothes_pos/core/auth/permissions.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';

import 'return_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});
  @override
  State<PosScreen> createState() => _PosScreenState();
}

// Simple dynamic-like object with expected fields used by ProductGridItem during loading.
class _ShimmerVariantStub {
  final double salePrice = 0;
  final int quantity = 0;
  final String name = '';
  final String parentName = '';
  final String sku = '';
  const _ShimmerVariantStub();
}

class _PosScreenState extends State<PosScreen> {
  // Responsive breakpoints
  static const double _narrowBreakpoint = 900; // <= narrow stacked layout

  // Filters & search
  final _searchCtrl = TextEditingController();
  List<String> _sizes = [];
  List<String> _colors = [];
  List<String> _brands = [];
  String? _selectedSize;
  String? _selectedColor;
  String? _selectedBrand;
  // Session
  final _cash = sl<CashRepository>();
  Map<String, dynamic>? _session;

  // Narrow layout cart expansion state
  bool _cartExpanded = false;

  void _toggleCartPanel() => setState(() => _cartExpanded = !_cartExpanded);

  void _applySearchWithFilters() {
    final posCubit = context.read<PosCubit>();
    final selectedCategoryId = posCubit.state.selectedCategoryId;
    final base = _searchCtrl.text.trim();
    final q = [
      base,
      if (_selectedSize?.isNotEmpty ?? false) 'size:${_selectedSize!}',
      if (_selectedColor?.isNotEmpty ?? false) 'color:${_selectedColor!}',
      if (_selectedBrand?.isNotEmpty ?? false) 'brand:${_selectedBrand!}',
    ].where((e) => e.trim().isNotEmpty).join(' ');
    posCubit.search(q, categoryId: selectedCategoryId);
  }

  Future<void> _showCategoriesSheet() async {
    final l = AppLocalizations.of(context);
    final posCubit = context.read<PosCubit>();
    final categories = posCubit.state.categories;
    if (categories.isEmpty) return;
    final selected = await showCupertinoModalPopup<int?>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l.categories),
        actions: [
          for (final c in categories)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop(c.id as int),
              isDefaultAction: posCubit.state.selectedCategoryId == c.id,
              child: Text(
                c.name,
                style: TextStyle(
                  fontWeight: posCubit.state.selectedCategoryId == c.id
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l.cancel),
        ),
      ),
    );
    if (!mounted) return;
    posCubit.selectCategory(
      selected == posCubit.state.selectedCategoryId ? null : selected,
    );
  }

  @override
  void initState() {
    super.initState();
    _refreshSession();
    context.read<PosCubit>().loadCategories();
    _loadFilters();
  }

  Future<void> _refreshSession() async {
    final s = await _cash.getOpenSession();
    if (mounted) setState(() => _session = s);
  }

  Future<void> _loadFilters() async {
    final repo = sl<ProductRepository>();
    final sizes = await repo.distinctSizes(limit: 100);
    final colors = await repo.distinctColors(limit: 100);
    final brands = await repo.distinctBrands(limit: 100);
    if (!mounted) return;
    setState(() {
      _sizes = sizes;
      _colors = colors;
      _brands = brands;
    });
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (dialogCtx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(AppLocalizations.of(dialogCtx).ok),
            onPressed: () => Navigator.of(dialogCtx).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _promptOpenSession() async {
    final l = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    final amount = await showCupertinoDialog<double>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l.openSessionTitle),
        content: Column(
          children: [
            const SizedBox(height: 8),
            CupertinoTextField(
              placeholder: l.openingFloat,
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(l.openAction),
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              if (v == null) return;
              Navigator.pop(ctx, v);
            },
          ),
        ],
      ),
    );
    if (amount == null || !mounted) return;
    final userId = context.read<AuthCubit>().state.user?.id ?? 1;
    await sl<CashRepository>().openSession(
      openedBy: userId,
      openingFloat: amount,
    );
    await _refreshSession();
  }

  // Legacy _showPaymentSheet removed (replaced by PaymentModal).

  // Stub variant object used for shimmer placeholders (mimics dynamic fields accessed).
  static final _shimmerVariant = _ShimmerVariantStub();

  Future<void> _showCartLineEditSheet(
    BuildContext context,
    CartLine line,
  ) async {
    final discountCtrl = TextEditingController(
      text: line.discountAmount == 0
          ? ''
          : line.discountAmount.toStringAsFixed(2),
    );
    final taxCtrl = TextEditingController(
      text: line.taxAmount == 0 ? '' : line.taxAmount.toStringAsFixed(2),
    );
    final noteCtrl = TextEditingController(text: line.note ?? '');
    double parse(String s) => double.tryParse(s.trim()) ?? 0;
    await showCupertinoModalPopup(
      context: context,
      builder: (sheetCtx) => CupertinoActionSheet(
        title: Text(AppLocalizations.of(sheetCtx).editLine),
        message: Column(
          children: [
            CupertinoTextField(
              controller: discountCtrl,
              placeholder: AppLocalizations.of(sheetCtx).discountAmount,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: taxCtrl,
              placeholder: AppLocalizations.of(sheetCtx).taxAmount,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: noteCtrl,
              placeholder: AppLocalizations.of(sheetCtx).noteLabel,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(sheetCtx).pop();
              final newDiscount = parse(discountCtrl.text);
              final newTax = parse(taxCtrl.text);
              final userId = context.read<AuthCubit>().state.user?.id;
              if (line.discountAmount != newDiscount) {
                sl<AuditRepository>().logChange(
                  userId: userId,
                  entity: 'cart_line:${line.variantId}',
                  field: 'discountAmount',
                  oldValue: line.discountAmount.toStringAsFixed(2),
                  newValue: newDiscount.toStringAsFixed(2),
                );
              }
              if (line.taxAmount != newTax) {
                sl<AuditRepository>().logChange(
                  userId: userId,
                  entity: 'cart_line:${line.variantId}',
                  field: 'taxAmount',
                  oldValue: line.taxAmount.toStringAsFixed(2),
                  newValue: newTax.toStringAsFixed(2),
                );
              }
              context.read<PosCubit>().updateLineDetails(
                line.variantId,
                discountAmount: newDiscount,
                taxAmount: newTax,
                note: noteCtrl.text.trim().isEmpty
                    ? null
                    : noteCtrl.text.trim(),
              );
            },
            child: Text(AppLocalizations.of(sheetCtx).save),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetCtx).pop(),
          child: Text(AppLocalizations.of(sheetCtx).cancel),
        ),
      ),
    );
  }

  // _amountField removed with legacy payment sheet.

  Future<void> _handleCheckout(BuildContext context) async {
    try {
      final ctx = context; // capture for async safety
      final posCubit = ctx.read<PosCubit>();
      final authCubit = ctx.read<AuthCubit>();
      final l = AppLocalizations.of(ctx);
      if (posCubit.state.cart.isEmpty) throw Exception('cart_empty');
      if (_session == null) throw Exception(l.sessionNone);
      final total = posCubit.state.cart.fold<double>(
        0,
        (s, l) => s + l.price * l.quantity,
      );
      // Collect payments via new full-screen PaymentModal
      final comp = Completer<List<Payment>?>();
      await PaymentModal.open(
        ctx,
        total: total,
        onConfirm: (cash, card, mobile) {
          var need = total;
          final list = <Payment>[];
          void take(double amt, PaymentMethod m) {
            final eff = amt.clamp(0, need);
            if (eff > 0) {
              list.add(
                Payment(
                  amount: eff.toDouble(),
                  method: m,
                  cashSessionId: m == PaymentMethod.cash
                      ? _session!['id'] as int
                      : null,
                  createdAt: DateTime.now(),
                ),
              );
              need -= eff;
            }
          }

          take(card, PaymentMethod.card);
          take(mobile, PaymentMethod.mobile);
          take(cash, PaymentMethod.cash);
          if (!comp.isCompleted) comp.complete(list);
        },
      );
      if (!comp.isCompleted) return; // user dismissed
      final payments = await comp.future;
      if (payments == null || payments.isEmpty) return;
      final saleId = await posCubit.checkoutWithPayments(payments: payments);
      if (!mounted) return;
      AppToast.show(ctx, message: l.saleSuccessTitle, type: ToastType.success);
      await showCupertinoDialog(
        context: ctx,
        builder: (dialogCtx) => CupertinoAlertDialog(
          title: Text(l.saleSuccessTitle),
          content: Text(l.saleNumber(saleId)),
          actions: [
            CupertinoDialogAction(
              child: Text(l.printReceipt),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final service = ReceiptPdfService();
                final cashierName = authCubit.state.user?.fullName;
                final file = await service.generate(
                  saleId,
                  locale: 'ar',
                  cashierName: cashierName,
                  phoneLabel: l.phoneLabel,
                  saleReceiptLabel: l.saleReceiptLabel,
                  userLabel: l.userLabel,
                  totalLabel: l.totalLabel.replaceAll(':', ''),
                  paymentMethodsLabel: l.paymentMethodsLabel,
                  thanksLabel: l.thanksLabel,
                  cashLabel: l.cash,
                  cardLabel: l.card,
                  mobileLabel: l.mobile,
                  refundLabel: l.returnLabel,
                );
                final bytes = await file.readAsBytes();
                if (!ctx.mounted) return;
                await SystemPdfPrinter().printPdfBytes(bytes);
              },
            ),
            CupertinoDialogAction(
              child: Text(l.savePdf),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final service = ReceiptPdfService();
                final cashierName = authCubit.state.user?.fullName;
                final file = await service.generate(
                  saleId,
                  locale: 'ar',
                  cashierName: cashierName,
                  phoneLabel: l.phoneLabel,
                  saleReceiptLabel: l.saleReceiptLabel,
                  userLabel: l.userLabel,
                  totalLabel: l.totalLabel.replaceAll(':', ''),
                  paymentMethodsLabel: l.paymentMethodsLabel,
                  thanksLabel: l.thanksLabel,
                  cashLabel: l.cash,
                  cardLabel: l.card,
                  mobileLabel: l.mobile,
                  refundLabel: l.returnLabel,
                );
                await Printing.sharePdf(
                  bytes: await file.readAsBytes(),
                  filename: 'receipt_$saleId.pdf',
                );
              },
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      final l = AppLocalizations.of(context); // use fresh context for error
      if (e is Exception && e.toString().contains('cart_empty')) {
        _showErrorDialog(context, l.error, l.cartEmpty);
        return;
      }
      _showErrorDialog(context, l.error, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final lBuild = AppLocalizations.of(context);
    final auth = context.watch<AuthCubit>().state;
    final hasSales =
        auth.user?.permissions.contains(AppPermissions.performSales) ?? false;
    final colors = context.colors;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        heroTag: 'pos-bar',
        middle: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(lBuild.posTitle),
            // Tiny gap between title and session label
            const SizedBox(height: AppSpacing.xxs / 2),
            Text(
              _session == null
                  ? lBuild.sessionNone
                  : '${lBuild.sessionOpen}${_session?['id'] ?? ''}',
              style: TextStyle(
                fontSize: AppTypography.fs11,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_session == null)
              ActionButton(
                onPressed: _promptOpenSession,
                label: lBuild.openAction,
              )
            else
              ActionButton(
                label: lBuild.closeAction,
                leading: const Icon(CupertinoIcons.stop_circle),
                onPressed: () async {
                  final l = AppLocalizations.of(context);
                  final ctrl = TextEditingController();
                  final amount = await showCupertinoDialog<double>(
                    context: context,
                    builder: (ctx) => CupertinoAlertDialog(
                      title: Text(l.logoutConfirmCloseSessionTitle),
                      content: Column(
                        children: [
                          const SizedBox(height: AppSpacing.xs),
                          CupertinoTextField(
                            placeholder: l.actualDrawerAmount,
                            controller: ctrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(l.cancel),
                        ),
                        CupertinoDialogAction(
                          isDefaultAction: true,
                          child: Text(l.closeAction),
                          onPressed: () {
                            final v = double.tryParse(ctrl.text.trim());
                            if (v == null) return;
                            Navigator.pop(ctx, v);
                          },
                        ),
                      ],
                    ),
                  );
                  if (amount == null || _session == null || !context.mounted) {
                    return;
                  }
                  final userId = context.read<AuthCubit>().state.user?.id ?? 1;
                  await sl<CashRepository>().closeSession(
                    sessionId: _session!['id'] as int,
                    closedBy: userId,
                    closingAmount: amount,
                  );
                  await _refreshSession();
                },
              ),
            const SizedBox(width: AppSpacing.xs),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(
                context,
              ).push(CupertinoPageRoute(builder: (_) => const ReturnScreen())),
              child: Text(lBuild.returnLabel),
            ),
            BlocBuilder<PosCubit, PosState>(
              builder: (context, state) {
                final settings = context.watch<SettingsCubit>().state;
                final total = state.cart.fold(
                  0.0,
                  (s, l) => s + l.price * l.quantity,
                );
                return Text(
                  '${lBuild.posTotal}: ${CurrencyFormatter.format(total, currency: settings.currency, locale: 'ar')}',
                );
              },
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wideLayout = constraints.maxWidth > _narrowBreakpoint;
            if (!wideLayout) {
              // Narrow stacked layout: search + results + bottom cart panel
              return Column(
                children: [
                  // Top controls row (search + barcode + RFID + categories button)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoSearchTextField(
                            controller: _searchCtrl,
                            onChanged: (v) =>
                                context.read<PosCubit>().debouncedSearch(
                                  v,
                                  categoryId: context
                                      .read<PosCubit>()
                                      .state
                                      .selectedCategoryId,
                                ),
                            placeholder: AppLocalizations.of(
                              context,
                            ).searchPlaceholder,
                            // Place advanced filter icon at the far left.
                            prefixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      AdvancedProductSearchScreen.open(context),
                                  child: const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(
                                      CupertinoIcons.slider_horizontal_3,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(CupertinoIcons.search, size: 18),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          onPressed: _showCategoriesSheet,
                          child: const Icon(CupertinoIcons.square_grid_2x2),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const RfidToggle(),
                        const SizedBox(width: AppSpacing.xs),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          onPressed: () async {
                            final ctx = context;
                            final cubit = ctx.read<PosCubit>();
                            try {
                              final cancelText = AppLocalizations.of(
                                ctx,
                              ).cancel;
                              final code =
                                  await FlutterBarcodeScanner.scanBarcode(
                                    '#ff6666',
                                    cancelText,
                                    true,
                                    ScanMode.BARCODE,
                                  );
                              if (!ctx.mounted || code == '-1') return;
                              final ok = await cubit.addByBarcode(code);
                              if (!ctx.mounted || ok) return;
                              final l = AppLocalizations.of(ctx);
                              AppToast.show(
                                ctx,
                                message: l.noProductForBarcode,
                                type: ToastType.error,
                              );
                            } catch (e) {
                              if (!ctx.mounted) return;
                              final l = AppLocalizations.of(ctx);
                              AppToast.show(
                                ctx,
                                message: l.posScanError,
                                type: ToastType.error,
                              );
                            }
                          },
                          child: const Icon(CupertinoIcons.barcode),
                        ),
                      ],
                    ),
                  ),
                  // Horizontal filter chips bar
                  if (_sizes.isNotEmpty ||
                      _colors.isNotEmpty ||
                      _brands.isNotEmpty)
                    FilterChipsBar(
                      sizes: _sizes,
                      colors: _colors,
                      brands: _brands,
                      selectedSize: _selectedSize,
                      selectedColor: _selectedColor,
                      selectedBrand: _selectedBrand,
                      onSizeChanged: (v) {
                        setState(() => _selectedSize = v);
                        _applySearchWithFilters();
                      },
                      onColorChanged: (v) {
                        setState(() => _selectedColor = v);
                        _applySearchWithFilters();
                      },
                      onBrandChanged: (v) {
                        setState(() => _selectedBrand = v);
                        _applySearchWithFilters();
                      },
                    ),
                  // Results
                  Expanded(
                    child: BlocBuilder<PosCubit, PosState>(
                      builder: (context, state) {
                        if (state.searching) {
                          // Shimmer skeleton for grid/list (8 items)
                          return GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: AppSpacing.xs,
                                  mainAxisSpacing: AppSpacing.xs,
                                  childAspectRatio: 2.6,
                                ),
                            itemCount: 8,
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            itemBuilder: (c, i) => ProductGridItem(
                              variant: _shimmerVariant,
                              loading: true,
                              square: true,
                            ),
                          );
                        }
                        final items = state.searchResults;
                        final quick = state.quickItems;
                        if (items.isEmpty && quick.isEmpty) {
                          return EmptyState(
                            title: AppLocalizations.of(context).notFound,
                            icon: CupertinoIcons.search,
                          );
                        }
                        String query = context.read<PosCubit>().state.query;
                        TextSpan highlight(String source) {
                          final q = query.trim();
                          if (q.isEmpty) return TextSpan(text: source);
                          final lower = source.toLowerCase();
                          final idx = lower.indexOf(q.toLowerCase());
                          if (idx < 0) return TextSpan(text: source);
                          return TextSpan(
                            children: [
                              if (idx > 0)
                                TextSpan(text: source.substring(0, idx)),
                              TextSpan(
                                text: source.substring(idx, idx + q.length),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (idx + q.length < source.length)
                                TextSpan(
                                  text: source.substring(idx + q.length),
                                ),
                            ],
                          );
                        }

                        return LayoutBuilder(
                          builder: (ctx, cons) {
                            final isGrid = cons.maxWidth >= 500;
                            Widget listWidget() {
                              return ListView(
                                children: [
                                  if (quick.isNotEmpty)
                                    SizedBox(
                                      height: 110,
                                      child: ListView.separated(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.xs,
                                          vertical: AppSpacing.xxs,
                                        ),
                                        scrollDirection: Axis.horizontal,
                                        itemCount: quick.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(
                                              width: AppSpacing.xxs + 2,
                                            ),
                                        itemBuilder: (c, i) {
                                          final v = quick[i];
                                          return ProductGridItem(
                                            variant: v,
                                            onTap: () => context
                                                .read<PosCubit>()
                                                .addToCart(
                                                  v.id as int,
                                                  v.salePrice as double,
                                                ),
                                            width: 140,
                                            square: true,
                                          );
                                        },
                                      ),
                                    ),
                                  for (final v in items)
                                    CupertinoListTile(
                                      title: RichText(
                                        text: highlight(
                                          v.parentName ??
                                              v.name ??
                                              (v.sku ?? ''),
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${AppLocalizations.of(context).priceLabel} ${money(context, (v.salePrice as double))} — ${AppLocalizations.of(context).quantityLabel} ${v.quantity}',
                                      ),
                                      onTap: () =>
                                          context.read<PosCubit>().addToCart(
                                            v.id as int,
                                            v.salePrice as double,
                                          ),
                                    ),
                                ],
                              );
                            }

                            if (!isGrid) return listWidget();
                            final crossAxisCount = (cons.maxWidth / 180)
                                .floor()
                                .clamp(2, 4);
                            return GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: AppSpacing.xs,
                                    mainAxisSpacing: AppSpacing.xs,
                                    childAspectRatio: 2.6,
                                  ),
                              itemCount: items.length,
                              itemBuilder: (context, i) {
                                final v = items[i];
                                return ProductGridItem(
                                  variant: v,
                                  onTap: () =>
                                      context.read<PosCubit>().addToCart(
                                        v.id as int,
                                        v.salePrice as double,
                                      ),
                                  square: true,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Collapsible cart panel
                  BlocBuilder<PosCubit, PosState>(
                    builder: (context, state) {
                      final total = state.cart.fold<double>(
                        0,
                        (s, l) =>
                            s +
                            (l.price * l.quantity) -
                            l.discountAmount +
                            l.taxAmount,
                      );
                      final items = state.cart.fold<int>(
                        0,
                        (s, l) => s + l.quantity,
                      );
                      final screenH = MediaQuery.of(context).size.height;
                      final expandedH = (screenH * 0.45).clamp(260.0, 420.0);
                      final panelHeight = _cartExpanded ? expandedH : 56.0;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        width: double.infinity,
                        height: panelHeight,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          border: Border(top: BorderSide(color: colors.border)),
                          boxShadow: _cartExpanded
                              ? [
                                  BoxShadow(
                                    color: colors.overlayStrong.withValues(
                                      alpha: 0.08,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, -2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            // Summary / toggle bar
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _toggleCartPanel,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xxs,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _cartExpanded
                                          ? CupertinoIcons.chevron_down
                                          : CupertinoIcons.chevron_up,
                                      size: 18,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        '${AppLocalizations.of(context).basket} • $items',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      money(context, total),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    CupertinoButton.filled(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                      ),
                                      onPressed:
                                          hasSales && state.cart.isNotEmpty
                                          ? () => _handleCheckout(context)
                                          : null,
                                      child: Text(
                                        AppLocalizations.of(context).checkout,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_cartExpanded)
                              Container(height: 1, color: colors.border),
                            if (_cartExpanded)
                              Expanded(
                                child: CartPanel(
                                  canCheckout: hasSales,
                                  onCheckout: () => _handleCheckout(context),
                                  onEdit: (line) =>
                                      _showCartLineEditSheet(context, line),
                                  // Hide footer summary here because the
                                  // collapsible panel header already shows
                                  // items/total/checkout, avoiding duplication.
                                  showSummaryFooter: false,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            }
            // Wide layout (three column style)
            return Row(
              children: [
                if (wideLayout) const CategorySidebar(),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      FilterChipsBar(
                        sizes: _sizes,
                        colors: _colors,
                        brands: _brands,
                        selectedSize: _selectedSize,
                        selectedColor: _selectedColor,
                        selectedBrand: _selectedBrand,
                        onSizeChanged: (v) {
                          setState(() => _selectedSize = v);
                          _applySearchWithFilters();
                        },
                        onColorChanged: (v) {
                          setState(() => _selectedColor = v);
                          _applySearchWithFilters();
                        },
                        onBrandChanged: (v) {
                          setState(() => _selectedBrand = v);
                          _applySearchWithFilters();
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: Row(
                          children: [
                            Expanded(
                              child: CupertinoSearchTextField(
                                controller: _searchCtrl,
                                onChanged: (v) =>
                                    context.read<PosCubit>().debouncedSearch(
                                      v,
                                      categoryId: context
                                          .read<PosCubit>()
                                          .state
                                          .selectedCategoryId,
                                    ),
                                placeholder: AppLocalizations.of(
                                  context,
                                ).searchPlaceholder,
                                prefixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () =>
                                          AdvancedProductSearchScreen.open(
                                            context,
                                          ),
                                      child: const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: Icon(
                                          CupertinoIcons.slider_horizontal_3,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(CupertinoIcons.search, size: 18),
                                    const SizedBox(width: 4),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            const RfidToggle(),
                            const SizedBox(width: AppSpacing.xs),
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                              ),
                              onPressed: () async {
                                final ctx = context;
                                final cubit = ctx.read<PosCubit>();
                                try {
                                  final cancelText = AppLocalizations.of(
                                    ctx,
                                  ).cancel;
                                  final code =
                                      await FlutterBarcodeScanner.scanBarcode(
                                        '#ff6666',
                                        cancelText,
                                        true,
                                        ScanMode.BARCODE,
                                      );
                                  if (!ctx.mounted || code == '-1') return;
                                  final ok = await cubit.addByBarcode(code);
                                  if (!ctx.mounted || ok) return;
                                  final l = AppLocalizations.of(ctx);
                                  AppToast.show(
                                    ctx,
                                    message: l.noProductForBarcode,
                                    type: ToastType.error,
                                  );
                                } catch (e) {
                                  if (!ctx.mounted) return;
                                  final l = AppLocalizations.of(ctx);
                                  AppToast.show(
                                    ctx,
                                    message: l.posScanError,
                                    type: ToastType.error,
                                  );
                                }
                              },
                              child: const Icon(CupertinoIcons.barcode),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: BlocBuilder<PosCubit, PosState>(
                          builder: (context, state) {
                            if (state.searching) {
                              return GridView.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: AppSpacing.xs,
                                      mainAxisSpacing: AppSpacing.xs,
                                      childAspectRatio: 2.8,
                                    ),
                                itemCount: 9,
                                padding: const EdgeInsets.all(AppSpacing.xs),
                                itemBuilder: (c, i) => ProductGridItem(
                                  variant: _shimmerVariant,
                                  loading: true,
                                  square: true,
                                ),
                              );
                            }
                            if (state.searchResults.isEmpty &&
                                state.quickItems.isEmpty) {
                              return EmptyState(
                                title: AppLocalizations.of(context).notFound,
                                icon: CupertinoIcons.search,
                              );
                            }
                            Widget resultsList(List<dynamic> items) {
                              String query = state.query.trim();
                              TextSpan highlight(String source) {
                                if (query.isEmpty) {
                                  return TextSpan(text: source);
                                }
                                final lower = source.toLowerCase();
                                final ql = query.toLowerCase();
                                final idx = lower.indexOf(ql);
                                if (idx < 0) return TextSpan(text: source);
                                return TextSpan(
                                  children: [
                                    if (idx > 0)
                                      TextSpan(text: source.substring(0, idx)),
                                    TextSpan(
                                      text: source.substring(
                                        idx,
                                        idx + ql.length,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (idx + ql.length < source.length)
                                      TextSpan(
                                        text: source.substring(idx + ql.length),
                                      ),
                                  ],
                                );
                              }

                              return LayoutBuilder(
                                builder: (ctx, cons) {
                                  final isWide = cons.maxWidth >= 700;
                                  if (!isWide) {
                                    return ListView.builder(
                                      itemCount: items.length,
                                      itemBuilder: (context, i) {
                                        final v = items[i];
                                        final name =
                                            v.parentName ??
                                            v.name ??
                                            (v.sku ?? '');
                                        final size = (v.size ?? '').toString();
                                        final color = (v.color ?? '')
                                            .toString();
                                        final brand = (v.brand_name ?? '')
                                            .toString();
                                        final options = [
                                          if (brand.isNotEmpty) '[$brand] ',
                                          if (size.isNotEmpty) ' $size',
                                          if (color.isNotEmpty) ' $color',
                                        ].join().trim();
                                        return CupertinoListTile(
                                          title: RichText(
                                            text: highlight(name),
                                          ),
                                          subtitle: Text(
                                            '${AppLocalizations.of(context).priceLabel} ${money(context, (v.salePrice as double))} — ${AppLocalizations.of(context).quantityLabel} ${v.quantity}${options.isNotEmpty ? '\n$options' : ''}',
                                          ),
                                          onTap: () => context
                                              .read<PosCubit>()
                                              .addToCart(
                                                v.id as int,
                                                v.salePrice as double,
                                              ),
                                        );
                                      },
                                    );
                                  }
                                  final crossAxisCount = (cons.maxWidth / 220)
                                      .floor()
                                      .clamp(2, 6);
                                  return GridView.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          crossAxisSpacing: AppSpacing.xs,
                                          mainAxisSpacing: AppSpacing.xs,
                                          childAspectRatio: 2.8,
                                        ),
                                    itemCount: items.length,
                                    itemBuilder: (context, i) {
                                      final v = items[i];
                                      return ProductGridItem(
                                        variant: v,
                                        onTap: () =>
                                            context.read<PosCubit>().addToCart(
                                              v.id as int,
                                              v.salePrice as double,
                                            ),
                                        square: true,
                                      );
                                    },
                                  );
                                },
                              );
                            }

                            if (state.quickItems.isNotEmpty) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs,
                                      vertical: AppSpacing.xxs,
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context).quickItems,
                                      style: CupertinoTheme.of(context)
                                          .textTheme
                                          .textStyle
                                          .copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        120, // quick items row height (not a token size)
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: state.quickItems.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(
                                            width:
                                                AppSpacing.xxs +
                                                2, // 6px legacy gap
                                          ),
                                      itemBuilder: (ctx, i) {
                                        final v = state.quickItems[i];
                                        return ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            minWidth: 120,
                                          ),
                                          child: ProductGridItem(
                                            variant: v,
                                            onTap: () => context
                                                .read<PosCubit>()
                                                .addToCart(
                                                  v.id as int,
                                                  v.salePrice as double,
                                                ),
                                            square: true,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Container(height: 1, color: colors.border),
                                  Expanded(
                                    child: resultsList(state.searchResults),
                                  ),
                                ],
                              );
                            }
                            return resultsList(state.searchResults);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, color: colors.border),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      if (!hasSales)
                        const ViewOnlyBanner(
                          message: 'عرض فقط: لا تملك صلاحية تنفيذ البيع',
                          margin: EdgeInsets.only(bottom: 4),
                        ),
                      Expanded(
                        child: CartPanel(
                          canCheckout: hasSales,
                          onCheckout: () => _handleCheckout(context),
                          onEdit: (line) =>
                              _showCartLineEditSheet(context, line),
                        ),
                      ),
                      // Removed duplicate footer summary (items/total/checkout)
                      // because CartPanel already renders it in wide layout.
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

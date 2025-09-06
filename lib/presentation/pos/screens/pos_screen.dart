// Reconstructed POS screen file after corruption. Clean implementation below.
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/design/system/app_typography.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:printing/printing.dart';
import 'package:clothes_pos/presentation/common/widgets/floating_modal.dart';

import 'package:clothes_pos/presentation/pos/bloc/pos_cubit.dart';
import 'package:clothes_pos/presentation/pos/bloc/cart_cubit.dart';
import 'package:clothes_pos/presentation/pos/utils/cart_helpers.dart';
import 'package:clothes_pos/presentation/inventory/bloc/inventory_cubit.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/presentation/pos/widgets/category_sidebar.dart';
import 'package:clothes_pos/presentation/pos/widgets/product_grid_item.dart';
import 'package:clothes_pos/presentation/pos/widgets/cart_panel.dart';
import 'package:clothes_pos/presentation/pos/widgets/rfid_toggle.dart';
import 'package:clothes_pos/presentation/common/widgets/variant_attributes_display.dart';

import 'package:clothes_pos/presentation/pos/screens/advanced_product_search_screen.dart';
import 'package:clothes_pos/presentation/pos/widgets/payment_modal.dart';
import 'package:clothes_pos/presentation/pos/widgets/empty_state.dart';
// duplicate product_grid_item import avoided (already imported above)
import 'package:clothes_pos/presentation/common/money.dart';
import 'package:clothes_pos/presentation/common/view_only_banner.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/presentation/common/widgets/action_button.dart';
import 'package:clothes_pos/presentation/common/widgets/app_buttons.dart';
import 'package:clothes_pos/presentation/common/overlay/app_toast.dart';
import 'package:clothes_pos/core/printing/receipt_pdf_service.dart';
import 'package:clothes_pos/core/printing/system_pdf_printer.dart';
import 'package:clothes_pos/data/repositories/audit_repository.dart';
import 'package:clothes_pos/data/models/customer.dart';
import 'package:clothes_pos/data/repositories/cash_repository.dart';

import 'package:clothes_pos/data/repositories/settings_repository.dart';
import 'package:clothes_pos/presentation/settings/bloc/settings_cubit.dart';
import 'package:clothes_pos/core/printing/thermal_print_service.dart';
import 'package:clothes_pos/core/printing/escpos_generator.dart';
import 'package:clothes_pos/data/models/payment.dart';
import 'package:clothes_pos/data/models/sale_item.dart';
import 'package:clothes_pos/core/auth/permissions.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';
import 'package:clothes_pos/data/datasources/sales_dao.dart';
import 'package:clothes_pos/data/datasources/product_dao.dart';

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
  // Use theme-level constant for the POS narrow breakpoint.
  // Kept as a static alias for backward compatibility in tests if needed.
  static const double _narrowBreakpoint = kPosNarrowBreakpoint;

  // Filters & search
  final _searchCtrl = TextEditingController();

  // Session
  final _cash = sl<CashRepository>();
  Map<String, dynamic>? _session;
  Customer? _selectedCustomer;

  // Narrow layout cart expansion state

  // Cart panel key for refreshing cash
  final GlobalKey _cartPanelKey = GlobalKey();

  void _onCustomerChanged(Customer? customer) {
    setState(() {
      _selectedCustomer = customer;
    });
  }

  void _refreshCartCash() {
    final cartState = _cartPanelKey.currentState;
    if (cartState != null) {
      try {
        (cartState as dynamic).refreshCash();
      } catch (e) {
        // Handle error silently
      }
    }
  }

  Future<void> _handleCloseSession() async {
    if (_session == null) return;

    // Get session summary first to show expected amount
    final sessionId = _session!['id'] as int;
    final summary = await sl<CashRepository>().getSessionSummary(sessionId);
    final expectedCash = (summary['expected_cash'] as num?)?.toDouble() ?? 0.0;

    if (!context.mounted) return;
    final ctx = context;
    final l = AppLocalizations.of(ctx);

    final ctrl = TextEditingController();
    final amount = await showCupertinoDialog<double>(
      context: ctx,
      builder: (dialogCtx) => CupertinoAlertDialog(
        title: const Text('إغلاق الجلسة'),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogCtx).size.height * 0.6,
            ),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'المبلغ المتوقع: ${money(ctx, expectedCash)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.systemBlue,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                CupertinoTextField(
                  placeholder: l.actualDrawerAmount,
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('إغلاق الجلسة'),
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              if (v == null) return;
              Navigator.pop(dialogCtx, v);
            },
          ),
        ],
      ),
    );

    if (amount == null) return;
    if (!context.mounted) return;
    final ctx2 = context;
    final userId = ctx2.read<AuthCubit>().state.user?.id ?? 1;
    final variance = await sl<CashRepository>().closeSession(
      sessionId: sessionId,
      closedBy: userId,
      closingAmount: amount,
    );

    if (!context.mounted) return;

    // Show variance result
    await _showVarianceResult(expectedCash, amount, variance, userId);
    await _refreshSession();
  }

  Future<void> _showVarianceResult(
    double expected,
    double actual,
    double variance,
    int userId,
  ) async {
    if (!context.mounted) return;
    final ctx = context;
    final l = AppLocalizations.of(ctx);

    // Determine variance status
    String varianceText;
    Color varianceColor;
    IconData varianceIcon;

    if (variance == 0) {
      varianceText = 'مطابق تماماً ✓';
      varianceColor = CupertinoColors.systemGreen;
      varianceIcon = CupertinoIcons.check_mark_circled;
    } else if (variance > 0) {
      varianceText = 'زيادة: ${money(ctx, variance)}';
      varianceColor = CupertinoColors.systemBlue;
      varianceIcon = CupertinoIcons.plus_circled;
    } else {
      varianceText = 'نقص: ${money(ctx, variance.abs())}';
      varianceColor = CupertinoColors.systemRed;
      varianceIcon = CupertinoIcons.minus_circled;
    }

    if (!ctx.mounted) return; // safety
    await showCupertinoDialog(
      context: ctx,
      builder: (_) => CupertinoAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(varianceIcon, color: varianceColor, size: 24),
            const SizedBox(width: 8),
            const Text('نتيجة إغلاق الجلسة'),
          ],
        ),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.6,
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildVarianceRow(
                  'المبلغ المتوقع:',
                  money(ctx, expected),
                  CupertinoColors.label,
                ),
                const SizedBox(height: 8),
                _buildVarianceRow(
                  'المبلغ الفعلي:',
                  money(ctx, actual),
                  CupertinoColors.label,
                ),
                const SizedBox(height: 8),
                Container(height: 1, color: CupertinoColors.separator),
                const SizedBox(height: 8),
                _buildVarianceRow('الفرق:', varianceText, varianceColor),
              ],
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(l.ok),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );

    // Log variance for manager if significant
    if (variance.abs() > 1.0) {
      // Only log if variance > 1 currency unit
      await _logVarianceForManager(userId, expected, actual, variance);
    }
  }

  Widget _buildVarianceRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Future<void> _logVarianceForManager(
    int userId,
    double expected,
    double actual,
    double variance,
  ) async {
    // Save a manager note for this user/session variance
    final note =
        'فرق الكاش عند الإغلاق: المتوقع = ${expected.toStringAsFixed(2)}, الفعلي = ${actual.toStringAsFixed(2)}, الفرق = ${variance.toStringAsFixed(2)}';
    try {
      await sl<AuditRepository>().logChange(
        userId: userId,
        entity: 'user:$userId',
        field: 'variance_note',
        newValue: note,
      );
    } catch (e) {
      AppLogger.w('Failed to log manager variance note', error: e);
    }
    AppLogger.i('Cash variance detected: $note');
  }

  Future<void> _showCategoriesSheet() async {
    final l = AppLocalizations.of(context);
    final ctx = context;
    final posCubit = ctx.read<PosCubit>();
    final categories = posCubit.state.categories;
    if (categories.isEmpty) return;
    final selected = await showCupertinoModalPopup<int?>(
      context: ctx,
      builder: (ctx2) => CupertinoActionSheet(
        title: Text(l.categories),
        actions: [
          for (final c in categories)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx2).pop(c.id as int),
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
          onPressed: () => Navigator.of(ctx2).pop(),
          child: Text(l.cancel),
        ),
      ),
    );
    if (!context.mounted) return;
    posCubit.selectCategory(
      selected == posCubit.state.selectedCategoryId ? null : selected,
    );
  }

  @override
  void initState() {
    super.initState();
    _refreshSession();
    context.read<PosCubit>().loadCategories();
  }

  Future<void> _refreshSession() async {
    final s = await _cash.getOpenSession();
    if (mounted) setState(() => _session = s);
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    if (!context.mounted) return; // safety
    showCupertinoDialog(
      context: context,
      builder: (dialogCtx) => CupertinoAlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogCtx).size.height * 0.6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFD32F2F),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                if (message.contains('منتج'))
                  const Text(
                    'يرجى اختيار منتج قبل إتمام عملية البيع.',
                    style: TextStyle(fontSize: 14),
                  ),
                if (message.contains('كمية'))
                  const Text(
                    'الكمية المدخلة غير صحيحة. يرجى إدخال كمية موجبة فقط.',
                    style: TextStyle(fontSize: 14),
                  ),
                if (message.contains('دفع'))
                  const Text(
                    'يرجى التأكد من إدخال مبلغ الدفع بشكل صحيح.',
                    style: TextStyle(fontSize: 14),
                  ),
              ],
            ),
          ),
        ),
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
        content: SizedBox(
          width: 380,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                CupertinoTextField(
                  placeholder: l.openingFloat,
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(fontSize: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
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
    await FloatingModal.showWithSize<void>(
      context: context,
      title: AppLocalizations.of(context).editLine,
      size: ModalSize.small,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    controller: discountCtrl,
                    placeholder: AppLocalizations.of(context).discountAmount,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CupertinoTextField(
                    controller: taxCtrl,
                    placeholder: AppLocalizations.of(context).taxAmount,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: noteCtrl,
              placeholder: AppLocalizations.of(context).noteLabel,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton.filled(
                    onPressed: () {
                      Navigator.of(context).maybePop();
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
                      try {
                        context.read<CartCubit>().updateLineDetails(
                          line.variantId,
                          discountAmount: newDiscount,
                          taxAmount: newTax,
                          note: noteCtrl.text.trim().isEmpty
                              ? null
                              : noteCtrl.text.trim(),
                        );
                      } catch (_) {
                        context.read<PosCubit>().updateLineDetails(
                          line.variantId,
                          discountAmount: newDiscount,
                          taxAmount: newTax,
                          note: noteCtrl.text.trim().isEmpty
                              ? null
                              : noteCtrl.text.trim(),
                        );
                      }
                    },
                    child: Text(AppLocalizations.of(context).save),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CupertinoButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(AppLocalizations.of(context).cancel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // _amountField removed with legacy payment sheet.

  Future<void> _handleCheckout(BuildContext context) async {
    final ctx = context; // capture for async safety
    final l = AppLocalizations.of(ctx);
    try {
      final posCubit = ctx.read<PosCubit>();
      final authCubit = ctx.read<AuthCubit>();
      if (posCubit.state.cart.isEmpty) throw Exception('cart_empty');
      if (_session == null) throw Exception(l.sessionNone);
      final total = posCubit.state.cart.fold<double>(
        0,
        (s, l) => s + l.price * l.quantity,
      );
      // Collect payments via new full-screen PaymentModal
      final comp = Completer<List<Payment>?>();

      if (!ctx.mounted) return;

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

      if (!ctx.mounted) return; // Check context again before proceeding

      // Prefer using CartCubit when available so we can include per-line attributes
      List<dynamic>? overrideLines;
      try {
        final cartCubit = ctx.read<CartCubit>();
        overrideLines = cartCubit.state.cart;
      } catch (_) {
        overrideLines = null;
      }

      final saleId = await posCubit.checkoutWithPayments(
        payments: payments,
        customerId: _selectedCustomer?.id,
        itemsOverride: overrideLines
            ?.map(
              (l) => SaleItem(
                saleId: 0,
                variantId: l.variantId,
                quantity: l.quantity,
                pricePerUnit: l.price,
                costAtSale: 0,
                discountAmount: l.discountAmount,
                taxAmount: l.taxAmount,
                note: l.note,
                attributes: (l.attributes as Map?)?.cast<String, String>(),
              ),
            )
            .toList(),
      );
      if (!mounted) return;
      // تحديث المخزون والمعروض في جميع الشاشات بعد البيع مباشرة
      try {
        if (!ctx.mounted) return;
        ctx.read<InventoryCubit>().load();
        ctx.read<PosCubit>().loadCategories();
        // تحديث الكاش في السلة
        _refreshCartCash();
      } catch (_) {}
      // يمكن إضافة تحديث لشاشات أخرى مثل التقارير والجرد هنا إذا كانت تستخدم Cubit/Bloc
      if (!ctx.mounted) return;
      AppToast.show(ctx, message: l.saleSuccessTitle, type: ToastType.success);

      // Clear selected customer after successful sale
      _onCustomerChanged(null);

      if (!ctx.mounted) return;
      await showCupertinoDialog(
        context: ctx,
        barrierDismissible: false, // Prevent accidental dismissal
        builder: (dialogCtx) => Stack(
          children: [
            CupertinoAlertDialog(
              title: Text(l.saleSuccessTitle),
              content: Text(l.saleNumber(saleId)),
              actions: [
                CupertinoDialogAction(
                  child: Text(l.printReceipt),
                  onPressed: () async {
                    if (Navigator.of(dialogCtx).canPop()) {
                      Navigator.of(dialogCtx).pop();
                    }
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
                    if (!mounted || !(dialogCtx as Element).mounted) return;
                    await SystemPdfPrinter().printPdfBytes(bytes);
                  },
                ),
                CupertinoDialogAction(
                  child: Text(l.savePdf),
                  onPressed: () async {
                    if (Navigator.of(dialogCtx).canPop()) {
                      Navigator.of(dialogCtx).pop();
                    }
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
                CupertinoDialogAction(
                  child: const Text('طباعة حرارية'),
                  onPressed: () async {
                    if (Navigator.of(dialogCtx).canPop()) {
                      Navigator.of(dialogCtx).pop();
                    }
                    try {
                      final gen = await EscposGenerator80.create();
                      final salesDao = sl<SalesDao>();
                      final prodDao = sl<ProductDao>();
                      // Load item rows for this sale (map rows)
                      final rows = await salesDao.itemRowsForSale(saleId);
                      // Enrich rows with attributes when feature enabled
                      // Batch enrich rows with variant attributes
                      final variantIds = <int>[];
                      for (final row in rows) {
                        final vid =
                            (row['variant_id'] as int?) ??
                            (row['variant_id'] as num?)?.toInt();
                        if (vid != null) variantIds.add(vid);
                      }
                      if (variantIds.isNotEmpty) {
                        try {
                          final variants = await prodDao.getVariantsByIds(
                            variantIds.toSet().toList(),
                          );
                          final mapById = {for (var v in variants) v.id!: v};
                          for (final row in rows) {
                            final vid =
                                (row['variant_id'] as int?) ??
                                (row['variant_id'] as num?)?.toInt();
                            if (vid != null && mapById.containsKey(vid)) {
                              row['attributes'] =
                                  mapById[vid]!.attributes ?? [];
                            }
                          }
                        } catch (_) {
                          // ignore enrichment failures
                        }
                      }
                      final bytes = gen.buildReceiptFromRows(
                        title: 'إيصال بيع #$saleId',
                        itemRows: rows,
                        currency:
                            await sl<SettingsRepository>().get('currency') ??
                            'LYD',
                      );
                      final settings = sl<SettingsRepository>();
                      final ip =
                          (await settings.get('thermal_printer_ip')) ??
                          '192.168.1.100';
                      final port =
                          int.tryParse(
                            (await settings.get('thermal_printer_port')) ??
                                '9100',
                          ) ??
                          9100;
                      await const ThermalPrintService().sendBytesToNetwork(
                        bytes: bytes,
                        ip: ip,
                        port: port,
                      );
                    } catch (e) {
                      if (!ctx.mounted) return;
                      _showErrorDialog(ctx, l.error, e.toString());
                    }
                  },
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: AppIconButton(
                onPressed: () {
                  if (Navigator.of(dialogCtx).canPop()) {
                    Navigator.of(dialogCtx).pop();
                  }
                },
                icon: const Icon(
                  CupertinoIcons.xmark_circle,
                  size: 28,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      if (e is Exception && e.toString().contains('cart_empty')) {
        if (mounted && ctx.mounted) _showErrorDialog(ctx, l.error, l.cartEmpty);
        return;
      }
      if (mounted && ctx.mounted) _showErrorDialog(ctx, l.error, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final lBuild = AppLocalizations.of(context);
    final auth = context.watch<AuthCubit>().state;
    final hasSales =
        auth.user?.permissions.contains(AppPermissions.performSales) ?? false;
    final colors = context.colors;

    // Read live setting from SettingsCubit so UI updates when toggled
    final showImages = context.select(
      (SettingsCubit s) => s.state.showProductCardImage,
    );

    // Provide a CartCubit seeded from existing PosCubit cart so CartPanel and
    // other widgets can use it for local cart state management.
    final Widget scaffold = CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground, // خلفية بيضاء نظيفة
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        middle: Text(
          lBuild.posTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Text(
                _session == null
                    ? lBuild.sessionNone
                    : '${lBuild.sessionOpen}${_session?['id'] ?? ''}',
                style: TextStyle(
                  fontSize: AppTypography.fs11,
                  color: colors.textSecondary,
                ),
              ),
            ),
            // زر بدء الجلسة أو إغلاق الجلسة مع إزاحة بسيطة
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: _session == null
                  ? ActionButton(
                      onPressed: _promptOpenSession,
                      label: lBuild.openAction,
                    )
                  : AppPrimaryButton(
                      onPressed: () async {
                        await _handleCloseSession();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: CupertinoColors.destructiveRed,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: CupertinoColors.white,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 18,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.stop_circle,
                              color: CupertinoColors.destructiveRed,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'إغلاق الجلسة',
                              style: const TextStyle(
                                color: CupertinoColors.destructiveRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            // زر المرتجع مع إزاحة بسيطة
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: AppPrimaryButton(
                onPressed: () => Navigator.of(context).push(
                  CupertinoPageRoute(builder: (_) => const ReturnScreen()),
                ),
                child: Text(lBuild.returnLabel),
              ),
            ),
            // مجموع الكاش في أقصى اليسار
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Builder(
                builder: (context) {
                  final cashValue =
                      _session?['cash'] ?? _session?['openingFloat'] ?? 0.0;
                  return Text(
                    'مجموع الكاش: ${money(context, cashValue)}',
                    style: const TextStyle(
                      color: CupertinoColors.activeGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  );
                },
              ),
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
                        AppIconButton(
                          onPressed: _showCategoriesSheet,
                          icon: const Icon(CupertinoIcons.square_grid_2x2),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const RfidToggle(),
                        const SizedBox(width: AppSpacing.xs),
                        AppIconButton(
                          onPressed: () async {
                            final ctx = context;
                            final cubit = ctx.read<PosCubit>();
                            try {
                              final result = await BarcodeScanner.scan();
                              if (!ctx.mounted) return;
                              final code = result.rawContent;
                              if (code.isEmpty) return; // cancelled
                              final resolved = await cubit.addByBarcode(code);
                              if (!ctx.mounted) return;
                              if (resolved != null) {
                                await safeAddToCart(
                                  ctx,
                                  resolved.id,
                                  resolved.price,
                                );
                              } else {
                                final l = AppLocalizations.of(ctx);
                                AppToast.show(
                                  ctx,
                                  message: l.noProductForBarcode,
                                  type: ToastType.error,
                                );
                              }
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
                          icon: const Icon(CupertinoIcons.barcode),
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
                                  childAspectRatio: 1.0, // مربعات للمظهر الأنظف
                                ),
                            itemCount: 9,
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            itemBuilder: (c, i) => ProductGridItem(
                              variant: _shimmerVariant,
                              loading: true,
                              square: true,
                              showImage: showImages,
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
                                  text: source.substring(idx, idx + ql.length),
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
                                    final name = v.parentName.isNotEmpty
                                        ? v.parentName
                                        : (v.name ?? v.sku ?? '');
                                    final size = (v.size ?? '').toString();
                                    final color = (v.color ?? '').toString();
                                    final brand = (v.brand_name ?? '')
                                        .toString();
                                    final options = [
                                      if (brand.isNotEmpty) '[$brand] ',
                                      if (size.isNotEmpty) ' $size',
                                      if (color.isNotEmpty) ' $color',
                                    ].join().trim();
                                    return CupertinoListTile(
                                      title: RichText(text: highlight(name)),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${AppLocalizations.of(context).priceLabel} ${money(context, (v.salePrice as double))} - ${AppLocalizations.of(context).quantityLabel} ${v.quantity}${options.isNotEmpty ? '\n$options' : ''}',
                                          ),
                                          VariantAttributesDisplay(
                                            attributes:
                                                (v as dynamic).attributes,
                                          ),
                                        ],
                                      ),
                                      onTap: () async {
                                        await safeAddToCart(
                                          context,
                                          v.id as int,
                                          v.salePrice as double,
                                        );
                                      },
                                    );
                                  },
                                );
                              }
                              final crossAxisCount =
                                  (cons.maxWidth /
                                          280) // زيادة العرض للحصول على عدد أقل من الأعمدة
                                      .floor()
                                      .clamp(
                                        2,
                                        4,
                                      ); // تقليل الحد الأقصى من 6 إلى 4
                              return GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: AppSpacing.xs,
                                      mainAxisSpacing: AppSpacing.xs,
                                      childAspectRatio:
                                          1.0, // مربعات للمظهر الأنظف
                                    ),
                                itemCount: items.length,
                                itemBuilder: (context, i) {
                                  final v = items[i];
                                  int? id;
                                  double? salePrice;
                                  try {
                                    if (v is Map<String, dynamic>) {
                                      id =
                                          v['id'] as int? ??
                                          v['variant_id'] as int?;
                                      salePrice =
                                          v['salePrice'] as double? ??
                                          v['sale_price'] as double?;
                                    } else {
                                      id =
                                          (v as dynamic).id as int? ??
                                          (v as dynamic).variant_id as int?;
                                      salePrice =
                                          (v as dynamic).salePrice as double? ??
                                          (v as dynamic).sale_price as double?;
                                    }
                                  } catch (_) {
                                    id = null;
                                    salePrice = null;
                                  }
                                  return ProductGridItem(
                                    variant: v,
                                    onTap: (id != null && salePrice != null)
                                        ? () async {
                                            await safeAddToCart(
                                              context,
                                              id!,
                                              salePrice!,
                                            );
                                          }
                                        : null,
                                    square: true,
                                    showImage: showImages,
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
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              SizedBox(
                                height:
                                    120, // quick items row height (not a token size)
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: state.quickItems.length,
                                  separatorBuilder: (_, __) => const SizedBox(
                                    width: AppSpacing.xxs + 2, // 6px legacy gap
                                  ),
                                  itemBuilder: (ctx, i) {
                                    final v = state.quickItems[i];
                                    return ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minWidth: 120,
                                      ),
                                      child: ProductGridItem(
                                        variant: v,
                                        onTap: () async {
                                          await safeAddToCart(
                                            context,
                                            v.id as int,
                                            v.salePrice as double,
                                          );
                                        },
                                        square: true,
                                        showImage: showImages,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Container(height: 1, color: colors.border),
                              Expanded(child: resultsList(state.searchResults)),
                            ],
                          );
                        }
                        return resultsList(state.searchResults);
                      },
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
                            key: _cartPanelKey,
                            canCheckout: hasSales,
                            onCheckout: () => _handleCheckout(context),
                            onEdit: (line) =>
                                _showCartLineEditSheet(context, line),
                            selectedCustomer: _selectedCustomer,
                            onCustomerChanged: _onCustomerChanged,
                          ),
                        ),
                        // Removed duplicate footer summary (items/total/checkout)
                        // because CartPanel already renders it in wide layout.
                      ],
                    ),
                  ),
                ],
              );
            }
            // Wide layout (sidebar + grid + cart)
            return Row(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 260,
                    maxWidth: 320,
                  ),
                  child: CategorySidebar(),
                ),
                Container(
                  width: 1,
                  color: CupertinoColors.separator,
                ), // حد أفتح وأنظف
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
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
                            AppIconButton(
                              onPressed: _showCategoriesSheet,
                              icon: const Icon(CupertinoIcons.square_grid_2x2),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            const RfidToggle(),
                            const SizedBox(width: AppSpacing.xs),
                            AppIconButton(
                              onPressed: () async {
                                final ctx = context;
                                final cubit = ctx.read<PosCubit>();
                                try {
                                  final result = await BarcodeScanner.scan();
                                  if (!ctx.mounted) return;
                                  final code = result.rawContent;
                                  if (code.isEmpty) return; // cancelled
                                  final resolved = await cubit.addByBarcode(
                                    code,
                                  );
                                  if (!ctx.mounted) return;
                                  if (resolved != null) {
                                    await safeAddToCart(
                                      ctx,
                                      resolved.id,
                                      resolved.price,
                                    );
                                  } else {
                                    final l = AppLocalizations.of(ctx);
                                    AppToast.show(
                                      ctx,
                                      message: l.noProductForBarcode,
                                      type: ToastType.error,
                                    );
                                  }
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
                              icon: const Icon(CupertinoIcons.barcode),
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
                                      crossAxisCount:
                                          3, // قللت من 4 إلى 3 للمظهر الأوضح
                                      crossAxisSpacing: AppSpacing.xs,
                                      mainAxisSpacing: AppSpacing.xs,
                                      childAspectRatio:
                                          1.0, // مربعات للمظهر الأنظف
                                    ),
                                itemCount: 12,
                                padding: const EdgeInsets.all(AppSpacing.xs),
                                itemBuilder: (c, i) => ProductGridItem(
                                  variant: _shimmerVariant,
                                  loading: true,
                                  square: true,
                                  showImage: showImages,
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
                            final crossAxisCount =
                                (MediaQuery.of(context).size.width /
                                        280) // زيادة العرض للحصول على عدد أقل من الأعمدة
                                    .floor()
                                    .clamp(
                                      2,
                                      4,
                                    ); // تقليل الحد الأقصى من 6 إلى 4
                            return GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: AppSpacing.xs,
                                    mainAxisSpacing: AppSpacing.xs,
                                    childAspectRatio:
                                        1.0, // مربعات للمظهر الأنظف
                                  ),
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              itemCount: state.searchResults.length,
                              itemBuilder: (context, i) {
                                final v = state.searchResults[i];
                                int? id;
                                double? salePrice;
                                try {
                                  if (v is Map<String, dynamic>) {
                                    id =
                                        v['id'] as int? ??
                                        v['variant_id'] as int?;
                                    salePrice =
                                        v['salePrice'] as double? ??
                                        v['sale_price'] as double?;
                                  } else {
                                    id =
                                        (v as dynamic).id as int? ??
                                        (v as dynamic).variant_id as int?;
                                    salePrice =
                                        (v as dynamic).salePrice as double? ??
                                        (v as dynamic).sale_price as double?;
                                  }
                                } catch (_) {
                                  id = null;
                                  salePrice = null;
                                }
                                return ProductGridItem(
                                  variant: v,
                                  onTap: (id != null && salePrice != null)
                                      ? () async {
                                          await safeAddToCart(
                                            context,
                                            id!,
                                            salePrice!,
                                          );
                                        }
                                      : null,
                                  square: true,
                                  showImage: showImages,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, color: colors.border),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 320,
                    maxWidth: 420,
                  ),
                  child: Column(
                    children: [
                      if (!hasSales)
                        const ViewOnlyBanner(
                          message: 'عرض فقط: لا تملك صلاحية تنفيذ البيع',
                          margin: EdgeInsets.only(bottom: 4),
                        ),
                      Expanded(
                        child: CartPanel(
                          key: _cartPanelKey,
                          canCheckout: hasSales,
                          onCheckout: () => _handleCheckout(context),
                          onEdit: (line) =>
                              _showCartLineEditSheet(context, line),
                          selectedCustomer: _selectedCustomer,
                          onCustomerChanged: _onCustomerChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    return BlocProvider<CartCubit>(
      create: (_) => CartCubit.fromPosCart(context.read<PosCubit>().state.cart),
      child: scaffold,
    );
  }
}

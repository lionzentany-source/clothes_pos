// Reconstructed POS screen file after corruption. Clean implementation below.
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/design/system/app_typography.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:printing/printing.dart';

import 'package:clothes_pos/presentation/pos/bloc/pos_cubit.dart';
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
import 'package:clothes_pos/presentation/common/overlay/app_toast.dart';
import 'package:clothes_pos/core/printing/receipt_pdf_service.dart';
import 'package:clothes_pos/core/printing/system_pdf_printer.dart';
import 'package:clothes_pos/data/repositories/audit_repository.dart';
import 'package:clothes_pos/data/models/customer.dart';
import 'package:clothes_pos/data/repositories/cash_repository.dart';

import 'package:clothes_pos/data/repositories/settings_repository.dart';
import 'package:clothes_pos/core/printing/thermal_print_service.dart';
import 'package:clothes_pos/core/printing/escpos_generator.dart';
import 'package:clothes_pos/data/models/payment.dart';
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
  static const double _narrowBreakpoint = 900; // <= narrow stacked layout

  // Filters & search
  final _searchCtrl = TextEditingController();

  // Session
  final _cash = sl<CashRepository>();
  Map<String, dynamic>? _session;
  Customer? _selectedCustomer;

  // Narrow layout cart expansion state
  bool _cartExpanded = false;

  // Cart panel key for refreshing cash
  final GlobalKey _cartPanelKey = GlobalKey();

  void _toggleCartPanel() => setState(() => _cartExpanded = !_cartExpanded);

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

    if (!mounted) return;
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
    if (!mounted) return;
    final ctx2 = context;
    final userId = ctx2.read<AuthCubit>().state.user?.id ?? 1;
    final variance = await sl<CashRepository>().closeSession(
      sessionId: sessionId,
      closedBy: userId,
      closingAmount: amount,
    );

    if (!mounted) return;

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
    if (!mounted) return;
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
  }

  Future<void> _refreshSession() async {
    final s = await _cash.getOpenSession();
    if (mounted) setState(() => _session = s);
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
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
      final saleId = await posCubit.checkoutWithPayments(
        payments: payments,
        customerId: _selectedCustomer?.id,
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
        builder: (dialogCtx) => Stack(
          children: [
            CupertinoAlertDialog(
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
                    if (!mounted || !(dialogCtx as Element).mounted) return;
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
                CupertinoDialogAction(
                  child: const Text('طباعة حرارية'),
                  onPressed: () async {
                    Navigator.of(dialogCtx).pop();
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
              child: CupertinoButton(
                padding: const EdgeInsets.all(0),
                minimumSize: Size(32, 32),
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                },
                child: const Icon(
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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        heroTag: 'pos-bar',
        middle: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(lBuild.posTitle),
            // Tiny gap between title and session label
            const SizedBox(height: AppSpacing.xs / 2),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // زر بدء الجلسة أو إغلاق الجلسة مع إزاحة بسيطة
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: _session == null
                  ? ActionButton(
                      onPressed: _promptOpenSession,
                      label: lBuild.openAction,
                    )
                  : CupertinoButton(
                      padding: EdgeInsets.zero,
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
              child: CupertinoButton(
                padding: EdgeInsets.zero,
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

                  // Results
                  Expanded(
                    child: BlocBuilder<InventoryCubit, InventoryState>(
                      builder: (context, inventoryState) {
                        final items = inventoryState.items;
                        if (inventoryState.loading) {
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
                        if (items.isEmpty) {
                          return EmptyState(
                            title: AppLocalizations.of(context).notFound,
                            icon: CupertinoIcons.search,
                          );
                        }
                        return LayoutBuilder(
                          builder: (ctx, cons) {
                            final isGrid = cons.maxWidth >= 500;
                            if (!isGrid) {
                              return ListView(
                                children: [
                                  for (final v in items)
                                    CupertinoListTile(
                                      title: Text(
                                        v.parentName.isNotEmpty
                                            ? v.parentName
                                            : (v.variant.sku ?? ''),
                                      ),
                                      subtitle: Text(
                                        '${AppLocalizations.of(context).priceLabel} ${money(context, v.variant.salePrice)} - ${AppLocalizations.of(context).quantityLabel} ${v.variant.quantity}',
                                      ),
                                      onTap: () =>
                                          context.read<PosCubit>().addToCart(
                                            v.variant.id!,
                                            v.variant.salePrice,
                                          ),
                                    ),
                                ],
                              );
                            }
                            // حساب النسبة المثالية حسب العرض
                            double aspect;
                            if (cons.maxWidth >= 1200) {
                              aspect = 1.4;
                            } else if (cons.maxWidth >= 700) {
                              aspect = 1.6;
                            } else {
                              aspect = 1.2;
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
                                    childAspectRatio: aspect,
                                  ),
                              itemCount: items.length,
                              itemBuilder: (context, i) {
                                final v = items[i];
                                return ProductGridItem(
                                  variant: v,
                                  onTap: () =>
                                      context.read<PosCubit>().addToCart(
                                        v.variant.id!,
                                        v.variant.salePrice,
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
                      final items = state.cart.fold<int>(
                        0,
                        (s, l) => s + l.quantity,
                      );
                      final screenH = MediaQuery.of(context).size.height;
                      final expandedH = (screenH * 0.45).clamp(260.0, 420.0);
                      final panelHeight = _cartExpanded ? expandedH : 56.0;
                      // اجمالي الكاش من الجلسة
                      final cashValue =
                          _session?['cash'] ?? _session?['openingFloat'] ?? 0.0;
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
                                      // اجمالي الكاش في اعلى السلة
                                      money(context, cashValue),
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
                                  selectedCustomer: _selectedCustomer,
                                  onCustomerChanged: _onCustomerChanged,
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
                                        final name = v.parentName.isNotEmpty
                                            ? v.parentName
                                            : (v.name ?? v.sku ?? '');
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
                                              (v as dynamic).salePrice
                                                  as double? ??
                                              (v as dynamic).sale_price
                                                  as double?;
                                        }
                                      } catch (_) {
                                        id = null;
                                        salePrice = null;
                                      }
                                      return ProductGridItem(
                                        variant: v,
                                        onTap: (id != null && salePrice != null)
                                            ? () => context
                                                  .read<PosCubit>()
                                                  .addToCart(id!, salePrice!)
                                            : null,
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
          },
        ),
      ),
    );
  }
}

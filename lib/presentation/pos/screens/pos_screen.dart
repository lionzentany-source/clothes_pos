import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:printing/printing.dart';

import 'package:clothes_pos/presentation/pos/bloc/pos_cubit.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/presentation/settings/bloc/settings_cubit.dart';
import 'package:clothes_pos/presentation/pos/widgets/rfid_toggle.dart';
import 'package:clothes_pos/presentation/common/view_only_banner.dart';
import 'package:clothes_pos/presentation/common/money.dart';
import 'package:clothes_pos/data/repositories/cash_repository.dart';
import 'package:clothes_pos/data/repositories/audit_repository.dart';
import 'package:clothes_pos/core/printing/receipt_pdf_service.dart';
import 'package:clothes_pos/core/printing/system_pdf_printer.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/core/format/currency_formatter.dart';
import 'package:clothes_pos/data/models/payment.dart';
import 'package:clothes_pos/core/auth/permissions.dart';
import 'package:clothes_pos/l10n/app_localizations.dart';

import 'return_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchCtrl = TextEditingController();
  final _cash = sl<CashRepository>();
  Map<String, dynamic>? _session;

  @override
  void initState() {
    super.initState();
    _refreshSession();
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
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(AppLocalizations.of(dialogCtx)?.ok ?? 'OK'),
            onPressed: () => Navigator.of(dialogCtx).pop(),
          ),
        ],
      ),
    );
  }

  Future<List<Payment>?> _showPaymentSheet(
    BuildContext context,
    double total,
    int cashSessionId,
  ) async {
    final l = AppLocalizations.of(context);
    final cashCtrl = TextEditingController();
    final cardCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    double parse(String s) => double.tryParse(s.trim()) ?? 0;
    return showCupertinoModalPopup<List<Payment>>(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (innerCtx, setState) {
          final cash = parse(cashCtrl.text);
          final card = parse(cardCtrl.text);
          final mobile = parse(mobileCtrl.text);
          final sum = cash + card + mobile;
          final remaining = (total - (card + mobile)).clamp(0, total);
          final change = (cash - remaining).clamp(0, cash);
          return CupertinoActionSheet(
            title: Text(l?.paymentMethodsLabel ?? 'Payments'),
            message: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _amountField(l?.cash ?? 'Cash', cashCtrl, setState),
                const SizedBox(height: 6),
                _amountField(l?.card ?? 'Card', cardCtrl, setState),
                const SizedBox(height: 6),
                _amountField(l?.mobile ?? 'Mobile', mobileCtrl, setState),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: () => setState(() {
                        final rem = (total - (card + mobile)).clamp(0, total);
                        cashCtrl.text = rem.toStringAsFixed(2);
                      }),
                      child: Text(l?.exact ?? 'Exact'),
                    ),
                    for (final inc in [5, 10, 20])
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        onPressed: () => setState(() {
                          final c = parse(cashCtrl.text);
                          cashCtrl.text = (c + inc).toStringAsFixed(2);
                        }),
                        child: Text('+$inc'),
                      ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l?.remainingCashDue ?? 'Remaining Cash:'),
                    Text(remaining.toStringAsFixed(2)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l?.changeDue ?? 'Change:'),
                    Text(change.toStringAsFixed(2)),
                  ],
                ),
              ],
            ),
            actions: [
              CupertinoActionSheetAction(
                child: Text(l?.cancel ?? 'Cancel'),
                onPressed: () => Navigator.of(sheetCtx).pop(),
              ),
              CupertinoActionSheetAction(
                isDefaultAction: true,
                child: Text(l?.confirm ?? 'Confirm'),
                onPressed: () {
                  if (sum < total) return; // ignore tap until enough entered
                  var need = total;
                  final payments = <Payment>[];
                  double take(double amt, PaymentMethod m) {
                    final eff = amt.clamp(0, need).toDouble();
                    if (eff > 0) {
                      payments.add(
                        Payment(
                          amount: eff,
                          method: m,
                          cashSessionId: m == PaymentMethod.cash
                              ? cashSessionId
                              : null,
                          createdAt: DateTime.now(),
                        ),
                      );
                      need -= eff;
                    }
                    return eff;
                  }

                  take(card, PaymentMethod.card);
                  take(mobile, PaymentMethod.mobile);
                  take(cash, PaymentMethod.cash);
                  Navigator.of(sheetCtx).pop(payments);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _amountField(
    String label,
    TextEditingController ctrl,
    void Function(void Function()) setState,
  ) {
    return Row(
      children: [
        SizedBox(width: 70, child: Text(label)),
        Expanded(
          child: CupertinoTextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            placeholder: '0.00',
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Future<void> _promptOpenSession() async {
    final ctrl = TextEditingController();
    final l = AppLocalizations.of(context)!;
    final amount = await showCupertinoDialog<double>(
      context: context,
      builder: (dialogCtx) => CupertinoAlertDialog(
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
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(l.openAction),
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
    final userId = context.read<AuthCubit>().state.user?.id ?? 1;
    await _cash.openSession(openedBy: userId, openingFloat: amount);
    await _refreshSession();
  }

  Future<void> _handleCheckout(BuildContext context) async {
    // Capture cubits & localization early to avoid context lookups after awaits
    final authCubit = context.read<AuthCubit>();
    final settingsCubit = context.read<SettingsCubit>();
    var session = await _cash.getOpenSession();
    if (session == null) {
      await _promptOpenSession();
      session = await _cash.getOpenSession();
      if (session == null) {
        if (!mounted) return;
        final l = AppLocalizations.of(context)!;
        await showCupertinoDialog(
          context: context,
          builder: (dialogCtx) => CupertinoAlertDialog(
            title: Text(l.noOpenSession),
            content: Text(l.openSessionFirst),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: Text(l.ok),
              ),
            ],
          ),
        );
        return;
      }
    }
    try {
      final posCubit = context.read<PosCubit>();
      final l = AppLocalizations.of(context)!;
      final settings = settingsCubit.state;
      final total = posCubit.total;
      final payments = await _showPaymentSheet(
        context,
        total,
        session['id'] as int,
      );
      if (!mounted || payments == null) return;
      final userId = authCubit.state.user?.id ?? 1;
      final saleId = await posCubit.checkoutWithPayments(
        payments: payments,
        userId: userId,
      );
      await _refreshSession();
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (dialogCtx) => CupertinoAlertDialog(
          title: Text(l.saleSuccessTitle),
          content: Text(l.saleNumber(saleId)),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(l.ok),
              onPressed: () => Navigator.of(dialogCtx).pop(),
            ),
            CupertinoDialogAction(
              child: Text(l.printReceipt),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final service = ReceiptPdfService();
                final cashierName = authCubit.state.user?.fullName;
                final file = await service.generate(
                  saleId,
                  locale: settings.localeCode,
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
                if (!mounted) return;
                await SystemPdfPrinter().printPdfBytes(bytes, context: context);
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
                  locale: settings.localeCode,
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
      if (!mounted) return;
      if (e is Exception && e.toString().contains('cart_empty')) {
        _showErrorDialog(
          context,
          AppLocalizations.of(context)!.error,
          AppLocalizations.of(context)!.cartEmpty,
        );
        return;
      }
      _showErrorDialog(
        context,
        AppLocalizations.of(context)!.error,
        e.toString(),
      );
    }
  }

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
        title: Text(AppLocalizations.of(sheetCtx)?.editLine ?? 'Edit line'),
        message: Column(
          children: [
            CupertinoTextField(
              controller: discountCtrl,
              placeholder:
                  AppLocalizations.of(sheetCtx)?.discountAmount ??
                  'Discount (amount)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: taxCtrl,
              placeholder:
                  AppLocalizations.of(sheetCtx)?.taxAmount ?? 'Tax (amount)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: noteCtrl,
              placeholder: AppLocalizations.of(sheetCtx)?.noteLabel ?? 'Note',
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
            child: Text(AppLocalizations.of(sheetCtx)?.save ?? 'Save'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(sheetCtx).pop(),
          child: Text(AppLocalizations.of(sheetCtx)?.cancel ?? 'Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lBuild = AppLocalizations.of(context);
    final auth = context.watch<AuthCubit>().state;
    final hasSales =
        auth.user?.permissions.contains(AppPermissions.performSales) ?? false;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(lBuild?.posTitle ?? 'POS'),
            const SizedBox(height: 2),
            Text(
              _session == null
                  ? (lBuild?.sessionNone ?? 'No session')
                  : '${lBuild?.sessionOpen ?? 'Session #'}${_session?['id'] ?? ''}',
              style: const TextStyle(
                fontSize: 11,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_session == null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _promptOpenSession,
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.play_circle),
                    const SizedBox(width: 4),
                    Text(lBuild?.openAction ?? 'Open'),
                  ],
                ),
              )
            else
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () async {
                  // Close session from POS quickly
                  final l = AppLocalizations.of(context)!;
                  final ctrl = TextEditingController();
                  final amount = await showCupertinoDialog<double>(
                    context: context,
                    builder: (ctx) => CupertinoAlertDialog(
                      title: Text(l.logoutConfirmCloseSessionTitle),
                      content: Column(
                        children: [
                          const SizedBox(height: 8),
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
                  if (amount == null || _session == null || !mounted) return;
                  final userId = context.read<AuthCubit>().state.user?.id ?? 1;
                  await sl<CashRepository>().closeSession(
                    sessionId: _session!['id'] as int,
                    closedBy: userId,
                    closingAmount: amount,
                  );
                  await _refreshSession();
                },
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.stop_circle),
                    const SizedBox(width: 4),
                    Text(lBuild?.closeAction ?? 'Close'),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(builder: (_) => const ReturnScreen()),
                );
              },
              child: Text(lBuild?.returnLabel ?? 'Return'),
            ),
            BlocBuilder<PosCubit, PosState>(
              builder: (context, state) {
                final settings = context.watch<SettingsCubit>().state;
                final total = state.cart.fold(
                  0.0,
                  (s, l) => s + l.price * l.quantity,
                );
                return Text(
                  '${lBuild?.posTotal ?? 'Total'}: ${CurrencyFormatter.format(total, currency: settings.currency, locale: settings.localeCode)}',
                );
              },
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Left: search + products
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoSearchTextField(
                            controller: _searchCtrl,
                            onChanged: (v) => context.read<PosCubit>().search(
                              v,
                              categoryId: context
                                  .read<PosCubit>()
                                  .state
                                  .selectedCategoryId,
                            ),
                            placeholder:
                                AppLocalizations.of(
                                  context,
                                )?.searchPlaceholder ??
                                'Search',
                          ),
                        ),
                        const SizedBox(width: 8),
                        const RfidToggle(),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          onPressed: () async {
                            final ctx = context; // capture
                            final cubit = ctx.read<PosCubit>();
                            try {
                              final cancelText = AppLocalizations.of(
                                ctx,
                              )!.cancel;
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
                              _showErrorDialog(
                                ctx,
                                l?.notFound ?? 'Not Found',
                                l?.noProductForBarcode ??
                                    'No product found for that barcode',
                              );
                            } catch (e) {
                              if (!ctx.mounted) return;
                              final l = AppLocalizations.of(ctx);
                              _showErrorDialog(
                                ctx,
                                l?.posScanError ?? 'Scan Error',
                                e.toString(),
                              );
                            }
                          },
                          child: const Icon(CupertinoIcons.barcode),
                        ),
                      ],
                    ),
                  ),
                  if (context
                      .watch<PosCubit>()
                      .state
                      .categories
                      .isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          (AppLocalizations.of(context)?.categories ??
                              'Categories'),
                          style: CupertinoTheme.of(context).textTheme.textStyle
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 120,
                      child: Builder(
                        builder: (context) {
                          final state = context.watch<PosCubit>().state;
                          return GridView.builder(
                            scrollDirection: Axis.horizontal,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 2.6,
                                  crossAxisSpacing: 6,
                                  mainAxisSpacing: 6,
                                ),
                            itemCount: state.categories.length,
                            itemBuilder: (ctx, i) {
                              final c = state.categories[i];
                              final selected = state.selectedCategoryId == c.id;
                              return CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                color: selected
                                    ? CupertinoColors.activeBlue
                                    : CupertinoColors.systemGrey6,
                                onPressed: () =>
                                    context.read<PosCubit>().selectCategory(
                                      selected ? null : c.id as int,
                                    ),
                                child: Text(
                                  c.name,
                                  style: TextStyle(
                                    color: selected
                                        ? CupertinoColors.white
                                        : CupertinoColors.label,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Container(height: 1, color: CupertinoColors.separator),
                  ],
                  Expanded(
                    child: BlocBuilder<PosCubit, PosState>(
                      builder: (context, state) {
                        if (state.searching) {
                          return const Center(
                            child: CupertinoActivityIndicator(),
                          );
                        }
                        Widget resultsList(
                          List<dynamic> items,
                        ) => ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final v = items[i];
                            final name = v.parent_name ?? v.name ?? v.sku;
                            final size = (v.size ?? '').toString();
                            final color = (v.color ?? '').toString();
                            final brand = (v.brand_name ?? '').toString();
                            final options = [
                              if (brand.isNotEmpty) '[$brand] ',
                              if (size.isNotEmpty) ' $size',
                              if (color.isNotEmpty) ' $color',
                            ].join().trim();
                            return CupertinoListTile(
                              title: Text(name),
                              subtitle: Text(
                                '${AppLocalizations.of(context)?.priceLabel ?? 'Price:'} ${money(context, (v.salePrice as double))} — ${AppLocalizations.of(context)?.quantityLabel ?? 'Qty:'} ${v.quantity}${options.isNotEmpty ? '\n$options' : ''}',
                              ),
                              onTap: () => context.read<PosCubit>().addToCart(
                                v.id as int,
                                v.salePrice as double,
                              ),
                            );
                          },
                        );
                        if (state.quickItems.isNotEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)?.quickItems ??
                                      'Quick',
                                  style: CupertinoTheme.of(context)
                                      .textTheme
                                      .textStyle
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              SizedBox(
                                height: 120,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: state.quickItems.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 6),
                                  itemBuilder: (ctx, i) {
                                    final v = state.quickItems[i];
                                    return ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minWidth: 120,
                                      ),
                                      child: CupertinoButton(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        onPressed: () =>
                                            context.read<PosCubit>().addToCart(
                                              v.id as int,
                                              v.salePrice as double,
                                            ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              v.sku,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              money(
                                                context,
                                                v.salePrice as double,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Container(
                                height: 1,
                                color: CupertinoColors.separator,
                              ),
                              Expanded(child: resultsList(state.searchResults)),
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
            Container(width: 1, color: CupertinoColors.separator),
            // Right: cart
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(AppLocalizations.of(context)!.basket),
                  ),
                  Expanded(
                    child: BlocBuilder<PosCubit, PosState>(
                      builder: (context, state) => ListView.builder(
                        itemCount: state.cart.length,
                        itemBuilder: (context, i) {
                          final l = state.cart[i];
                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'ID ${l.variantId} — ${money(context, l.price)}',
                                ),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => context
                                    .read<PosCubit>()
                                    .changeQty(l.variantId, l.quantity - 1),
                                child: const Icon(CupertinoIcons.minus_circled),
                              ),
                              Text('${l.quantity}'),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => context
                                    .read<PosCubit>()
                                    .changeQty(l.variantId, l.quantity + 1),
                                child: const Icon(CupertinoIcons.add_circled),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () =>
                                    _showCartLineEditSheet(context, l),
                                child: const Icon(CupertinoIcons.pencil),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => context
                                    .read<PosCubit>()
                                    .removeLine(l.variantId),
                                child: const Icon(CupertinoIcons.delete_simple),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!hasSales)
                          const ViewOnlyBanner(
                            message: 'عرض فقط: لا تملك صلاحية تنفيذ البيع',
                            margin: EdgeInsets.only(bottom: 4),
                          ),
                        CupertinoButton.filled(
                          onPressed: !hasSales
                              ? null
                              : () => _handleCheckout(context),
                          child: Text(AppLocalizations.of(context)!.checkout),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

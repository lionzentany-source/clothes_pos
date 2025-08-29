import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/cash_repository.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/core/printing/cash_session_report_service.dart';
import 'package:clothes_pos/presentation/common/money.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';
import 'package:printing/printing.dart';

import 'package:clothes_pos/presentation/common/widgets/action_button.dart';

class CashSessionScreen extends StatefulWidget {
  const CashSessionScreen({super.key});

  @override
  State<CashSessionScreen> createState() => _CashSessionScreenState();
}

class _CashSessionScreenState extends State<CashSessionScreen> {
  final _repo = sl<CashRepository>();
  Map<String, Object?>? _session;
  bool _loading = true;
  String? _error;
  Map<String, Object?>? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await _repo.getOpenSession();
      Map<String, Object?>? summary;
      if (s != null) {
        summary = await _repo.getSessionSummary(s['id'] as int);
      }
      if (!mounted) return;
      setState(() {
        _session = s;
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openSession() async {
    final ctrl = TextEditingController();
    final amount = await showCupertinoDialog<double>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context).openSessionTitle),
        content: Column(
          children: [
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.6,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      placeholder: AppLocalizations.of(context).openingFloat,
                      controller: ctrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(AppLocalizations.of(context).openAction),
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              if (v == null) return;
              Navigator.pop(ctx, v);
            },
          ),
        ],
      ),
    );
    if (amount == null) return;
    if (!mounted) return;
    final userId = context.read<AuthCubit>().state.user?.id ?? 1;
    await _repo.openSession(openedBy: userId, openingFloat: amount);
    await _load();
  }

  Future<void> _closeSession() async {
    if (_session == null) return;
    final ctrl = TextEditingController();
    final amount = await showCupertinoDialog<double>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          AppLocalizations.of(context).logoutConfirmCloseSessionTitle,
        ),
        content: Column(
          children: [
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.6,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      placeholder: AppLocalizations.of(
                        context,
                      ).actualDrawerAmount,
                      controller: ctrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(AppLocalizations.of(context).closeAction),
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              if (v == null) return;
              Navigator.pop(ctx, v);
            },
          ),
        ],
      ),
    );
    if (amount == null) return;
    if (!mounted) return;
    final userId = context.read<AuthCubit>().state.user?.id ?? 1;
    final variance = await _repo.closeSession(
      sessionId: _session!['id'] as int,
      closedBy: userId,
      closingAmount: amount,
    );
    if (!mounted) return;
    await showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context).closedTitle),
        content: Text(
          AppLocalizations.of(context).variance(variance.toStringAsFixed(2)),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(AppLocalizations.of(context).ok),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
    await _load();
  }

  Future<void> _movement(bool isIn) async {
    if (_session == null) return;
    final ctrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final amount = await showCupertinoDialog<double>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          isIn
              ? AppLocalizations.of(context).cashDepositTitle
              : AppLocalizations.of(context).cashWithdrawTitle,
        ),
        content: Column(
          children: [
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.6,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      placeholder: AppLocalizations.of(context).amount,
                      controller: ctrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      placeholder: AppLocalizations.of(context).reasonOptional,
                      controller: reasonCtrl,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(AppLocalizations.of(context).confirm),
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              if (v == null) return;
              Navigator.pop(ctx, v);
            },
          ),
        ],
      ),
    );
    if (amount == null) return;
    if (isIn) {
      await _repo.cashIn(
        sessionId: _session!['id'] as int,
        amount: amount,
        reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
      );
    } else {
      await _repo.cashOut(
        sessionId: _session!['id'] as int,
        amount: amount,
        reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
      );
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppLocalizations.of(context).cashSessionTitle),
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _session == null
                              ? AppLocalizations.of(context).noOpenSession
                              : '${AppLocalizations.of(context).sessionOpen}${_session!['id']}',
                        ),
                        if (_session == null)
                          ActionButton(
                            label: AppLocalizations.of(context).openAction,
                            onPressed: _openSession,
                            leading: const Icon(
                              CupertinoIcons.play_arrow,
                              size: 18,
                              color: CupertinoColors.white,
                            ),
                          )
                        else
                          ActionButton(
                            label: AppLocalizations.of(context).closeAction,
                            onPressed: _closeSession,
                            color: CupertinoColors.destructiveRed,
                            leading: Icon(
                              CupertinoIcons.stop,
                              size: 18,
                              color: CupertinoColors.white,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_session != null && _summary != null) ...[
                      Builder(
                        builder: (ctx) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).openingFloatLabel(
                                  money(
                                    context,
                                    (_summary!['opening_float'] as num?)
                                            ?.toDouble() ??
                                        0,
                                  ),
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context).cashSales(
                                  money(
                                    context,
                                    (_summary!['sales_cash'] as num?)
                                            ?.toDouble() ??
                                        0,
                                  ),
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context).depositsLabel(
                                  money(
                                    context,
                                    (_summary!['cash_in'] as num?)
                                            ?.toDouble() ??
                                        0,
                                  ),
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context).withdrawalsLabel(
                                  money(
                                    context,
                                    (_summary!['cash_out'] as num?)
                                            ?.toDouble() ??
                                        0,
                                  ),
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context).expectedCash(
                                  money(
                                    context,
                                    (_summary!['expected_cash'] as num?)
                                            ?.toDouble() ??
                                        0,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              onPressed: () => _movement(true),
                              child: Text(
                                AppLocalizations.of(context).depositAction,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CupertinoButton(
                              onPressed: () => _movement(false),
                              child: Text(
                                AppLocalizations.of(context).withdrawAction,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              color: CupertinoColors.activeBlue,
                              onPressed: () async {
                                final l = AppLocalizations.of(context);
                                // New localization getters not yet generated; use existing ones with placeholders.
                                final file = await CashSessionReportService()
                                    .generateXReport(
                                      _session!['id'] as int,
                                      title: l.xReport,
                                      sessionLabel: '${l.sessionOpen}{id}',
                                      openingFloatLabel: l.openingFloatLabel(
                                        '{value}',
                                      ),
                                      cashSalesLabel: l.cashSales('{value}'),
                                      depositsLabel: l.depositsLabel('{value}'),
                                      withdrawalsLabel: l.withdrawalsLabel(
                                        '{value}',
                                      ),
                                      expectedCashLabel: l.expectedCash(
                                        '{value}',
                                      ),
                                    );
                                if (!mounted) return;
                                await Printing.layoutPdf(
                                  onLayout: (_) async => file.readAsBytes(),
                                );
                              },
                              child: Text(AppLocalizations.of(context).xReport),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CupertinoButton(
                              color: CupertinoColors.activeBlue,
                              onPressed: () async {
                                // Z report usually after close; use current expected cash
                                final l = AppLocalizations.of(context);
                                final file = await CashSessionReportService()
                                    .generateZReport(
                                      _session!['id'] as int,
                                      closingAmount:
                                          (_session!['closing_amount'] as num?)
                                              ?.toDouble(),
                                      variance: (_session!['variance'] as num?)
                                          ?.toDouble(),
                                      title: l.zReport,
                                      sessionLabel: '${l.sessionOpen}{id}',
                                      openingFloatLabel: l.openingFloatLabel(
                                        '{value}',
                                      ),
                                      cashSalesLabel: l.cashSales('{value}'),
                                      depositsLabel: l.depositsLabel('{value}'),
                                      withdrawalsLabel: l.withdrawalsLabel(
                                        '{value}',
                                      ),
                                      expectedCashLabel: l.expectedCash(
                                        '{value}',
                                      ),
                                      actualAmountLabel: l.actualDrawerAmount
                                          .replaceFirst('{value}', '{value}'),
                                      varianceLabelTemplate: l.variance(
                                        '{value}',
                                      ),
                                    );
                                if (!mounted) return;
                                await Printing.layoutPdf(
                                  onLayout: (_) async => file.readAsBytes(),
                                );
                              },
                              child: Text(AppLocalizations.of(context).zReport),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

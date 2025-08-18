import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/models/purchase_invoice.dart';
import 'package:clothes_pos/data/models/purchase_invoice_item.dart';
import 'package:clothes_pos/data/repositories/purchase_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/core/auth/permissions.dart';
import 'package:clothes_pos/presentation/common/money.dart';
import 'package:clothes_pos/presentation/common/view_only_banner.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});
  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  final _repo = sl<PurchaseRepository>();
  bool _loading = true;
  List<PurchaseInvoice> _invoices = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _invoices = await _repo.listInvoices(limit: 200);
      setState(() {});
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPurchase =
        context.watch<AuthCubit>().state.user?.permissions.contains(
          AppPermissions.performPurchases,
        ) ??
        false;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('فواتير المشتريات'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.refresh),
          onPressed: (_loading || !canPurchase) ? null : _load,
        ),
      ),
      child: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : SafeArea(
              child: ListView.separated(
                padding: const EdgeInsets.only(top: 8),
                itemCount: _invoices.length + (canPurchase ? 0 : 1),
                separatorBuilder: (_, __) => const SizedBox(height: 1),
                itemBuilder: (context, i) {
                  if (!canPurchase && i == 0) {
                    return const ViewOnlyBanner(
                      message: 'عرض فقط: لا تملك صلاحية إدارة فواتير المشتريات',
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    );
                  }
                  final index = canPurchase ? i : i - 1;
                  final inv = _invoices[index];
                  return CupertinoListTile(
                    title: Text(
                      'المورد #${inv.supplierId} — ${inv.reference ?? ''}',
                    ),
                    subtitle: Text(
                      inv.receivedDate.toString().split('T').first,
                    ),
                    trailing: Text(money(context, inv.totalCost)),
                    onTap: () async {
                      await Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => PurchaseDetailsScreen(invoice: inv),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

class PurchaseDetailsScreen extends StatefulWidget {
  final PurchaseInvoice invoice;
  const PurchaseDetailsScreen({super.key, required this.invoice});
  @override
  State<PurchaseDetailsScreen> createState() => _PurchaseDetailsScreenState();
}

class _PurchaseDetailsScreenState extends State<PurchaseDetailsScreen> {
  final _repo = sl<PurchaseRepository>();
  bool _loading = true;
  List<PurchaseInvoiceItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _repo.itemsForInvoice(widget.invoice.id!);
      setState(() {});
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('فاتورة #${inv.id ?? ''}'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.refresh),
          onPressed: _loading ? null : _load,
        ),
      ),
      child: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Text('المورد: ${inv.supplierId}'),
                  Text('المرجع: ${inv.reference ?? '-'}'),
                  Text(
                    'التاريخ: ${inv.receivedDate.toString().split('T').first}',
                  ),
                  Text('الإجمالي: ${money(context, inv.totalCost)}'),
                  const SizedBox(height: 12),
                  const Text('العناصر'),
                  for (final it in _items)
                    Text(
                      'Var ${it.variantId} — Qty ${it.quantity} — Cost ${money(context, it.costPrice)}',
                    ),
                ],
              ),
            ),
    );
  }
}

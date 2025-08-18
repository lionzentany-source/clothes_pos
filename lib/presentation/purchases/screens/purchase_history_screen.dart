import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/models/purchase_invoice.dart';
import 'package:clothes_pos/data/models/purchase_invoice_item.dart';
import 'package:clothes_pos/data/repositories/purchase_repository.dart';
import 'package:flutter/cupertino.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});
  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
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
      _invoices = await _repo.listInvoices(limit: 100);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('سجل المشتريات'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _loading ? null : _load,
          child: const Icon(CupertinoIcons.refresh),
        ),
      ),
      child: _loading
          ? const Center(child: CupertinoActivityIndicator())
          : SafeArea(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _invoices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final inv = _invoices[i];
                  return CupertinoListTile(
                    title: Text('فاتورة #${inv.id} — ${inv.reference ?? ''}'),
                    subtitle: Text('المورد: ${inv.supplierId} — التكلفة: ${inv.totalCost.toStringAsFixed(2)}'),
                    onTap: () => Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => PurchaseDetailsScreen(invoice: inv),
                      ),
                    ),
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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('فاتورة #${inv.id}'),
        trailing: _loading ? const CupertinoActivityIndicator() : null,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text('المورد: ${inv.supplierId}'),
            Text('المرجع: ${inv.reference ?? '-'}'),
            Text('التاريخ: ${inv.receivedDate.toIso8601String()}'),
            Text('الإجمالي: ${inv.totalCost.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            const Text('العناصر:'),
            const SizedBox(height: 6),
            if (_loading)
              const Center(child: CupertinoActivityIndicator())
            else if (_items.isEmpty)
              const Text('لا توجد عناصر')
            else
              ..._items.map(
                (it) => CupertinoListTile(
                  title: Text('Variant ${it.variantId} — Qty ${it.quantity}'),
                  subtitle: Text('Cost ${it.costPrice.toStringAsFixed(2)}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


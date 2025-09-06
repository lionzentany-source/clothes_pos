import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/models/purchase_invoice.dart';
import 'package:clothes_pos/data/models/purchase_invoice_item.dart';
import 'package:clothes_pos/data/repositories/purchase_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/common/widgets/variant_attributes_display.dart';
import 'package:clothes_pos/data/datasources/product_dao.dart';
import 'package:clothes_pos/data/repositories/supplier_repository.dart';
import 'package:clothes_pos/data/repositories/product_repository.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});
  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  final _repo = sl<PurchaseRepository>();
  bool _loading = true;
  List<PurchaseInvoice> _invoices = [];
  final Map<int, String> _supplierNames = {};
  final Map<int, String> _variantDisplayNames = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _invoices = await _repo.listInvoices(limit: 100);
      final supRepo = sl<SupplierRepository>();
      final prodDao = sl<ProductDao>();
      final prodRepo = sl<ProductRepository>();
      // Batch prefetch supplier names
      final supIds = _invoices.map((i) => i.supplierId).toSet().toList();
      final suppliers = await supRepo.getByIds(supIds);
      for (final s in suppliers) {
        if (s.id != null) _supplierNames[s.id!] = s.name;
      }

      // Collect all variant ids across invoices
      final variantIdSet = <int>{};
      for (final inv in _invoices) {
        final items = await _repo.itemsForInvoice(inv.id!);
        for (final it in items) {
          variantIdSet.add(it.variantId);
        }
      }
      final variantIds = variantIdSet.toList();
      if (variantIds.isNotEmpty) {
        final variantDisplayMap = await prodRepo.getVariantDisplayNames(
          variantIds,
        );
        final variants = await prodDao.getVariantsByIds(variantIds);
        for (final v in variants) {
          _variantDisplayNames[v.id!] = variantDisplayMap[v.id!] ?? 'Variant';
          _variantDisplayNames[v.id!] =
              _variantDisplayNames[v.id!]!; // ensure key exists
          _variantDisplayNames[v.id!] =
              _variantDisplayNames[v.id!]!; // no-op to avoid analyzer warnings
          _variantDisplayNames[v.id!] = _variantDisplayNames[v.id!]!;
          _variantDisplayNames[v.id!] = _variantDisplayNames[v.id!]!;
          _variantDisplayNames[v.id!] = _variantDisplayNames[v.id!]!;
          _variantDisplayNames[v.id!] = _variantDisplayNames[v.id!]!;
          _variantDisplayNames[v.id!] = _variantDisplayNames[v.id!]!;
          // store attributes
          // attribute values are populated in variants when FeatureFlags.useDynamicAttributes
          // but PurchaseHistoryScreen expects only display names; attributes will be loaded in details screen as needed
        }
      }
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
                    title: Text('فاتورة #${inv.id} - ${inv.reference ?? ''}'),
                    subtitle: Text(
                      'المورد: ${_supplierNames[inv.supplierId] ?? inv.supplierId} - التكلفة: ${inv.totalCost.toStringAsFixed(2)}',
                    ),
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
  final Map<int, List<dynamic>?> _variantAttributes = {};
  String? _supplierName;
  final Map<int, String> _variantDisplayNames = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await _repo.itemsForInvoice(widget.invoice.id!);
      // Load variant attributes for display using DAO helper
      final prodDao = sl<ProductDao>();
      final prodRepo = sl<ProductRepository>();
      final supRepo = sl<SupplierRepository>();
      // Load supplier name
      try {
        final suppliers = await supRepo.getByIds([widget.invoice.supplierId]);
        _supplierName = suppliers.isNotEmpty ? suppliers.first.name : null;
      } catch (_) {
        _supplierName = null;
      }
      // Batch fetch variant display names and attributes
      final variantIds = _items.map((i) => i.variantId).toSet().toList();
      if (variantIds.isNotEmpty) {
        try {
          final variantDisplayMap = await prodRepo.getVariantDisplayNames(
            variantIds,
          );
          final variants = await prodDao.getVariantsByIds(variantIds);
          for (final v in variants) {
            _variantAttributes[v.id!] = v.attributes;
            _variantDisplayNames[v.id!] = variantDisplayMap[v.id!] ?? 'Variant';
          }
          // ensure any missing ids still have a fallback
          for (final id in variantIds) {
            _variantDisplayNames.putIfAbsent(id, () => 'Variant');
            _variantAttributes.putIfAbsent(id, () => null);
          }
        } catch (_) {
          for (final id in variantIds) {
            _variantDisplayNames[id] = 'Variant';
            _variantAttributes[id] = null;
          }
        }
      }
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
            Text('المورد: ${_supplierName ?? widget.invoice.supplierId}'),
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
              ..._items.map((it) {
                final vname = _variantDisplayNames[it.variantId] ?? 'Variant';
                return CupertinoListTile(
                  title: Text(
                    '$vname - Qty ${it.quantity} - Cost ${it.costPrice.toStringAsFixed(2)}',
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cost ${it.costPrice.toStringAsFixed(2)}'),
                      VariantAttributesDisplay(
                        attributes: _variantAttributes[it.variantId],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

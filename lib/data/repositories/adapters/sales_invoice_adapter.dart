import 'package:clothes_pos/data/models/sale.dart';
import 'package:clothes_pos/data/models/sale_item.dart';
import 'package:clothes_pos/data/repositories/sales_repository.dart';
import 'package:clothes_pos/data/repositories/interfaces/invoice_repository.dart';

class SalesInvoiceAdapter implements InvoiceRepository {
  final SalesRepository _sales;
  SalesInvoiceAdapter(this._sales);

  @override
  Future<int> createInvoice({
    required Sale sale,
    required List<SaleItem> items,
  }) {
    return _sales.createSale(sale: sale, items: items, payments: const []);
  }

  @override
  Future<int> createInvoiceFromPayload(Map<String, Object?> payload) async {
    // Expect payload shape: { 'sale': Map, 'items': List<Map>, 'payments': List<Map> (optional) }
    final saleMap = payload['sale'] as Map<String, Object?>?;
    final itemsRaw =
        (payload['items'] as List?)?.cast<Map<String, Object?>>() ?? [];
    if (saleMap == null) throw Exception('Invalid payload: missing sale');

    final sale = Sale.fromMap(saleMap);
    final items = itemsRaw.map((m) => SaleItem.fromMap(m)).toList();

    // Note: SalesRepository.createSale requires Payment models; adapter leaves payments empty
    return createInvoice(sale: sale, items: items);
  }
}

import 'package:clothes_pos/data/models/sale.dart';
import 'package:clothes_pos/data/models/sale_item.dart';

abstract class InvoiceRepository {
  Future<int> createInvoice({
    required Sale sale,
    required List<SaleItem> items,
  });

  Future<int> createInvoiceFromPayload(Map<String, Object?> payload);
}

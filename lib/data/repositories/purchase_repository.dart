import 'package:clothes_pos/data/datasources/purchase_dao.dart';
import 'package:clothes_pos/data/models/purchase_invoice.dart';
import 'package:clothes_pos/data/models/purchase_invoice_item.dart';

class PurchaseRepository {
  final PurchaseDao dao;
  PurchaseRepository(this.dao);

  Future<int> createInvoice(
    PurchaseInvoice invoice,
    List<PurchaseInvoiceItem> items,
  ) => dao.insertInvoice(invoice, items);

  Future<int> createInvoiceWithRfids(
    PurchaseInvoice invoice,
    List<PurchaseInvoiceItem> items,
    List<List<String>> rfidsByItem,
  ) => dao.insertInvoiceWithRfids(invoice, items, rfidsByItem);
  Future<List<PurchaseInvoice>> listInvoices({
    int limit = 50,
    int offset = 0,
  }) => dao.listInvoices(limit: limit, offset: offset);
  Future<List<PurchaseInvoiceItem>> itemsForInvoice(int invoiceId) =>
      dao.itemsForInvoice(invoiceId);
}

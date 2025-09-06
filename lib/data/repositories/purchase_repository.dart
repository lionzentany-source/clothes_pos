import 'package:clothes_pos/data/datasources/purchase_dao.dart';
import 'package:clothes_pos/data/models/purchase_invoice.dart';
import 'package:clothes_pos/data/models/purchase_invoice_item.dart';
import 'package:clothes_pos/core/result/result.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';

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

  Future<Result<int>> createInvoiceResult(
    PurchaseInvoice invoice,
    List<PurchaseInvoiceItem> items,
  ) async {
    try {
      final id = await createInvoice(invoice, items);
      return ok(id);
    } catch (e, st) {
      AppLogger.e('createInvoice failed', error: e, stackTrace: st);
      return fail(
        'فشل حفظ فاتورة الشراء',
        code: 'purchase_create',
        exception: e,
        stackTrace: st,
        retryable: true,
      );
    }
  }

  Future<Result<int>> createInvoiceWithRfidsResult(
    PurchaseInvoice invoice,
    List<PurchaseInvoiceItem> items,
    List<List<String>> rfidsByItem,
  ) async {
    try {
      final id = await createInvoiceWithRfids(invoice, items, rfidsByItem);
      return ok(id);
    } catch (e, st) {
      AppLogger.e('createInvoiceWithRfids failed', error: e, stackTrace: st);
      return fail(
        'فشل حفظ فاتورة الشراء (RFID)',
        code: 'purchase_create_rfids',
        exception: e,
        stackTrace: st,
        retryable: true,
      );
    }
  }

  Future<List<PurchaseInvoice>> listInvoices({
    int limit = 50,
    int offset = 0,
  }) => dao.listInvoices(limit: limit, offset: offset);
  Future<List<PurchaseInvoiceItem>> itemsForInvoice(int invoiceId) =>
      dao.itemsForInvoice(invoiceId);
}

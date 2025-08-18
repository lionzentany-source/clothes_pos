import 'package:clothes_pos/core/db/database_helper.dart';

Future<void> cleanupTestData() async {
  final db = await DatabaseHelper.instance.database;
  await db.transaction((txn) async {
    // Gather variants and parents created by tests (by SKU prefix)
    final vRows = await txn.rawQuery(
      '''
      SELECT id, parent_product_id FROM product_variants
      WHERE sku LIKE 'E2E_%' OR sku LIKE 'RET_%' OR sku LIKE 'CS_%' OR sku LIKE 'UAT_%'
      ''',
    );
    if (vRows.isEmpty) return; // nothing to clean
    final variantIds = vRows.map((e) => e['id'] as int).toList();
    final parentIds = vRows.map((e) => e['parent_product_id'] as int).toSet().toList();

    String inClause(List ints) => ints.isEmpty ? '(NULL)' : '(${List.filled(ints.length, '?').join(',')})';

    // Related sale ids
    final saleRows = await txn.rawQuery(
      'SELECT DISTINCT sale_id FROM sale_items WHERE variant_id IN ${inClause(variantIds)}',
      variantIds,
    );
    final saleIds = saleRows.map((e) => e['sale_id'] as int).toList();

    // Delete returns items then returns
    await txn.rawDelete(
      'DELETE FROM sales_return_items WHERE sale_item_id IN (SELECT id FROM sale_items WHERE variant_id IN ${inClause(variantIds)})',
      variantIds,
    );
    if (saleIds.isNotEmpty) {
      await txn.rawDelete(
        'DELETE FROM sales_returns WHERE sale_id IN ${inClause(saleIds)}',
        saleIds,
      );
    }

    // Delete payments for those sales
    if (saleIds.isNotEmpty) {
      await txn.rawDelete(
        'DELETE FROM payments WHERE sale_id IN ${inClause(saleIds)}',
        saleIds,
      );
    }

    // Delete sale items then sales
    await txn.rawDelete(
      'DELETE FROM sale_items WHERE variant_id IN ${inClause(variantIds)}',
      variantIds,
    );
    if (saleIds.isNotEmpty) {
      await txn.rawDelete(
        'DELETE FROM sales WHERE id IN ${inClause(saleIds)}',
        saleIds,
      );
    }

    // Delete purchase invoice items for those variants, then any empty or test refs invoices
    await txn.rawDelete(
      'DELETE FROM purchase_invoice_items WHERE variant_id IN ${inClause(variantIds)}',
      variantIds,
    );
    await txn.rawDelete(
      "DELETE FROM purchase_invoices WHERE reference LIKE 'INV-%' OR reference LIKE 'RINV-%' OR reference LIKE 'UAT%'",
    );

    // Delete inventory movements for those variants
    await txn.rawDelete(
      'DELETE FROM inventory_movements WHERE variant_id IN ${inClause(variantIds)}',
      variantIds,
    );

    // Delete expenses created by tests
    await txn.rawDelete(
      "DELETE FROM expenses WHERE description LIKE 'E2E%' OR description LIKE 'UAT%'",
    );

    // Delete any cash sessions used in tests (after removing payments/expenses)
    await txn.rawDelete(
      "DELETE FROM cash_sessions WHERE opened_by = 1 AND (opening_float IN (50.0, 100.0)) AND date(opened_at) >= date('now','-3 days')",
    );

    // Delete variants then parents
    await txn.rawDelete(
      'DELETE FROM product_variants WHERE id IN ${inClause(variantIds)}',
      variantIds,
    );
    if (parentIds.isNotEmpty) {
      await txn.rawDelete(
        'DELETE FROM parent_products WHERE id IN ${inClause(parentIds)}',
        parentIds,
      );
    }

    // Delete suppliers created by tests
    await txn.rawDelete(
      "DELETE FROM suppliers WHERE name LIKE 'Supplier %' OR name LIKE 'UAT Supplier %'",
    );
  });
}


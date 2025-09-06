import 'dart:async';

import 'package:clothes_pos/data/models/attribute.dart';
import 'package:clothes_pos/data/repositories/attribute_repository.dart'
    as repo_attr;
import 'package:clothes_pos/data/repositories/customer_repository.dart'
    as repo_cust;
import 'package:clothes_pos/data/repositories/inventory_repository.dart'
    as repo_inv;
import 'package:clothes_pos/data/repositories/product_repository.dart'
    as repo_prod;
import 'package:clothes_pos/data/repositories/purchase_repository.dart'
    as repo_purchase;
import 'package:clothes_pos/data/repositories/sales_repository.dart'
    as repo_sales;
import 'package:clothes_pos/data/repositories/returns_repository.dart'
    as repo_returns;
import 'package:clothes_pos/data/repositories/expense_repository.dart'
    as repo_expense;
import 'package:clothes_pos/data/repositories/reports_repository.dart'
    as repo_reports;
import 'package:clothes_pos/core/result/result.dart';
import 'package:clothes_pos/data/models/customer.dart';
import 'package:clothes_pos/data/models/inventory_item_row.dart';
import 'package:clothes_pos/data/models/parent_product.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:clothes_pos/data/models/purchase_invoice.dart';
import 'package:clothes_pos/data/models/purchase_invoice_item.dart';
import 'package:clothes_pos/data/models/sale.dart';
import 'package:clothes_pos/data/models/sale_item.dart';
import 'package:clothes_pos/data/models/payment.dart';
import 'package:clothes_pos/data/models/inventory_movement.dart';
import 'package:clothes_pos/data/datasources/returns_dao.dart';
import 'package:clothes_pos/data/datasources/customer_dao.dart';
import 'package:clothes_pos/data/datasources/product_dao.dart';
import 'package:clothes_pos/data/datasources/purchase_dao.dart';
import 'package:clothes_pos/data/datasources/sales_dao.dart';
import 'package:clothes_pos/data/datasources/reports_dao.dart';
import 'package:clothes_pos/data/datasources/expense_dao.dart';
import 'package:clothes_pos/data/models/expense.dart';
import 'package:clothes_pos/data/models/expense_category.dart';

// Minimal in-memory repository fakes implementing the methods the app uses.
// These are intentionally small and return the shapes expected by cubits.

class InMemoryAttributeRepository implements repo_attr.AttributeRepository {
  final _attrs = <Attribute>[];
  final _attrValues = <AttributeValue>[];
  int _attrId = 1;
  int _attrValueId = 1;

  @override
  Future<List<Attribute>> getAllAttributes() async => List.from(_attrs);

  @override
  Future<Attribute> getAttributeById(int id) async {
    return _attrs.firstWhere((a) => a.id == id);
  }

  @override
  Future<int> createAttribute(Attribute attribute) async {
    final newAttr = attribute.copyWith(id: _attrId++);
    _attrs.add(newAttr);
    return newAttr.id!;
  }

  @override
  Future<int> updateAttribute(Attribute attribute) async {
    final i = _attrs.indexWhere((a) => a.id == attribute.id);
    if (i >= 0) {
      _attrs[i] = attribute;
      return 1;
    }
    return 0;
  }

  @override
  Future<int> deleteAttribute(int id) async {
    final initialLength = _attrs.length;
    _attrs.removeWhere((a) => a.id == id);
    return initialLength - _attrs.length;
  }

  @override
  Future<List<AttributeValue>> getAttributeValues(int attributeId) async {
    return _attrValues.where((v) => v.attributeId == attributeId).toList();
  }

  @override
  Future<int> createAttributeValue(AttributeValue value) async {
    final newValue = value.copyWith(id: _attrValueId++);
    _attrValues.add(newValue);
    return newValue.id!;
  }

  @override
  Future<int> updateAttributeValue(AttributeValue value) async {
    final i = _attrValues.indexWhere((v) => v.id == value.id);
    if (i >= 0) {
      _attrValues[i] = value;
      return 1;
    }
    return 0;
  }

  @override
  Future<int> deleteAttributeValue(int id) async {
    final initialLength = _attrValues.length;
    _attrValues.removeWhere((v) => v.id == id);
    return initialLength - _attrValues.length;
  }
}

class InMemoryCustomerRepository implements repo_cust.CustomerRepository {
  final _customers = <Customer>[];
  int _auto = 1;

  @override
  CustomerDao get dao => throw UnimplementedError();

  @override
  Future<int> create(Customer customer, {int? userId}) async {
    final newCustomer = customer.copyWith(id: _auto++);
    _customers.add(newCustomer);
    return newCustomer.id!;
  }

  @override
  Future<Result<int>> createResult(Customer customer, {int? userId}) async {
    if (_customers.any((c) => c.phoneNumber == customer.phoneNumber)) {
      return fail('Phone number exists');
    }
    final id = await create(customer, userId: userId);
    return ok(id);
  }

  @override
  Future<void> delete(int id, {int? userId}) async {
    _customers.removeWhere((c) => c.id == id);
  }

  @override
  Future<Result<void>> deleteResult(int id, {int? userId}) async {
    delete(id, userId: userId);
    return ok(null);
  }

  @override
  Future<Customer?> getById(int id) async {
    final matches = _customers.where((c) => c.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<Result<Customer?>> getByIdResult(int id) async {
    return ok(await getById(id));
  }

  @override
  Future<Customer?> getByPhoneNumber(String phoneNumber) async {
    final matches = _customers.where((c) => c.phoneNumber == phoneNumber);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<int> getCount() async {
    return _customers.length;
  }

  @override
  Future<List<Map<String, Object?>>> getCustomersWithSalesStats({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    return [];
  }

  @override
  Future<List<Map<String, Object?>>> getTopCustomers({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    return [];
  }

  @override
  Future<List<Customer>> listAll({int limit = 100, int offset = 0}) async {
    return _customers.skip(offset).take(limit).toList();
  }

  @override
  Future<bool> phoneNumberExists(String phoneNumber, {int? excludeId}) async {
    return _customers.any(
      (c) => c.phoneNumber == phoneNumber && c.id != excludeId,
    );
  }

  @override
  Future<List<Customer>> search(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    return _customers
        .where(
          (c) =>
              c.name.contains(query) ||
              (c.phoneNumber?.contains(query) ?? false),
        )
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<Result<List<Customer>>> searchResult(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    return ok(await search(query, limit: limit, offset: offset));
  }

  @override
  Future<void> update(Customer customer, {int? userId}) async {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _customers[index] = customer;
    }
  }

  @override
  Future<Result<void>> updateResult(Customer customer, {int? userId}) async {
    await update(customer, userId: userId);
    return ok(null);
  }

  @override
  Future<Customer> findOrCreateByPhone(
    String phoneNumber,
    String name, {
    int? userId,
  }) async {
    var customer = await getByPhoneNumber(phoneNumber);
    if (customer == null) {
      final customer = Customer(name: name, phoneNumber: phoneNumber);
      final id = await create(customer, userId: userId);
      return customer.copyWith(id: id);
    }
    return customer;
  }
}

class InMemoryInventoryRepository implements repo_inv.InventoryRepository {
  final _items = <InventoryItemRow>[];

  @override
  ProductDao get dao => throw UnimplementedError();

  @override
  Future<Result<void>> addRfidTag({
    required int variantId,
    required String epc,
    int? userId,
  }) async {
    final index = _items.indexWhere((item) => item.variant.id == variantId);
    if (index != -1) {
      final oldVariant = _items[index].variant;
      final newVariant = oldVariant.copyWith(rfidTag: epc);
      _items[index] = InventoryItemRow(
        variant: newVariant,
        parentName: _items[index].parentName,
        brandName: _items[index].brandName,
      );
    }
    return ok(null);
  }

  @override
  Future<Result<void>> adjustInventory({
    required int variantId,
    required int quantityChange,
    required String reason,
    int? userId,
  }) async {
    final index = _items.indexWhere((item) => item.variant.id == variantId);
    if (index != -1) {
      final oldVariant = _items[index].variant;
      final newVariant = oldVariant.copyWith(
        quantity: oldVariant.quantity + quantityChange,
      );
      _items[index] = InventoryItemRow(
        variant: newVariant,
        parentName: _items[index].parentName,
        brandName: _items[index].brandName,
      );
    }
    return ok(null);
  }

  @override
  Future<List<InventoryItemRow>> getInventoryByRfidTag(String epc) async {
    return _items.where((item) => item.variant.rfidTag == epc).toList();
  }

  @override
  Future<InventoryItemRow?> getInventoryItemByVariantId(int variantId) async {
    final matches = _items.where((item) => item.variant.id == variantId);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<List<InventoryMovement>> getInventoryMovements({
    int? variantId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>> getInventorySummary() async {
    return {};
  }

  @override
  Future<List<InventoryItemRow>> getLowStockItems({
    int limit = 50,
    int offset = 0,
  }) async {
    return _items
        .where((item) => item.isLowStock)
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<Result<void>> removeRfidTag({required String epc, int? userId}) async {
    final index = _items.indexWhere((item) => item.variant.rfidTag == epc);
    if (index != -1) {
      final oldVariant = _items[index].variant;
      final newVariant = oldVariant.copyWith(rfidTag: null);
      _items[index] = InventoryItemRow(
        variant: newVariant,
        parentName: _items[index].parentName,
        brandName: _items[index].brandName,
      );
    }
    return ok(null);
  }

  @override
  Future<List<InventoryItemRow>> searchInventoryItems({
    String? name,
    String? sku,
    String? barcode,
    String? rfidTag,
    int? brandId,
    int? categoryId,
    bool? lowStockOnly,
    int limit = 50,
    int offset = 0,
  }) async {
    return _items.skip(offset).take(limit).toList();
  }

  @override
  Future<Result<List<InventoryItemRow>>> searchInventoryItemsResult({
    String? name,
    String? sku,
    String? barcode,
    String? rfidTag,
    int? brandId,
    int? categoryId,
    bool? lowStockOnly,
    int limit = 50,
    int offset = 0,
  }) async {
    return ok(
      await searchInventoryItems(
        name: name,
        sku: sku,
        barcode: barcode,
        rfidTag: rfidTag,
        brandId: brandId,
        categoryId: categoryId,
        lowStockOnly: lowStockOnly,
        limit: limit,
        offset: offset,
      ),
    );
  }
}

class InMemoryProductRepository implements repo_prod.ProductRepository {
  final _products = <ParentProduct>[];
  final _variants = <ProductVariant>[];
  int _productId = 1;
  int _variantId = 1;

  @override
  ProductDao get dao => throw UnimplementedError();

  @override
  repo_attr.AttributeRepository? get attributeRepository =>
      throw UnimplementedError();

  @override
  Future<int> addVariant(ProductVariant v) async {
    final newVariant = v.copyWith(id: _variantId++);
    _variants.add(newVariant);
    return newVariant.id!;
  }

  @override
  Future<int> createParent(ParentProduct p) async {
    final newProduct = p.copyWith(id: _productId++);
    _products.add(newProduct);
    return newProduct.id!;
  }

  @override
  Future<int> createWithVariants(
    ParentProduct p,
    List<ProductVariant> vs, [
    List<Attribute>? parentAttributes,
  ]) async {
    final parentId = await createParent(p);
    for (var v in vs) {
      await addVariant(v.copyWith(parentProductId: parentId));
    }
    return parentId;
  }

  @override
  Future<int> deleteParent(int id) async {
    final initialLength = _products.length;
    _products.removeWhere((p) => p.id == id);
    return initialLength - _products.length;
  }

  @override
  Future<int> deleteVariant(int id) async {
    final initialLength = _variants.length;
    _variants.removeWhere((v) => v.id == id);
    return initialLength - _variants.length;
  }

  @override
  Future<List<String>> distinctBrands({int limit = 100}) async {
    return [];
  }

  @override
  Future<List<String>> distinctColors({int limit = 100}) async {
    return [];
  }

  @override
  Future<List<String>> distinctSizes({int limit = 100}) async {
    return [];
  }

  @override
  Future<ParentProduct?> getParentById(int id) async {
    final matches = _products.where((p) => p.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<Map<String, Object?>> getParentWithAttributes(int id) async {
    return {};
  }

  @override
  Future<List<ProductVariant>> getVariantsByParent(int parentId) async {
    return _variants.where((v) => v.parentProductId == parentId).toList();
  }

  @override
  Future<List<ProductVariant>> lowStock({
    int limit = 50,
    int offset = 0,
  }) async {
    return [];
  }

  @override
  Future<List<ParentProduct>> searchParentsByName(
    String q, {
    int limit = 20,
    int offset = 0,
  }) async {
    return _products
        .where((p) => p.name.contains(q))
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<List<ProductVariant>> searchVariants({
    String? name,
    String? sku,
    String? barcode,
    String? rfidTag,
    int? brandId,
    int? categoryId,
    int limit = 20,
    int offset = 0,
  }) async {
    return _variants.skip(offset).take(limit).toList();
  }

  @override
  Future<int> updateParent(ParentProduct p) async {
    final index = _products.indexWhere((product) => product.id == p.id);
    if (index != -1) {
      _products[index] = p;
      return 1;
    }
    return 0;
  }

  @override
  Future<int> updateVariant(ProductVariant v) async {
    final index = _variants.indexWhere((variant) => variant.id == v.id);
    if (index != -1) {
      _variants[index] = v;
      return 1;
    }
    return 0;
  }

  @override
  Future<void> updateVariantSalePrice({
    required int variantId,
    required double salePrice,
  }) async {
    final index = _variants.indexWhere((variant) => variant.id == variantId);
    if (index != -1) {
      final oldVariant = _variants[index];
      _variants[index] = oldVariant.copyWith(salePrice: salePrice);
    }
  }

  @override
  Future<void> updateWithVariants(
    ParentProduct p,
    List<ProductVariant> vs, [
    List<Attribute>? parentAttributes,
  ]) async {
    await updateParent(p);
    for (var v in vs) {
      await updateVariant(v);
    }
  }

  @override
  Future<List<InventoryItemRow>> searchInventoryRows({
    String? name,
    String? sku,
    String? barcode,
    String? rfidTag,
    int? brandId,
    int? categoryId,
    int limit = 50,
    int offset = 0,
  }) async {
    return [];
  }

  @override
  Future<Result<List<InventoryItemRow>>> searchInventoryRowsResult({
    String? name,
    String? sku,
    String? barcode,
    String? rfidTag,
    int? brandId,
    int? categoryId,
    int limit = 50,
    int offset = 0,
  }) async {
    return ok(
      await searchInventoryRows(
        name: name,
        sku: sku,
        barcode: barcode,
        rfidTag: rfidTag,
        brandId: brandId,
        categoryId: categoryId,
        limit: limit,
        offset: offset,
      ),
    );
  }

  @override
  Future<void> addRfidTag({
    required int variantId,
    required String epc,
  }) async {}

  @override
  Future<void> removeRfidTag({required String epc}) async {}

  @override
  Future<List<Map<String, Object?>>> searchVariantRowMaps({
    String? name,
    String? sku,
    String? barcode,
    String? rfidTag,
    int? brandId,
    int? categoryId,
    int limit = 20,
    int offset = 0,
  }) async {
    return [];
  }

  @override
  Future<String?> getVariantDisplayName(int id) async {
    return null;
  }

  @override
  Future<Map<int, String>> getVariantDisplayNames(List<int> ids) async {
    return {};
  }

  @override
  Future<List<String>> listRfidTags(int variantId) async {
    return [];
  }

  @override
  Future<List<Attribute>> getAllAttributes() async {
    return [Attribute(id: 1, name: 'Color'), Attribute(id: 2, name: 'Size')];
  }

  @override
  Future<List<AttributeValue>> getAttributeValues(int attributeId) async {
    switch (attributeId) {
      case 1:
        return [
          AttributeValue(id: 11, attributeId: 1, value: 'Red'),
          AttributeValue(id: 12, attributeId: 1, value: 'Blue'),
        ];
      case 2:
        return [
          AttributeValue(id: 21, attributeId: 2, value: 'S'),
          AttributeValue(id: 22, attributeId: 2, value: 'M'),
        ];
      default:
        return [];
    }
  }

  @override
  Future<int> createAttribute(Attribute a) async {
    return 0;
  }

  @override
  Future<int> createAttributeValue(AttributeValue v) async {
    return 0;
  }
}

class InMemoryPurchaseRepository implements repo_purchase.PurchaseRepository {
  @override
  PurchaseDao get dao => throw UnimplementedError();

  @override
  Future<int> createInvoice(
    PurchaseInvoice invoice,
    List<PurchaseInvoiceItem> items,
  ) async {
    return 1;
  }

  @override
  Future<Result<int>> createInvoiceResult(
    PurchaseInvoice invoice,
    List<PurchaseInvoiceItem> items,
  ) async {
    return ok(1);
  }

  @override
  Future<int> createInvoiceWithRfids(
    PurchaseInvoice invoice,
    List<PurchaseInvoiceItem> items,
    List<List<String>> rfidsByItem,
  ) async {
    return 1;
  }

  @override
  Future<Result<int>> createInvoiceWithRfidsResult(
    PurchaseInvoice invoice,
    List<PurchaseInvoiceItem> items,
    List<List<String>> rfidsByItem,
  ) async {
    return ok(1);
  }

  @override
  Future<List<PurchaseInvoiceItem>> itemsForInvoice(int invoiceId) async {
    return [];
  }

  @override
  Future<List<PurchaseInvoice>> listInvoices({
    int limit = 50,
    int offset = 0,
  }) async {
    return [];
  }
}

class InMemorySalesRepository implements repo_sales.SalesRepository {
  @override
  SalesDao get dao => throw UnimplementedError();

  @override
  repo_sales.CashSessionProvider? getOpenSession;

  @override
  repo_sales.PermissionChecker? hasPermission;

  @override
  Future<int> createSale({
    required Sale sale,
    required List<SaleItem> items,
    required List<Payment> payments,
  }) async {
    return 1;
  }

  @override
  Future<Result<int>> createSaleResult({
    required Sale sale,
    required List<SaleItem> items,
    required List<Payment> payments,
  }) async {
    return ok(1);
  }

  @override
  Future<Sale> getSale(int saleId) async {
    return Sale(userId: 1, totalAmount: 0, saleDate: DateTime.now());
  }

  @override
  Future<List<SaleItem>> itemsForSale(int saleId) async {
    return [];
  }

  @override
  Future<List<Map<String, Object?>>> listSales({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
  }) async {
    return [];
  }

  @override
  Future<Map<String, Object?>?> getSaleInfo(int saleId) async {
    return {
      'id': saleId,
      'total': 0.0,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<List<Payment>> paymentsForSale(int saleId) async {
    return [];
  }

  @override
  Future<List<Map<String, Object?>>> salesForCustomer(int customerId) async {
    return [];
  }

  @override
  void setGuards({
    repo_sales.PermissionChecker? permission,
    repo_sales.CashSessionProvider? openSession,
  }) {}
}

class InMemoryReturnsRepository implements repo_returns.ReturnsRepository {
  @override
  ReturnsDao get dao => throw UnimplementedError();

  @override
  Future<int> createReturn({
    required int saleId,
    required int userId,
    String? reason,
    required List<ReturnLineInput> items,
  }) async {
    return 1;
  }

  @override
  Future<Result<int>> createReturnResult({
    required int saleId,
    required int userId,
    String? reason,
    required List<ReturnLineInput> items,
  }) async {
    return ok(1);
  }

  @override
  Future<List<Map<String, Object?>>> getReturnableItems(int saleId) async {
    return [];
  }
}

class InMemoryExpenseRepository implements repo_expense.ExpenseRepository {
  @override
  ExpenseDao get dao => throw UnimplementedError();

  @override
  Future<int> createCategory(String name) async {
    return 1;
  }

  @override
  Future<int> createExpense(Expense e, {int? userId}) async {
    return 1;
  }

  @override
  Future<void> deleteExpense(int id, {int? userId}) async {}

  @override
  Future<List<ExpenseCategory>> listCategories({bool onlyActive = true}) async {
    return [];
  }

  @override
  Future<List<Expense>> listExpenses({
    DateTime? start,
    DateTime? end,
    int? categoryId,
    String? paidVia,
    int limit = 500,
    int offset = 0,
  }) async {
    return [];
  }

  @override
  Future<void> renameCategory(int id, String newName) async {}

  @override
  Future<void> setCategoryActive(int id, bool active) async {}

  @override
  Future<Map<String, double>> sumByCategory({
    DateTime? start,
    DateTime? end,
  }) async {
    return {};
  }

  @override
  Future<double> sumExpenses({
    DateTime? start,
    DateTime? end,
    int? categoryId,
  }) async {
    return 0;
  }

  @override
  Future<void> updateExpense(Expense e, {int? userId}) async {}
}

class InMemoryReportsRepository implements repo_reports.ReportsRepository {
  @override
  ReportsDao get dao => throw UnimplementedError();

  @override
  Future<int> customerCount() async {
    return 0;
  }

  @override
  Future<double> expensesTotalByDate({
    required String startIso,
    required String endIso,
  }) async {
    return 0;
  }

  @override
  Future<int> inventoryCount() async {
    return 0;
  }

  @override
  Future<double> profitByDate({
    required String startIso,
    required String endIso,
    int? userId,
  }) async {
    return 0;
  }

  @override
  Future<double> purchasesTotalByDate({
    required String startIso,
    required String endIso,
  }) async {
    return 0;
  }

  @override
  Future<double> returnsTotalByDate({
    required String startIso,
    required String endIso,
    int? userId,
  }) async {
    return 0;
  }

  @override
  Future<List<Map<String, Object?>>> salesByCategory({
    String? startIso,
    String? endIso,
    int? userId,
  }) async {
    return [];
  }

  @override
  Future<List<Map<String, Object?>>> salesByDay({
    String? startIso,
    String? endIso,
    int? userId,
    int? categoryId,
    int? supplierId,
  }) async {
    return [];
  }

  @override
  Future<List<Map<String, Object?>>> salesByMonth({
    String? startIso,
    String? endIso,
    int? userId,
    int? categoryId,
    int? supplierId,
  }) async {
    return [];
  }

  @override
  Future<double> salesTotalByDate({
    required String startIso,
    required String endIso,
    int? userId,
    int? categoryId,
  }) async {
    return 0;
  }

  @override
  Future<List<Map<String, Object?>>> stockStatus({
    int? categoryId,
    bool? lowStockOnly,
    int limit = 100,
    int offset = 0,
  }) async {
    return [];
  }

  @override
  Future<List<Map<String, Object?>>> topProducts({
    int limit = 10,
    String? startIso,
    String? endIso,
    int? userId,
    int? categoryId,
    int? supplierId,
  }) async {
    return [];
  }
}

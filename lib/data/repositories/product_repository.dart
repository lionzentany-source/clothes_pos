import 'package:clothes_pos/data/datasources/product_dao.dart';
import 'package:clothes_pos/data/models/inventory_item_row.dart';
import 'package:clothes_pos/data/models/parent_product.dart';
import 'package:clothes_pos/data/models/product_variant.dart';

class ProductRepository {
  final ProductDao dao;
  ProductRepository(this.dao);

  Future<int> createParent(ParentProduct p) => dao.insertParentProduct(p);
  Future<int> updateParent(ParentProduct p) => dao.updateParentProduct(p);
  Future<int> deleteParent(int id) => dao.deleteParentProduct(id);
  Future<ParentProduct?> getParentById(int id) => dao.getParentById(id);

  Future<List<ParentProduct>> searchParentsByName(
    String q, {
    int limit = 20,
    int offset = 0,
  }) => dao.searchParentsByName(q, limit: limit, offset: offset);

  Future<int> addVariant(ProductVariant v) => dao.insertVariant(v);
  Future<int> updateVariant(ProductVariant v) => dao.updateVariant(v);
  Future<int> deleteVariant(int id) => dao.deleteVariant(id);
  Future<List<ProductVariant>> getVariantsByParent(int parentId) =>
      dao.getVariantsByParent(parentId);
  Future<List<ProductVariant>> searchVariants({
    String? name,
    String? sku,
    String? barcode,
    String? rfidTag,
    int? brandId,
    int? categoryId,
    int limit = 20,
    int offset = 0,
  }) => dao.searchVariants(
    name: name,
    sku: sku,
    barcode: barcode,
    rfidTag: rfidTag,
    limit: limit,
    offset: offset,
  );
  Future<List<ProductVariant>> lowStock({int limit = 50, int offset = 0}) =>
      dao.getLowStockVariants(limit: limit, offset: offset);

  Future<int> createWithVariants(ParentProduct p, List<ProductVariant> vs) =>
      dao.createProductWithVariants(p, vs);
  Future<void> updateWithVariants(ParentProduct p, List<ProductVariant> vs) =>
      dao.updateProductAndVariants(p, vs);

  Future<List<String>> distinctSizes({int limit = 100}) =>
      dao.distinctSizes(limit: limit);
  Future<List<String>> distinctColors({int limit = 100}) =>
      dao.distinctColors(limit: limit);

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
    final rows = await dao.searchVariantRows(
      name: name,
      sku: sku,
      barcode: barcode,
      rfidTag: rfidTag,
      brandId: brandId,
      categoryId: categoryId,
      limit: limit,
      offset: offset,
    );
    return rows
        .map(
          (m) => InventoryItemRow(
            variant: ProductVariant.fromMap(m),
            parentName: (m['parent_name'] as String?) ?? '',
            brandName: m['brand_name'] as String?,
          ),
        )
        .toList();
  }

  // RFID helpers for multi-tag table (delegate to DAO)
  Future<void> addRfidTag({required int variantId, required String epc}) async {
    await dao.addRfidTag(variantId: variantId, epc: epc);
  }

  Future<void> removeRfidTag({required String epc}) async {
    await dao.removeRfidTag(epc: epc);
  }

  Future<List<Map<String, Object?>>> searchVariantRowMaps({
    String? name,
    String? sku,
    String? barcode,
    String? rfidTag,
    int? brandId,
    int? categoryId,
    int limit = 20,
    int offset = 0,
  }) => dao.searchVariantRows(
    name: name,
    sku: sku,
    barcode: barcode,
    rfidTag: rfidTag,
    brandId: brandId,
    categoryId: categoryId,
    limit: limit,
    offset: offset,
  );

  Future<List<String>> listRfidTags(int variantId) async {
    return dao.listRfidTags(variantId);
  }
}

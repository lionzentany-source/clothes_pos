import 'package:clothes_pos/data/datasources/product_dao.dart';
import 'package:clothes_pos/data/models/inventory_item_row.dart';
import 'package:clothes_pos/data/models/parent_product.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:clothes_pos/core/cache/ttl_cache.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';
import 'package:clothes_pos/core/result/result.dart';

class ProductRepository {
  final ProductDao dao;
  final _sizesCache = TtlCache<String, List<String>>(
    ttl: const Duration(minutes: 10),
  );
  final _colorsCache = TtlCache<String, List<String>>(
    ttl: const Duration(minutes: 10),
  );
  final _brandsCache = TtlCache<String, List<String>>(
    ttl: const Duration(minutes: 10),
  );
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

  Future<List<String>> distinctSizes({int limit = 100}) async {
    final k = 'sizes:$limit';
    final cached = _sizesCache.get(k);
    if (cached != null) return cached;
    final sizes = await dao.distinctSizes(limit: limit);
    _sizesCache.set(k, sizes);
    AppLogger.d('Cache miss sizes (limit=$limit) -> ${sizes.length}');
    return sizes;
  }

  Future<List<String>> distinctColors({int limit = 100}) async {
    final k = 'colors:$limit';
    final cached = _colorsCache.get(k);
    if (cached != null) return cached;
    final colors = await dao.distinctColors(limit: limit);
    _colorsCache.set(k, colors);
    AppLogger.d('Cache miss colors (limit=$limit) -> ${colors.length}');
    return colors;
  }

  Future<List<String>> distinctBrands({int limit = 100}) async {
    final k = 'brands:$limit';
    final cached = _brandsCache.get(k);
    if (cached != null) return cached;
    final brands = await dao.distinctBrands(limit: limit);
    _brandsCache.set(k, brands);
    AppLogger.d('Cache miss brands (limit=$limit) -> ${brands.length}');
    return brands;
  }

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

  // Incremental Result-based variant for safer error propagation.
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
    try {
      final rows = await searchInventoryRows(
        name: name,
        sku: sku,
        barcode: barcode,
        rfidTag: rfidTag,
        brandId: brandId,
        categoryId: categoryId,
        limit: limit,
        offset: offset,
      );
      return ok(rows);
    } catch (e, st) {
      AppLogger.e('searchInventoryRowsResult failed', error: e, stackTrace: st);
      return fail(
        'تعذر تحميل المخزون',
        code: 'inventory_search',
        exception: e,
        stackTrace: st,
        retryable: true,
      );
    }
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

  Future<String?> getVariantDisplayName(int id) async {
    final row = await dao.getVariantRowById(id);
    if (row == null) return null;
    return (row['parent_name'] as String?) ??
        (row['name'] as String?) ??
        (row['sku'] as String?) ??
        'Item $id';
  }

  Future<List<String>> listRfidTags(int variantId) async {
    return dao.listRfidTags(variantId);
  }
}

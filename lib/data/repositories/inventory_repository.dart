import 'package:clothes_pos/data/datasources/product_dao.dart';
import 'package:clothes_pos/data/models/inventory_item_row.dart';
import 'package:clothes_pos/data/models/inventory_movement.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:clothes_pos/core/result/result.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/audit_repository.dart';

/// Repository for managing inventory operations
class InventoryRepository {
  final ProductDao dao;

  InventoryRepository(this.dao);

  /// Search inventory items with various filters
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
    try {
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

      var inventoryRows = rows
          .map(
            (m) => InventoryItemRow(
              variant: ProductVariant.fromMap(m),
              parentName: (m['parent_name'] as String?) ?? '',
              brandName: m['brand_name'] as String?,
            ),
          )
          .toList();

      // Filter for low stock if requested
      if (lowStockOnly == true) {
        inventoryRows = inventoryRows.where((row) => row.isLowStock).toList();
      }

      return inventoryRows;
    } catch (e, st) {
      AppLogger.e('searchInventoryItems failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Search inventory items with Result wrapper for safer error handling
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
    try {
      final items = await searchInventoryItems(
        name: name,
        sku: sku,
        barcode: barcode,
        rfidTag: rfidTag,
        brandId: brandId,
        categoryId: categoryId,
        lowStockOnly: lowStockOnly,
        limit: limit,
        offset: offset,
      );
      return ok(items);
    } catch (e, st) {
      AppLogger.e(
        'searchInventoryItemsResult failed',
        error: e,
        stackTrace: st,
      );
      return fail(
        'تعذر تحميل المخزون',
        code: 'inventory_search',
        exception: e,
        stackTrace: st,
        retryable: true,
      );
    }
  }

  /// Get low stock items
  Future<List<InventoryItemRow>> getLowStockItems({
    int limit = 50,
    int offset = 0,
  }) async {
    return searchInventoryItems(
      lowStockOnly: true,
      limit: limit,
      offset: offset,
    );
  }

  /// Get inventory item by variant ID
  Future<InventoryItemRow?> getInventoryItemByVariantId(int variantId) async {
    try {
      // Get the base row for display context (parent/brand names)
      final row = await dao.getVariantRowById(variantId);
      if (row == null) return null;
      // Get variant with attributes populated
      final v = await dao.getVariantWithAttributesById(variantId);
      final variant = v ?? ProductVariant.fromMap(row);
      return InventoryItemRow(
        variant: variant,
        parentName: (row['parent_name'] as String?) ?? '',
        brandName: row['brand_name'] as String?,
      );
    } catch (e, st) {
      AppLogger.e(
        'getInventoryItemByVariantId failed',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Get inventory summary statistics
  Future<Map<String, dynamic>> getInventorySummary() async {
    try {
      final allItems = await searchInventoryItems(limit: 10000);

      final totalItems = allItems.length;
      final totalValue = allItems.fold<double>(
        0.0,
        (sum, item) => sum + (item.variant.quantity * item.variant.costPrice),
      );
      final lowStockCount = allItems.where((item) => item.isLowStock).length;
      final outOfStockCount = allItems
          .where((item) => item.variant.quantity <= 0)
          .length;

      return {
        'totalItems': totalItems,
        'totalValue': totalValue,
        'lowStockCount': lowStockCount,
        'outOfStockCount': outOfStockCount,
        'averageValue': totalItems > 0 ? totalValue / totalItems : 0.0,
      };
    } catch (e, st) {
      AppLogger.e('getInventorySummary failed', error: e, stackTrace: st);
      return {
        'totalItems': 0,
        'totalValue': 0.0,
        'lowStockCount': 0,
        'outOfStockCount': 0,
        'averageValue': 0.0,
      };
    }
  }

  /// Adjust inventory quantity for a variant
  Future<Result<void>> adjustInventory({
    required int variantId,
    required int quantityChange,
    required String reason,
    int? userId,
  }) async {
    try {
      // This would typically involve creating an inventory movement
      // and updating the variant quantity
      // For now, we'll just log the audit trail

      await sl<AuditRepository>().logChange(
        userId: userId,
        entity: 'inventory:$variantId',
        field: 'quantity_adjustment',
        newValue: quantityChange.toString(),
        oldValue: reason, // Using oldValue to store the reason
      );

      return ok(null);
    } catch (e, st) {
      AppLogger.e('adjustInventory failed', error: e, stackTrace: st);
      return fail(
        'فشل في تعديل المخزون',
        code: 'inventory_adjust',
        exception: e,
        stackTrace: st,
        retryable: true,
      );
    }
  }

  /// Get inventory movements for a variant
  Future<List<InventoryMovement>> getInventoryMovements({
    int? variantId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      // This would query the inventory_movements table
      // For now, return empty list as the actual implementation
      // would depend on having an InventoryMovementDao
      return [];
    } catch (e, st) {
      AppLogger.e('getInventoryMovements failed', error: e, stackTrace: st);
      return [];
    }
  }

  /// Add RFID tag to a variant
  Future<Result<void>> addRfidTag({
    required int variantId,
    required String epc,
    int? userId,
  }) async {
    try {
      await dao.addRfidTag(variantId: variantId, epc: epc);

      await sl<AuditRepository>().logChange(
        userId: userId,
        entity: 'inventory:$variantId',
        field: 'rfid_tag_added',
        newValue: epc,
      );

      return ok(null);
    } catch (e, st) {
      AppLogger.e('addRfidTag failed', error: e, stackTrace: st);
      return fail(
        'فشل في إضافة علامة RFID',
        code: 'rfid_add',
        exception: e,
        stackTrace: st,
        retryable: true,
      );
    }
  }

  /// Remove RFID tag
  Future<Result<void>> removeRfidTag({required String epc, int? userId}) async {
    try {
      await dao.removeRfidTag(epc: epc);

      await sl<AuditRepository>().logChange(
        userId: userId,
        entity: 'rfid_tag',
        field: 'removed',
        newValue: epc,
      );

      return ok(null);
    } catch (e, st) {
      AppLogger.e('removeRfidTag failed', error: e, stackTrace: st);
      return fail(
        'فشل في إزالة علامة RFID',
        code: 'rfid_remove',
        exception: e,
        stackTrace: st,
        retryable: true,
      );
    }
  }

  /// Get inventory items by RFID tag
  Future<List<InventoryItemRow>> getInventoryByRfidTag(String epc) async {
    return searchInventoryItems(rfidTag: epc, limit: 10);
  }
}

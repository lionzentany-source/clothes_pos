import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/datasources/product_dao.dart';
import 'package:clothes_pos/data/models/parent_product.dart';
import 'package:clothes_pos/data/models/product_variant.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper helper;
  late ProductDao productDao;

  setUp(() async {
    await Directory.systemTemp.createTemp('pos_test_');
    // Ensure fresh DB each test by resetting
    helper = DatabaseHelper.instance;
    await helper.resetForTests();
    // Force opening
    await helper.database;
    productDao = ProductDao(helper);
  });

  test('insert parent and variant then fetch', () async {
    final parent = ParentProduct(
      name: 'Test Shirt',
      description: 'Desc',
      categoryId: 1,
    );
    final parentId = await productDao.insertParentProduct(parent);
    expect(parentId, greaterThan(0));

    final variant = ProductVariant(
      parentProductId: parentId,
      sku: 'SKU123',
      barcode: 'BAR123',
      size: 'M',
      color: 'Red',
      quantity: 5,
      costPrice: 5.0,
      salePrice: 10.0,
      reorderPoint: 2,
    );
    final variantId = await productDao.insertVariant(variant);
    expect(variantId, greaterThan(0));

    final fetchedParent = await productDao.getParentById(parentId);
    expect(fetchedParent?.name, equals('Test Shirt'));

    final variants = await productDao.getVariantsByParent(parentId);
    expect(variants.length, 1);
    expect(variants.first.size, 'M');
  });
}

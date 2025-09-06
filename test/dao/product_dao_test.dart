import 'package:clothes_pos/core/config/feature_flags.dart';
import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/data/datasources/product_dao.dart';
import 'package:clothes_pos/data/models/attribute.dart';
import 'package:clothes_pos/data/models/parent_product.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../mocks.mocks.dart';

void main() {
  // Ensure Flutter bindings are initialized before any code that uses
  // asset bundles or platform channels (DatabaseHelper reads assets).
  TestWidgetsFlutterBinding.ensureInitialized();
  late DatabaseHelper dbHelper;
  late ProductDao productDao;
  late MockAttributeDao mockAttributeDao;
  late int testAttributeId;
  late int testAttributeValueRedId;
  late int testAttributeValueBlueId;

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dbHelper = DatabaseHelper.instance;
    await dbHelper.resetForTests();
    mockAttributeDao = MockAttributeDao();
    productDao = ProductDao(dbHelper, mockAttributeDao);
    // Create a real attribute and two values so variant_attributes FK is satisfied
    final db = await dbHelper.database;
    await db.rawInsert('INSERT OR IGNORE INTO attributes(name) VALUES(?)', [
      'Color',
    ]);
    final existingAttr = await db.query(
      'attributes',
      where: 'name = ?',
      whereArgs: ['Color'],
      limit: 1,
    );
    testAttributeId = existingAttr.first['id'] as int;
    await db.rawInsert(
      'INSERT OR IGNORE INTO attribute_values(attribute_id, value) VALUES(?, ?)',
      [testAttributeId, 'Red'],
    );
    await db.rawInsert(
      'INSERT OR IGNORE INTO attribute_values(attribute_id, value) VALUES(?, ?)',
      [testAttributeId, 'Blue'],
    );
    final redRow = await db.query(
      'attribute_values',
      where: 'attribute_id = ? AND value = ?',
      whereArgs: [testAttributeId, 'Red'],
      limit: 1,
    );
    final blueRow = await db.query(
      'attribute_values',
      where: 'attribute_id = ? AND value = ?',
      whereArgs: [testAttributeId, 'Blue'],
      limit: 1,
    );
    testAttributeValueRedId = redRow.first['id'] as int;
    testAttributeValueBlueId = blueRow.first['id'] as int;
    // Default mock behavior: return empty attribute list unless a test overrides it
    when(
      mockAttributeDao.getAttributeValuesForVariant(any),
    ).thenAnswer((_) async => <AttributeValue>[]);
  });

  tearDown(() async {
    await dbHelper.resetForTests();
  });

  group('ProductDao', () {
    test('createProductWithVariants with dynamic attributes', () async {
      // Arrange
      FeatureFlags.useDynamicAttributes = true;
      final uniq = DateTime.now().microsecondsSinceEpoch;
      final parent = ParentProduct(name: 'Test Product $uniq', categoryId: 1);
      final variants = [
        ProductVariant(
          parentProductId: 1,
          costPrice: 10.0,
          salePrice: 20.0,
          attributes: [
            AttributeValue(
              id: testAttributeValueRedId,
              attributeId: testAttributeId,
              value: 'Red',
            ),
          ],
        ),
      ];

      // Act
      final parentId = await productDao.createProductWithVariants(
        parent,
        variants,
      );

      // Assert
      final createdParent = await productDao.getParentById(parentId);
      expect(createdParent, isNotNull);
      // name may include a uniqueness suffix in tests; assert prefix instead
      expect(createdParent!.name.startsWith('Test Product'), isTrue);

      final createdVariants = await productDao.getVariantsByParent(parentId);
      expect(createdVariants, hasLength(1));
      // verify that the attribute was saved
      // This will be tested in the getVariantsByParent test
    });

    test('updateProductAndVariants with dynamic attributes', () async {
      // Arrange
      FeatureFlags.useDynamicAttributes = true;
      final uniq = DateTime.now().microsecondsSinceEpoch;
      final parent = ParentProduct(name: 'Test Product $uniq', categoryId: 1);
      final initialVariants = [
        ProductVariant(
          parentProductId: 1,
          costPrice: 10.0,
          salePrice: 20.0,
          attributes: [
            AttributeValue(
              id: testAttributeValueRedId,
              attributeId: testAttributeId,
              value: 'Red',
            ),
          ],
        ),
      ];
      final parentId = await productDao.createProductWithVariants(
        parent,
        initialVariants,
      );
      // Determine the actual variant id assigned by the DB
      final existingVariants = await productDao.getVariantsByParent(parentId);
      final existingVariantId = existingVariants.first.id!;

      final updatedParent = parent.copyWith(
        id: parentId,
        name: 'Updated Product',
      );
      final updatedVariants = [
        ProductVariant(
          id: existingVariantId,
          parentProductId: parentId,
          costPrice: 15.0,
          salePrice: 25.0,
          attributes: [
            AttributeValue(
              id: testAttributeValueBlueId,
              attributeId: testAttributeId,
              value: 'Blue',
            ),
          ],
        ),
      ];

      // Act
      await productDao.updateProductAndVariants(updatedParent, updatedVariants);

      // Assert
      final fetchedParent = await productDao.getParentById(parentId);
      expect(fetchedParent, isNotNull);
      expect(fetchedParent!.name, 'Updated Product');

      final fetchedVariants = await productDao.getVariantsByParent(parentId);
      expect(fetchedVariants, hasLength(1));
      expect(fetchedVariants.first.salePrice, 25.0);
    });

    test('getVariantsByParent with dynamic attributes', () async {
      // Arrange
      FeatureFlags.useDynamicAttributes = true;
      final uniq = DateTime.now().microsecondsSinceEpoch;
      final parent = ParentProduct(name: 'Test Product $uniq', categoryId: 1);
      final variants = [
        ProductVariant(
          parentProductId: 1,
          costPrice: 10.0,
          salePrice: 20.0,
          attributes: [
            AttributeValue(
              id: testAttributeValueRedId,
              attributeId: testAttributeId,
              value: 'Red',
            ),
          ],
        ),
      ];
      final parentId = await productDao.createProductWithVariants(
        parent,
        variants,
      );
      // Variant IDs are not deterministic between tests; respond to any id.
      when(mockAttributeDao.getAttributeValuesForVariant(any)).thenAnswer(
        (_) async => [AttributeValue(id: 1, attributeId: 1, value: 'Red')],
      );

      // Act
      final fetchedVariants = await productDao.getVariantsByParent(parentId);

      // Assert
      expect(fetchedVariants, hasLength(1));
      expect(fetchedVariants.first.attributes, isNotNull);
      expect(fetchedVariants.first.attributes!, hasLength(1));
      expect(fetchedVariants.first.attributes!.first.value, 'Red');
    });

    test('searchVariantRows with dynamic attributes', () async {
      // Arrange
      FeatureFlags.useDynamicAttributes = true;
      final uniq = DateTime.now().microsecondsSinceEpoch;
      final parent = ParentProduct(name: 'Test Product $uniq', categoryId: 1);
      final variants = [
        ProductVariant(
          parentProductId: 1,
          costPrice: 10.0,
          salePrice: 20.0,
          attributes: [AttributeValue(id: 1, attributeId: 1, value: 'Red')],
        ),
      ];
      await productDao.createProductWithVariants(parent, variants);

      // Act
      // Search by the unique parent name to avoid matching other tests' rows.
      final rows = await productDao.searchVariantRows(name: parent.name);

      // Assert
      expect(rows, hasLength(1));
    });
  });
}

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'attribute_dao.dart';

class AttributeRepository {
  final AttributeDao dao;

  AttributeRepository(this.dao);

  Future<int> ensureAttributeByName(Database db, String name) async {
    return dao.ensureAttribute(db, name);
  }

  Future<int> addValueForAttribute(
    Database db,
    String attributeName,
    String value,
  ) async {
    final id = await dao.ensureAttribute(db, attributeName);
    return dao.ensureAttributeValue(db, id, value);
  }

  Future<void> link(
    Database db,
    int variantId,
    String attributeName,
    String value,
  ) async {
    final attrId = await dao.ensureAttribute(db, attributeName);
    final valId = await dao.ensureAttributeValue(db, attrId, value);
    await dao.linkVariantAttribute(db, variantId, valId);
  }
}

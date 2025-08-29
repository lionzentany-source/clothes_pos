import 'package:clothes_pos/data/datasources/attribute_dao.dart';
import 'package:clothes_pos/data/models/attribute.dart';

class AttributeRepository {
  final AttributeDao _attributeDao;

  AttributeRepository(this._attributeDao);

  Future<List<Attribute>> getAllAttributes() => _attributeDao.getAllAttributes();

  Future<Attribute> getAttributeById(int id) => _attributeDao.getAttributeById(id);

  Future<int> createAttribute(Attribute attribute) => _attributeDao.createAttribute(attribute);

  Future<int> updateAttribute(Attribute attribute) => _attributeDao.updateAttribute(attribute);

  Future<int> deleteAttribute(int id) => _attributeDao.deleteAttribute(id);

  Future<List<AttributeValue>> getAttributeValues(int attributeId) => _attributeDao.getAttributeValues(attributeId);

  Future<int> createAttributeValue(AttributeValue value) => _attributeDao.createAttributeValue(value);

  Future<int> updateAttributeValue(AttributeValue value) => _attributeDao.updateAttributeValue(value);

  Future<int> deleteAttributeValue(int id) => _attributeDao.deleteAttributeValue(id);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/presentation/attributes/bloc/attributes_cubit.dart';
import 'package:clothes_pos/data/repositories/attribute_repository.dart';
import 'package:clothes_pos/data/datasources/attribute_dao.dart';
import 'package:clothes_pos/data/models/attribute.dart';

class FakeAttributeDao implements AttributeDao {
  final List<Attribute> _attrs = [];
  final Map<int, List<AttributeValue>> _values = {};
  int _nextAttrId = 1;

  @override
  Future<int> createAttribute(Attribute attribute) async {
    final a = Attribute(id: _nextAttrId++, name: attribute.name);
    _attrs.add(a);
    return a.id!;
  }

  @override
  Future<int> createAttributeValue(AttributeValue value) async {
    throw UnimplementedError();
  }

  @override
  Future<int> deleteAttribute(int id) async {
    _attrs.removeWhere((a) => a.id == id);
    return 1;
  }

  @override
  Future<int> deleteAttributeValue(int id) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Attribute>> getAllAttributes() async => List.of(_attrs);

  @override
  Future<Attribute> getAttributeById(int id) async =>
      _attrs.firstWhere((a) => a.id == id);

  @override
  Future<List<AttributeValue>> getAttributeValues(int attributeId) async =>
      List.of(_values[attributeId] ?? []);

  @override
  Future<int> updateAttribute(Attribute attribute) async {
    final idx = _attrs.indexWhere((a) => a.id == attribute.id);
    if (idx >= 0) _attrs[idx] = attribute;
    return 1;
  }

  @override
  Future<int> updateAttributeValue(AttributeValue value) async {
    throw UnimplementedError();
  }

  @override
  Future<List<AttributeValue>> getAttributeValuesForVariant(
    int variantId,
  ) async => [];

  @override
  Future<Map<int, List<AttributeValue>>> getAttributeValuesForVariantIds(
    List<int> variantIds,
  ) async {
    return <int, List<AttributeValue>>{};
  }
}

void main() {
  group('AttributesCubit', () {
    late FakeAttributeDao fakeDao;
    late AttributeRepository repo;
    late AttributesCubit cubit;

    setUp(() {
      fakeDao = FakeAttributeDao();
      repo = AttributeRepository(fakeDao);
      cubit = AttributesCubit(repo);
    });

    tearDown(() {
      cubit.close();
    });

    test('loadAttributes emits loading then loaded', () async {
      final states = <dynamic>[];
      cubit.stream.listen(states.add);

      await cubit.loadAttributes();
      // allow events
      await Future.delayed(Duration.zero);

      expect(states.first, isA<AttributesLoading>());
      expect(states.last, isA<AttributesLoaded>());
    });

    test('addAttribute reloads attributes', () async {
      final states = <dynamic>[];
      cubit.stream.listen(states.add);

      await cubit.addAttribute(Attribute(name: 'Size'));
      await Future.delayed(Duration.zero);

      // final state should be AttributesLoaded with one attribute
      expect(states.last, isA<AttributesLoaded>());
      final loaded = states.last as AttributesLoaded;
      expect(loaded.attributes.length, 1);
      expect(loaded.attributes.first.name, 'Size');
    });

    test('updateAttribute updates and reloads', () async {
      // seed
      final id = await fakeDao.createAttribute(Attribute(name: 'Color'));

      final states = <dynamic>[];
      cubit.stream.listen(states.add);

      await cubit.updateAttribute(Attribute(id: id, name: 'Shade'));
      await Future.delayed(Duration.zero);

      expect(states.last, isA<AttributesLoaded>());
      final loaded = states.last as AttributesLoaded;
      expect(loaded.attributes.any((a) => a.name == 'Shade'), true);
    });

    test('deleteAttribute removes and reloads', () async {
      final id = await fakeDao.createAttribute(Attribute(name: 'Temp'));

      final states = <dynamic>[];
      cubit.stream.listen(states.add);

      await cubit.deleteAttribute(id);
      await Future.delayed(Duration.zero);

      expect(states.last, isA<AttributesLoaded>());
      final loaded = states.last as AttributesLoaded;
      expect(loaded.attributes.any((a) => a.id == id), false);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/attributes/screens/manage_attributes_screen.dart';
import 'package:clothes_pos/presentation/attributes/bloc/attributes_cubit.dart';
import 'package:clothes_pos/data/repositories/attribute_repository.dart';
import 'package:clothes_pos/data/datasources/attribute_dao.dart';
import 'package:clothes_pos/data/models/attribute.dart';

class FakeAttributeDao implements AttributeDao {
  final List<Attribute> _attrs = [];
  final Map<int, List<AttributeValue>> _values = {};
  int _nextAttrId = 1;
  int _nextValueId = 100;

  @override
  Future<int> createAttribute(Attribute attribute) async {
    final a = Attribute(id: _nextAttrId++, name: attribute.name);
    _attrs.add(a);
    return a.id!;
  }

  @override
  Future<int> createAttributeValue(AttributeValue value) async {
    final v = AttributeValue(id: _nextValueId++, attributeId: value.attributeId, value: value.value);
    _values.putIfAbsent(value.attributeId, () => []).add(v);
    return v.id!;
  }

  @override
  Future<int> deleteAttribute(int id) async {
    _attrs.removeWhere((a) => a.id == id);
    _values.remove(id);
    return 1;
  }

  @override
  Future<int> deleteAttributeValue(int id) async {
    for (final list in _values.values) {
      final idx = list.indexWhere((v) => v.id == id);
      if (idx >= 0) {
        list.removeAt(idx);
        return 1;
      }
    }
    return 0;
  }

  @override
  Future<List<Attribute>> getAllAttributes() async => List.of(_attrs);

  @override
  Future<Attribute> getAttributeById(int id) async => _attrs.firstWhere((a) => a.id == id);

  @override
  Future<List<AttributeValue>> getAttributeValues(int attributeId) async => List.of(_values[attributeId] ?? []);

  @override
  Future<int> updateAttribute(Attribute attribute) async {
    final idx = _attrs.indexWhere((a) => a.id == attribute.id);
    if (idx >= 0) _attrs[idx] = attribute;
    return 1;
  }

  @override
  Future<int> updateAttributeValue(AttributeValue value) async {
    final list = _values[value.attributeId];
    if (list == null) return 0;
    final idx = list.indexWhere((v) => v.id == value.id);
    if (idx >= 0) list[idx] = value;
    return 1;
  }

  @override
  Future<List<AttributeValue>> getAttributeValuesForVariant(int variantId) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Add attribute rejects empty name', (tester) async {
    final fakeDao = FakeAttributeDao();
    final repo = AttributeRepository(fakeDao);
    final cubit = AttributesCubit(repo);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const ManageAttributesScreen(),
        ),
      ),
    );

    await cubit.loadAttributes();
    await tester.pumpAndSettle();

    // Open add dialog
    await tester.tap(find.byIcon(CupertinoIcons.add).first);
    await tester.pumpAndSettle();

  // Tap Add within the add-dialog
  final addDialog = find.byType(CupertinoAlertDialog).first;
  final addAction = find.descendant(of: addDialog, matching: find.text('Add'));
  await tester.tap(addAction);
    await tester.pumpAndSettle();

    // Expect validation error dialog
    expect(find.text('Name is required.'), findsOneWidget);

    // Dismiss
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets('Add attribute rejects duplicate name (case-insensitive)', (tester) async {
    final fakeDao = FakeAttributeDao();
    final repo = AttributeRepository(fakeDao);
    final cubit = AttributesCubit(repo);

    // Pre-seed one attribute
    await fakeDao.createAttribute(Attribute(name: 'Color'));

    // Ensure cubit has loaded attributes before rendering the UI
    await cubit.loadAttributes();

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const ManageAttributesScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

  // Open add dialog
  await tester.tap(find.byIcon(CupertinoIcons.add).first);
  await tester.pumpAndSettle();

  // Ensure the dialog's text field is present
  expect(find.byType(CupertinoTextField), findsOneWidget);

  // Enter duplicate name with different case
  await tester.enterText(find.byType(CupertinoTextField), 'color');
  final addDialog2 = find.byType(CupertinoAlertDialog).first;
  final addAction2 = find.descendant(of: addDialog2, matching: find.text('Add'));
  await tester.tap(addAction2);
  await tester.pumpAndSettle();

  // Ensure repository did not add a duplicate (robust assertion)
  final attrs = await fakeDao.getAllAttributes();
  expect(attrs.length, 1);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/attributes/screens/manage_attributes_screen.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';
import 'package:clothes_pos/presentation/attributes/bloc/attributes_cubit.dart';
import 'package:clothes_pos/data/repositories/attribute_repository.dart';
import 'package:clothes_pos/data/datasources/attribute_dao.dart';
import 'package:clothes_pos/data/models/attribute.dart';

/// In-memory fake DAO for tests.
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
    final v = AttributeValue(
      id: _nextValueId++,
      attributeId: value.attributeId,
      value: value.value,
    );
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
    final list = _values[value.attributeId];
    if (list == null) return 0;
    final idx = list.indexWhere((v) => v.id == value.id);
    if (idx >= 0) list[idx] = value;
    return 1;
  }

  // Unused in test but required by interface
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
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ManageAttributesScreen CRUD flows', (tester) async {
    final fakeDao = FakeAttributeDao();
    final repo = AttributeRepository(fakeDao);
    final cubit = AttributesCubit(repo);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit,
          child: const ManageAttributesScreen(),
        ),
      ),
    );

    // Load initial attributes (empty)
    await cubit.loadAttributes();
    await tester.pumpAndSettle();

    // Open add attribute dialog
    await tester.tap(find.byIcon(CupertinoIcons.add).first);
    await tester.pumpAndSettle();

    // Enter attribute name and add
    await tester.enterText(find.byType(CupertinoTextField), 'Material');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    // dismiss success
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Material'), findsOneWidget);

    // Edit attribute
    await tester.tap(
      find.widgetWithIcon(CupertinoButton, CupertinoIcons.pencil).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoTextField), 'Fabric');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    // dismiss success
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Fabric'), findsOneWidget);

    // Add attribute value
    final addValueBtn = find
        .widgetWithIcon(CupertinoButton, CupertinoIcons.add)
        .at(1);
    await tester.tap(addValueBtn);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoTextField), 'Cotton');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    // dismiss success
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Cotton'), findsOneWidget);

    // Edit attribute value
    await tester.tap(
      find.widgetWithIcon(CupertinoButton, CupertinoIcons.pencil).at(1),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoTextField), 'Organic Cotton');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    // dismiss success
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Organic Cotton'), findsOneWidget);

    // Delete attribute value (confirm + dismiss)
    await tester.tap(
      find.widgetWithIcon(CupertinoButton, CupertinoIcons.delete).at(1),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Organic Cotton'), findsNothing);

    // Delete attribute (confirm + dismiss)
    await tester.tap(
      find.widgetWithIcon(CupertinoButton, CupertinoIcons.delete).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Fabric'), findsNothing);
  });
}

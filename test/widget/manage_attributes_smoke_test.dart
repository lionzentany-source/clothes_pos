import 'package:flutter_test/flutter_test.dart';
import 'package:clothes_pos/core/config/feature_flags.dart';
import 'package:clothes_pos/presentation/attributes/screens/manage_attributes_screen.dart';
import 'package:clothes_pos/presentation/attributes/bloc/attributes_cubit.dart';
import 'package:clothes_pos/data/models/attribute.dart';
import 'package:clothes_pos/data/repositories/attribute_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';

/// A tiny fake repository to avoid touching the database in the smoke test.
class _FakeAttributeRepository implements AttributeRepository {
  final List<Attribute> _attrs;

  _FakeAttributeRepository([this._attrs = const []]);

  @override
  Future<int> createAttribute(Attribute attribute) async => 1;

  @override
  Future<int> deleteAttribute(int id) async => 1;

  @override
  Future<int> deleteAttributeValue(int id) async => 1;

  @override
  Future<List<Attribute>> getAllAttributes() async => _attrs;

  @override
  Future<Attribute> getAttributeById(int id) async =>
      _attrs.firstWhere((a) => a.id == id);

  @override
  Future<List<AttributeValue>> getAttributeValues(int attributeId) async => [];

  @override
  Future<int> updateAttribute(Attribute attribute) async => 1;

  @override
  Future<int> updateAttributeValue(AttributeValue value) async => 1;

  @override
  Future<int> createAttributeValue(AttributeValue value) async => 1;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ManageAttributesScreen renders when feature enabled', (
    tester,
  ) async {
    FeatureFlags.useDynamicAttributes = true;

    // Provide a fake repo with a single attribute so UI has something to show.
    final fakeRepo = _FakeAttributeRepository([Attribute(id: 1, name: 'Size')]);

    final cubit = AttributesCubit(fakeRepo);

    await tester.pumpWidget(
      CupertinoApp(
        // Provide localization delegates used by the app so widgets that call
        // AppLocalizations.of(context) do not throw in tests.
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<AttributesCubit>(
          create: (_) => cubit,
          child: const ManageAttributesScreen(),
        ),
      ),
    );

    // Allow a couple frames for the widget tree to build
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    // Verify the screen title exists
    expect(find.text('Manage Attributes'), findsOneWidget);
  });
}

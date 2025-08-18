import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/common/money.dart';
import 'package:clothes_pos/presentation/settings/bloc/settings_cubit.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';
import 'package:clothes_pos/data/datasources/settings_dao.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('money() renders formatted text', (tester) async {
    final widget = BlocProvider<SettingsCubit>(
      create: (_) => SettingsCubit(FakeSettingsRepo())..emit(const SettingsState(currency: 'LYD')),
      child: const Directionality(
        textDirection: TextDirection.rtl,
        child: CupertinoApp(
          home: CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(),
            child: Center(child: Text('stub')),
          ),
        ),
      ),
    );

    await tester.pumpWidget(widget);

    // Just verify that money() does not throw for a simple case
    final s = money(tester.element(find.byType(Center)), 123.45);
    expect(s, isNotEmpty);
  });
}

class FakeSettingsRepo extends SettingsRepository {
  FakeSettingsRepo() : super(_FakeDao());
  @override
  Future<String?> get(String key) async => 'LYD';
  @override
  Future<void> set(String key, String? value) async {}
}

class _FakeDao implements SettingsDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


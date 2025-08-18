import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:clothes_pos/main.dart' as app;
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/data/models/user.dart';
import 'package:clothes_pos/presentation/settings/screens/settings_home_screen.dart';
import 'package:clothes_pos/presentation/auth/screens/admin_first_password_screen.dart';
import 'package:clothes_pos/presentation/app_root.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('open users management and see admin entry', (tester) async {
    await app.main();
    // Activate bypass after main (static flag) then pump to allow rebuild
    AppRoot.loginBypass = true;
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // If first password screen shows up, bypass by injecting user directly
    final adminFirst = find.byType(AdminFirstPasswordScreen);
    if (tester.any(adminFirst)) {
      final blocFinder = find.byType(BlocBuilder<AuthCubit, AuthState>);
      final element = tester.element(blocFinder.first);
      element.read<AuthCubit>().testBypassSetAdminPassword(
        const AppUser(
          id: 1,
          username: 'admin',
          fullName: 'Administrator',
          isActive: true,
          permissions: ['manage_users'],
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    // Try to locate settings tab via known Arabic/English labels or gear icon.
    Finder? settingsTab;
    final settingsAr = find.text('الإعدادات');
    final settingsEn = find.text('Settings');
    if (tester.any(settingsAr)) {
      settingsTab = settingsAr.first;
    } else if (tester.any(settingsEn)) {
      settingsTab = settingsEn.first;
    } else {
      final gearIcon = find.byIcon(CupertinoIcons.gear);
      if (tester.any(gearIcon)) settingsTab = gearIcon.first;
    }

    // Fallback: tap the last tab bar item (common for settings) if TabBar present
    if (settingsTab == null) {
      final tabBars = find.byType(CupertinoTabBar);
      if (tester.any(tabBars)) {
        // assume last item area
        await tester.tapAt(
          tester.getBottomRight(tabBars.first) - const Offset(8, 8),
        );
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
    } else {
      await tester.tap(settingsTab);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    // Assert settings screen loaded
    expect(find.byType(SettingsHomeScreen), findsWidgets);

    // Tap Users Management tile (Arabic label)
    final usersTile = find.text('إدارة المستخدمين');
    int safety = 0;
    while (!tester.any(usersTile) && safety < 10) {
      await tester.pump(const Duration(milliseconds: 300));
      safety++;
    }
    expect(usersTile, findsWidgets);
    await tester.tap(usersTile.first);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Verify admin appears
    final adminFull = find.textContaining('Administrator');
    final adminUser = find.text('admin');
    expect(
      adminFull.evaluate().isNotEmpty || adminUser.evaluate().isNotEmpty,
      isTrue,
      reason: 'Admin user should be present ensuring tables seeded.',
    );
  });
}

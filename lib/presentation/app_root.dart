import 'package:clothes_pos/presentation/returns/screens/returns_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/presentation/pos/screens/pos_screen.dart';
import 'package:clothes_pos/presentation/auth/screens/login_screen.dart';
import 'package:clothes_pos/presentation/reports/screens/reports_home_screen.dart';
import 'package:clothes_pos/presentation/settings/screens/settings_home_screen.dart';
import 'package:clothes_pos/presentation/inventory/screens/inventory_home_screen.dart';

// AppRoot now provides a simple tab scaffold with main app sections.
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});
  static bool loginBypass = false; // TEMP: set true in dev/tests to skip login

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state.loading) {
          return const CupertinoPageScaffold(
            child: Center(child: CupertinoActivityIndicator()),
          );
        }
        if (state.user == null) {
          // إذا لم يكن هناك مستخدم مسجل الدخول، أظهر شاشة تسجيل الدخول
          return const LoginScreen();
        }

        // Authenticated: show main tab scaffold
        return ScaffoldMessenger(
          child: CupertinoTabScaffold(
            tabBar: CupertinoTabBar(
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.home),
                  label: 'المبيعات',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.square_list),
                  label: 'المخزون',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.back),
                  label: 'المرتجعات',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.chart_bar),
                  label: 'التقارير',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.settings),
                  label: 'الإعدادات',
                ),
              ],
            ),
            tabBuilder: (context, index) {
              switch (index) {
                case 0:
                  return CupertinoTabView(builder: (_) => const PosScreen());
                case 1:
                  return CupertinoTabView(
                    builder: (_) => InventoryHomeScreen(),
                  );
                case 2:
                  return CupertinoTabView(
                    builder: (_) => const ReturnsScreen(),
                  );
                case 3:
                  return CupertinoTabView(builder: (_) => ReportsHomeScreen());
                case 4:
                  return CupertinoTabView(builder: (_) => SettingsHomeScreen());
                default:
                  return CupertinoTabView(builder: (_) => const PosScreen());
              }
            },
          ),
        );
      },
    );
  }
}

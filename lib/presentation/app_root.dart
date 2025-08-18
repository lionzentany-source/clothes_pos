import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart' show ThemeMode; // for theme selection

import 'package:clothes_pos/l10n_clean/app_localizations.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/presentation/pos/bloc/pos_cubit.dart';
import 'package:clothes_pos/presentation/pos/screens/pos_screen.dart';
import 'package:clothes_pos/presentation/inventory/screens/inventory_home_screen.dart';
import 'package:clothes_pos/presentation/reports/screens/reports_home_screen.dart';
import 'package:clothes_pos/presentation/settings/screens/settings_home_screen.dart';
import 'package:clothes_pos/presentation/settings/bloc/settings_cubit.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
// user model no longer needed here for synthetic injection

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});
  static bool loginBypass = false; // TEMP: set true in dev/tests to skip login

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => PosCubit()..loadCategories()),
        BlocProvider(
          create: (_) => SettingsCubit(sl<SettingsRepository>())..load(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final settings = context.watch<SettingsCubit>().state;
          final theme = settings.themeMode == ThemeMode.dark
              ? AppTheme.dark()
              : AppTheme.light();
          return CupertinoApp(
            debugShowCheckedModeBanner: false,
            // Arabic-only UI
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: const [Locale('ar')],
            theme: theme,
            onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
            home: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state.loading) {
                  return const CupertinoPageScaffold(
                    child: Center(child: CupertinoActivityIndicator()),
                  );
                }
                return const _MainTabs();
              },
            ),
          );
        },
      ),
    );
  }
}

class _MainTabs extends StatelessWidget {
  const _MainTabs();
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.cart),
            label: l.posTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.cube_box),
            label: l.inventoryTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.chart_bar_square),
            label: l.reportsTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.settings),
            label: l.settingsTab,
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return const PosScreen();
          case 1:
            return const InventoryHomeScreen();
          case 2:
            return const ReportsHomeScreen();
          case 3:
          default:
            return const SettingsHomeScreen();
        }
      },
    );
  }
}

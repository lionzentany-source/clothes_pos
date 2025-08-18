import 'package:flutter/cupertino.dart';
import 'inventory/screens/inventory_home_screen.dart';
import 'expenses/screens/expense_list_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'settings/bloc/settings_cubit.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'pos/bloc/pos_cubit.dart';
import 'pos/screens/pos_screen.dart';
import 'reports/screens/reports_home_screen.dart';
import 'settings/screens/settings_home_screen.dart';
import 'auth/bloc/auth_cubit.dart';
import 'auth/screens/login_screen.dart';
import 'package:clothes_pos/data/repositories/sales_repository.dart';
import 'package:clothes_pos/data/repositories/cash_repository.dart';
import 'package:clothes_pos/l10n/app_localizations.dart';
import 'dart:io' show Platform;

class _NoGlowBouncingScrollBehavior extends CupertinoScrollBehavior {
  const _NoGlowBouncingScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // Remove Android glow
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final router = _buildRouter();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => SettingsCubit(sl())..load()),
      ],
      child: Builder(
        builder: (context) {
          // Configure sales repository guards dynamically when auth changes
          return BlocListener<AuthCubit, AuthState>(
            listenWhen: (p, c) => p.user != c.user,
            listener: (ctx, state) {
              final salesRepo = sl<SalesRepository>();
              final cashRepo = sl<CashRepository>();
              salesRepo.setGuards(
                permission: (code) =>
                    state.user?.permissions.contains(code) ?? false,
                openSession: () => cashRepo.getOpenSession(),
              );
            },
            child: _buildApp(context, router),
          );
        },
      ),
    );
  }

  Widget _buildApp(BuildContext context, GoRouter router) {
    final settings = context.watch<SettingsCubit>().state;

    // Base Cupertino theme
    const baseTheme = CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: CupertinoColors.activeBlue,
      barBackgroundColor: CupertinoColors.systemGrey6,
      scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
    );

    // On non-Apple platforms, prefer SF Pro if bundled; otherwise the system will fallback gracefully
    final theme = (Platform.isIOS || Platform.isMacOS)
        ? baseTheme
        : baseTheme.copyWith(
            textTheme: const CupertinoTextThemeData(
              textStyle: TextStyle(
                fontFamily: 'SF Pro',
                fontFamilyFallback: ['خط ابل العربي'],
                fontWeight: FontWeight.w500,
                color: CupertinoColors.label,
              ),
            ),
          );

    return CupertinoApp.router(
      title: AppLocalizations.of(context)?.appTitle ?? 'Clothes POS',
      routerConfig: router,
      theme: theme,
      localizationsDelegates: const [
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      locale: settings.locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      builder: (context, child) => ScrollConfiguration(
        behavior: const _NoGlowBouncingScrollBehavior(),
        child: child!,
      ),
    );
  }

  GoRouter _buildRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            final auth = context.watch<AuthCubit>().state;
            if (auth.user == null) {
              return const LoginScreen();
            }
            return const _CupertinoTabsShell();
          },
        ),
      ],
    );
  }
}

class _CupertinoTabsShell extends StatefulWidget {
  const _CupertinoTabsShell();

  @override
  State<_CupertinoTabsShell> createState() => _CupertinoTabsShellState();
}

class _CupertinoTabsShellState extends State<_CupertinoTabsShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.bag),
            label: AppLocalizations.of(context)?.posTab ?? 'المبيعات',
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.cube_box),
            label: AppLocalizations.of(context)?.inventoryTab ?? 'المخزون',
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.chart_bar),
            label: AppLocalizations.of(context)?.reportsTab ?? 'التقارير',
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.money_dollar),
            label: AppLocalizations.of(context)?.expensesTab ?? 'المصروفات',
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.settings),
            label: AppLocalizations.of(context)?.settingsTab ?? 'الإعدادات',
          ),
        ],
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
      tabBuilder: (context, index) {
        late final Widget page;
        switch (index) {
          case 0:
            page = BlocProvider(
              create: (_) => PosCubit(),
              child: const PosScreen(),
            );
            break;
          case 1:
            page = const InventoryHomeScreen();
            break;
          case 2:
            page = const ReportsHomeScreen();
            break;
          case 3:
            page = const ExpenseListScreen();
            break;
          case 4:
          default:
            page = const SettingsHomeScreen();
        }
        return CupertinoTabView(builder: (_) => page);
      },
    );
  }
}

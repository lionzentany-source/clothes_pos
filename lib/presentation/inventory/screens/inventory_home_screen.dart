import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/inventory/bloc/stocktake_rfid_cubit.dart';
import 'package:clothes_pos/l10n/app_localizations.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/inventory/bloc/inventory_cubit.dart';
import 'package:clothes_pos/presentation/inventory/screens/inventory_list_screen.dart';
import 'package:clothes_pos/presentation/inventory/bloc/stocktake_cubit.dart';
import 'package:clothes_pos/presentation/inventory/screens/stocktake_screen.dart';

class InventoryHomeScreen extends StatelessWidget {
  const InventoryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.cube_box),
            label: l?.inventoryTab ?? 'المخزون',
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.checkmark_seal),
            label: l?.stocktakeTab ?? 'الجرد',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return CupertinoTabView(
              builder: (_) => BlocProvider(
                create: (_) => InventoryCubit(),
                child: const InventoryListScreen(),
              ),
            );
          case 1:
          default:
            return CupertinoTabView(
              builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => StocktakeCubit()),
                  BlocProvider(create: (_) => StocktakeRfidCubit()),
                ],
                child: const StocktakeScreen(),
              ),
            );
        }
      },
    );
  }
}

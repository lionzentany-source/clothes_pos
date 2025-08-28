import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/inventory/bloc/stocktake_rfid_cubit.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/inventory/bloc/inventory_cubit.dart';
import 'package:clothes_pos/presentation/inventory/screens/inventory_list_screen.dart';
import 'package:clothes_pos/presentation/inventory/bloc/stocktake_cubit.dart';
import 'package:clothes_pos/presentation/inventory/screens/stocktake_screen.dart';

class InventoryHomeScreen extends StatefulWidget {
  const InventoryHomeScreen({super.key});

  @override
  State<InventoryHomeScreen> createState() => _InventoryHomeScreenState();
}

class _InventoryHomeScreenState extends State<InventoryHomeScreen> {
  int _tab = 0; // 0: inventory, 1: stocktake

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        transitionBetweenRoutes: false,
        heroTag: 'inventory-home-bar',
        middle: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: CupertinoSegmentedControl<int>(
                padding: const EdgeInsets.all(4),
                groupValue: _tab,
                onValueChanged: (v) => setState(() => _tab = v),
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('المخزون'),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('الجرد'),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _tab == 0
              ? BlocProvider(
                  key: const ValueKey('inv'),
                  create: (_) => InventoryCubit(),
                  child: const InventoryListScreen(),
                )
              : MultiBlocProvider(
                  key: const ValueKey('stk'),
                  providers: [
                    BlocProvider(create: (_) => StocktakeCubit()),
                    BlocProvider(create: (_) => StocktakeRfidCubit()),
                  ],
                  child: const StocktakeScreen(),
                ),
        ),
      ),
    );
  }
}

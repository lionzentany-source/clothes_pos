import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/main.dart' as app;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/data/models/user.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots app, login admin, navigate to Inventory', (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Force set user to skip login UI
    final user = const AppUser(
      id: 1,
      username: 'admin',
      fullName: 'Administrator',
      isActive: true,
      permissions: [
        'view_reports',
        'edit_products',
        'perform_sales',
        'perform_purchases',
        'adjust_stock',
        'manage_users',
      ],
    );
    final authCubitFinder = find.byType(BlocBuilder<AuthCubit, AuthState>);
    expect(authCubitFinder, findsWidgets);
    // Use the first matching BlocBuilder to access the cubit via context
    final element = tester.element(authCubitFinder.first);
    element.read<AuthCubit>().setUser(user);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byType(CupertinoApp), findsOneWidget);

    // Wait up to ~6s for tabs to appear (after programmatic login)
    final invLabel = find.text('Inventory');
    var tries = 0;
    while (tries < 12 && tester.any(invLabel) == false) {
      await tester.pump(const Duration(milliseconds: 500));
      tries++;
    }
    expect(invLabel, findsWidgets);

    // Inventory tab by label or icon
    if (tester.any(invLabel)) {
      await tester.tap(invLabel.first);
    } else {
      final inventoryIcon = find.byIcon(CupertinoIcons.cube_box);
      expect(inventoryIcon, findsOneWidget);
      await tester.tap(inventoryIcon);
    }
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byType(CustomScrollView), findsWidgets);
    expect(find.byIcon(CupertinoIcons.add), findsWidgets);
  });
}

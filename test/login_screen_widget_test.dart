import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/presentation/auth/screens/login_screen.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';
import 'helpers/test_helpers.dart';

void main() {
  testWidgets('LoginScreen shows دخول button when no user', (tester) async {
    // تسجيل جميع الفيكات المطلوبة في GetIt
    await setupTestDependencies();
    final authCubit = AuthCubit();
    authCubit.emit(authCubit.state.copyWith(user: null));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: CupertinoApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const LoginScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('مستخدم تجريبي'), findsWidgets);
  });
}

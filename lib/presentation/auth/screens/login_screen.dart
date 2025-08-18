import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/models/user.dart';
import 'package:clothes_pos/data/repositories/auth_repository.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authRepo = sl<AuthRepository>();

  List<AppUser> _users = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _authRepo.listActiveUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل المستخدمين';
      });
    }
  }

  Future<void> _onUserTapped(AppUser user) async {
    final ctx = context; // capture
    final l = AppLocalizations.of(ctx);
    final password = await _promptForPassword(user);
    if (password == null) return;

    // Verify credentials without changing the route yet
    final verified = await _authRepo.login(user.username, password);
    if (verified == null) {
      if (!mounted) return;
      _showErrorDialog(
        ctx,
        'خطأ',
        l?.loginInvalid ?? 'بيانات الدخول غير صحيحة',
      );
      return;
    }

    if (!mounted) return;
    ctx.read<AuthCubit>().setUser(verified);
  }

  Future<String?> _promptForPassword(AppUser user) async {
    final ctrl = TextEditingController();
    return showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) {
        return CupertinoPopupSurface(
          isSurfacePainted: true,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)?.loginEnterPassword ??
                        'أدخل كلمة المرور',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.fullName?.isNotEmpty == true
                        ? user.fullName!
                        : user.username,
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: ctrl,
                    placeholder:
                        AppLocalizations.of(context)?.loginEnterPassword ??
                        'كلمة المرور',
                    obscureText: true,
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            AppLocalizations.of(context)?.loginCancel ??
                                'إلغاء',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CupertinoButton.filled(
                          onPressed: () =>
                              Navigator.of(ctx).pop(ctrl.text.trim()),
                          child: Text(
                            AppLocalizations.of(context)?.loginContinue ??
                                'متابعة',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              AppLocalizations.of(context)?.loginTitle ?? 'تسجيل الدخول',
            ),
          ),
          child: SafeArea(
            child: _loading
                ? const Center(child: CupertinoActivityIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                          ),
                        Expanded(
                          child: _users.isEmpty
                              ? Center(
                                  child: Text(
                                    AppLocalizations.of(
                                          context,
                                        )?.loginNoUsers ??
                                        'لا يوجد مستخدمون نشطون',
                                  ),
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final maxWidth = constraints.maxWidth;
                                    final cardWidth = 160.0;
                                    final crossAxisCount =
                                        (maxWidth / (cardWidth + 16))
                                            .floor()
                                            .clamp(1, 6);
                                    return GridView.builder(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            mainAxisSpacing: 12,
                                            crossAxisSpacing: 12,
                                            childAspectRatio: 1.2,
                                          ),
                                      itemCount: _users.length,
                                      itemBuilder: (context, index) {
                                        final u = _users[index];
                                        final display =
                                            u.fullName?.isNotEmpty == true
                                            ? u.fullName!
                                            : u.username;
                                        return CupertinoButton(
                                          padding: EdgeInsets.zero,
                                          onPressed: state.loading
                                              ? null
                                              : () => _onUserTapped(u),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: CupertinoColors.activeBlue
                                                  .withOpacity(0.08),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: CupertinoColors
                                                    .activeBlue
                                                    .withOpacity(0.25),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: CupertinoColors
                                                      .activeBlue
                                                      .withOpacity(0.08),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 64,
                                                  height: 64,
                                                  decoration: BoxDecoration(
                                                    color: CupertinoColors
                                                        .activeBlue
                                                        .withOpacity(0.15),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    CupertinoIcons
                                                        .person_crop_circle,
                                                    size: 36,
                                                    color: CupertinoColors
                                                        .activeBlue,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  display,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}

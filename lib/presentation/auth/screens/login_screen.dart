import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/models/user.dart';
import 'package:clothes_pos/data/repositories/auth_repository.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';

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
      if (!mounted || !ctx.mounted) return;
      _showErrorDialog(ctx, 'خطأ', l.loginInvalid);
      return;
    }

    if (!mounted || !ctx.mounted) return;
    ctx.read<AuthCubit>().setUser(verified);
  }

  Future<String?> _promptForPassword(AppUser user) async {
    final ctrl = TextEditingController();
    return showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context).loginEnterPassword),
        content: Column(
          children: [
            const SizedBox(height: 4),
            Text(
              user.fullName?.isNotEmpty == true
                  ? user.fullName!
                  : user.username,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.activeBlue,
              ),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: ctrl,
              placeholder: AppLocalizations.of(context).loginEnterPassword,
              obscureText: true,
              autofocus: true,
              obscuringCharacter: '•',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context).loginCancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: Text(AppLocalizations.of(context).loginContinue),
          ),
        ],
      ),
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
            middle: Text(AppLocalizations.of(context).loginTitle),
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
                                    AppLocalizations.of(context).loginNoUsers,
                                  ),
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final maxWidth = constraints.maxWidth;
                                    const targetSize =
                                        150.0; // unified square size
                                    const spacing = 12.0;
                                    final crossAxisCount =
                                        (maxWidth / (targetSize + spacing))
                                            .floor()
                                            .clamp(1, 8);
                                    return GridView.builder(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            mainAxisSpacing: spacing,
                                            crossAxisSpacing: spacing,
                                            childAspectRatio:
                                                1.0, // square cells
                                          ),
                                      itemCount: _users.length,
                                      itemBuilder: (context, index) {
                                        final u = _users[index];
                                        final display =
                                            u.fullName?.isNotEmpty == true
                                            ? u.fullName!
                                            : u.username;
                                        return AspectRatio(
                                          aspectRatio: 1,
                                          child: CupertinoButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: state.loading
                                                ? null
                                                : () => _onUserTapped(u),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: CupertinoColors
                                                    .activeBlue
                                                    .withOpacity(0.08),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: CupertinoColors
                                                      .activeBlue
                                                      .withOpacity(0.25),
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: 60,
                                                    height: 60,
                                                    decoration: BoxDecoration(
                                                      color: CupertinoColors
                                                          .activeBlue
                                                          .withOpacity(0.18),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      CupertinoIcons
                                                          .person_crop_circle,
                                                      size: 34,
                                                      color: CupertinoColors
                                                          .activeBlue,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                        ),
                                                    child: Text(
                                                      display,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
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

import 'package:clothes_pos/core/logging/app_logger.dart';
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
  Future<void> _onUserTapped(AppUser user) async {
    final ctx = context; // capture
    final l = AppLocalizations.of(ctx);
    final isPlaceholder = await _authRepo.isPasswordPlaceholder(user.username);
    String? password;

    if (isPlaceholder) {
      password = await _promptForPassword(user, isFirstTime: true);
      if (password == null) return;

      final verified = await _authRepo.login(user.username, password);
      if (verified == null) {
        if (!mounted || !ctx.mounted) return;
        _showErrorDialog(ctx, 'خطأ', 'كلمة المرور يجب أن تكون 4 أحرف أو أكثر.');
        return;
      }
      if (!mounted || !ctx.mounted) return;
      // Use the new success dialog
      _showSuccessDialog(
        ctx,
        'تم تعيين كلمة المرور',
        'تم تعيين كلمة المرور بنجاح. يمكنك الآن الدخول للنظام.',
      );
      ctx.read<AuthCubit>().setUser(verified);
      return;
    } else {
      password = await _promptForPassword(user);
      if (password == null) return;

      final verified = await _authRepo.login(user.username, password);
      if (verified == null) {
        if (!mounted || !ctx.mounted) return;
        _showErrorDialog(ctx, 'خطأ', l.loginInvalid);
        return;
      }
      if (!mounted || !ctx.mounted) return;
      ctx.read<AuthCubit>().setUser(verified);
    }
  }

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
      AppLogger.d('LoginScreen._loadUsers called');
      final users = await _authRepo.listActiveUsers();
      AppLogger.d('LoginScreen._loadUsers got users: ${users.length}');
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      AppLogger.e('LoginScreen._loadUsers error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل المستخدمين';
      });
    }
  }

  Future<String?> _promptForPassword(
    AppUser user, {
    bool isFirstTime = false,
  }) async {
    final ctrl = TextEditingController();
    return showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          isFirstTime
              ? 'تعيين كلمة مرور المسؤول لأول مرة'
              : AppLocalizations.of(context).loginEnterPassword,
        ),
        content: SizedBox(
          width: 380,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  user.fullName?.isNotEmpty == true
                      ? user.fullName!
                      : user.username,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.activeBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (isFirstTime) ...[
                  const SizedBox(height: 12),
                  Text(
                    'أدخل كلمة مرور جديدة للمسؤول. سيتم حفظها في قاعدة البيانات ولن تظهر مرة أخرى.',
                    style: const TextStyle(
                      fontSize: 15,
                      color: CupertinoColors.systemGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: ctrl,
                  placeholder: isFirstTime
                      ? 'كلمة مرور جديدة للمسؤول'
                      : AppLocalizations.of(context).loginEnterPassword,
                  obscureText: true,
                  autofocus: true,
                  obscuringCharacter: '•',
                  style: const TextStyle(fontSize: 18),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context).loginCancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: Text(
              isFirstTime
                  ? 'حفظ كلمة المرور'
                  : AppLocalizations.of(context).loginContinue,
            ),
          ),
        ],
      ),
    );
  }

  // New dialog for success messages
  void _showSuccessDialog(BuildContext context, String title, String message) {
  if (!context.mounted) return; // safety
  showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
  if (!context.mounted) return; // safety
  showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: const TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Specific hints for common errors
                    if (message.contains('كلمة المرور'))
                      const Text(
                        'يرجى إدخال كلمة مرور مكونة من 4 أحرف أو أكثر.',
                        style: TextStyle(fontSize: 14),
                      ),
                    if (message.contains('المستخدمين'))
                      const Text(
                        'تعذر تحميل قائمة المستخدمين. تحقق من الاتصال أو أعد المحاولة.',
                        style: TextStyle(fontSize: 14),
                      ),
                    if (message.contains('بيانات الدخول'))
                      const Text(
                        'يرجى التأكد من صحة اسم المستخدم وكلمة المرور.',
                        style: TextStyle(fontSize: 14),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('موافق'),
            onPressed: () => Navigator.of(ctx).pop(),
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
                        const SizedBox(height: 16),
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/475686060_122111624468716899_7070205537672805384_n.jpg',
                              width: 120,
                              height: 120,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    CupertinoIcons.exclamationmark_circle,
                                    size: 120,
                                    color: CupertinoColors.systemRed,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
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
                                        return Container(
                                          margin: EdgeInsets.zero,
                                          child: CupertinoButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: state.loading
                                                ? null
                                                : () => _onUserTapped(u),
                                            child: Container(
                                              width: targetSize,
                                              height: targetSize,
                                              decoration: BoxDecoration(
                                                color: CupertinoColors
                                                    .activeBlue
                                                    .withValues(alpha: 0.08),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: CupertinoColors
                                                      .activeBlue
                                                      .withValues(alpha: 0.25),
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
                                                          .withValues(
                                                            alpha: 0.18,
                                                          ),
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

import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/datasources/auth_dao.dart';
import 'package:bcrypt/bcrypt.dart';
import '../../../l10n/app_localizations.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _working = false;

  AuthDao get _dao => sl<AuthDao>();

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _change() async {
    final auth = context.read<AuthCubit>().state;
    final userId = auth.user?.id;
    if (userId == null) return;

    final current = _currentCtrl.text.trim();
    final newPass = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    final l = AppLocalizations.of(context);
    if (newPass.length < 6) {
      await _showError(l?.passwordMinLengthError ?? 'Password too short');
      return;
    }
    if (newPass != confirm) {
      await _showError(l?.passwordConfirmMismatch ?? 'Passwords mismatch');
      return;
    }

    setState(() => _working = true);
    try {
      // تحقق من كلمة المرور الحالية عن طريق محاولة تسجيل الدخول بنفس اسم المستخدم
      final username = auth.user!.username;
      final ok = await _dao.verifyPassword(username, current);
      if (!ok) {
        await _showError(
          l?.currentPasswordIncorrect ?? 'Current password incorrect',
        );
        return;
      }
      // حدث كلمة المرور إلى bcrypt
      final newHash = await _hash(newPass);
      await _dao.updatePasswordHash(userId, newHash);
      if (!mounted) return;
      await showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text(l?.passwordChangedSuccessTitle ?? 'Done'),
          content: Text(
            l?.passwordChangedSuccessMessage ?? 'Password changed successfully',
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l?.ok ?? 'OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      await _showError(
        l == null
            ? 'Failed to change password: $e'
            : l.changePasswordFailed('$e'),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<String> _hash(String password) async {
    // استخدم نفس المنطق في AuthDao (يُنتج bcrypt)
    // لتجنب ازدواجية الكود، نعتمد على bcrypt هنا مباشرة
    // لكن دون إضافة import جديد هنا، سنستدعي DAO عبر وسيلة بسيطة
    // لأجل البساطة الآن سنحسب هنا مباشرة باستخدام نفس الحزمة
    // ملاحظة: ملف pubspec يحتوي على bcrypt
    // import bcrypt غير مضاف هنا عمداً لتقليل الاعتمادات في شاشة العرض
    // بدلاً من ذلك، سنوفر مساعد محلي مبسط إذا لزم الأمر
    return Future.value(BCrypt.hashpw(password, BCrypt.gensalt()));
  }

  Future<void> _showError(String msg) async {
    final l = AppLocalizations.of(context);
    await showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(l?.error ?? 'Error'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(l?.ok ?? 'OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l?.changePasswordTitle ?? 'Change Password'),
        trailing: _working ? const CupertinoActivityIndicator() : null,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l?.currentPasswordLabel ?? 'Current Password'),
            const SizedBox(height: 6),
            CupertinoTextField(controller: _currentCtrl, obscureText: true),
            const SizedBox(height: 12),
            Text(l?.newPasswordLabel ?? 'New Password'),
            const SizedBox(height: 6),
            CupertinoTextField(controller: _newCtrl, obscureText: true),
            const SizedBox(height: 12),
            Text(l?.confirmNewPasswordLabel ?? 'Confirm New Password'),
            const SizedBox(height: 6),
            CupertinoTextField(controller: _confirmCtrl, obscureText: true),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: _working ? null : _change,
              child: Text(l?.save ?? 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}

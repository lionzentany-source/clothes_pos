import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/datasources/auth_dao.dart';
import 'package:bcrypt/bcrypt.dart';

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

    if (newPass.length < 6) {
      await _showError('كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل');
      return;
    }
    if (newPass != confirm) {
      await _showError('تأكيد كلمة المرور غير مطابق');
      return;
    }

    setState(() => _working = true);
    try {
      final username = auth.user!.username;
      final ok = await _dao.verifyPassword(username, current);
      if (!ok) {
        await _showError('كلمة المرور الحالية غير صحيحة');
        return;
      }
      final newHash = await _hash(newPass);
      await _dao.updatePasswordHash(userId, newHash);
      if (!mounted) return;
      await showCupertinoDialog(
        context: context,
        builder: (_) => const CupertinoAlertDialog(
          title: Text('تم'),
          content: Text('تم تغيير كلمة المرور بنجاح'),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      await _showError('فشل تغيير كلمة المرور: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<String> _hash(String password) async {
    return Future.value(BCrypt.hashpw(password, BCrypt.gensalt()));
  }

  Future<void> _showError(String msg) async {
    await showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('خطأ'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('حسنًا'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  CupertinoTextField _pwField(TextEditingController c) {
    return CupertinoTextField(
      controller: c,
      obscureText: true,
      obscuringCharacter: '•',
      style: const TextStyle(color: CupertinoColors.label),
      placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('تغيير كلمة المرور'),
        trailing: _working ? const CupertinoActivityIndicator() : null,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('كلمة المرور الحالية'),
            const SizedBox(height: 6),
            _pwField(_currentCtrl),
            const SizedBox(height: 12),
            const Text('كلمة المرور الجديدة'),
            const SizedBox(height: 6),
            _pwField(_newCtrl),
            const SizedBox(height: 12),
            const Text('تأكيد كلمة المرور الجديدة'),
            const SizedBox(height: 6),
            _pwField(_confirmCtrl),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: _working ? null : _change,
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

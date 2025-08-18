import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/auth_repository.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Screen forcing admin to set a secure password on first login.
class AdminFirstPasswordScreen extends StatefulWidget {
  final String username;
  const AdminFirstPasswordScreen({super.key, required this.username});
  @override
  State<AdminFirstPasswordScreen> createState() =>
      _AdminFirstPasswordScreenState();
}

class _AdminFirstPasswordScreenState extends State<AdminFirstPasswordScreen> {
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  bool _saving = false;
  String? _error;

  bool _validatePolicy(String p) {
    return p.length >= 8 &&
        RegExp(r'[A-Za-z]').hasMatch(p) &&
        RegExp(r'\d').hasMatch(p);
  }

  Future<void> _save() async {
    final p1 = _p1.text.trim();
    final p2 = _p2.text.trim();
    if (p1 != p2) {
      setState(() => _error = 'كلمتا المرور غير متطابقتين');
      return;
    }
    if (!_validatePolicy(p1)) {
      setState(() => _error = 'كلمة المرور ضعيفة: 8 حروف على الأقل + رقم');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Fetch current admin user by login again to ensure ID
      final authRepo = sl<AuthRepository>();
      final user = await authRepo.login(
        widget.username,
        p1,
      ); // triggers upgrade if placeholder
      if (user == null) {
        setState(() {
          _saving = false;
          _error = 'فشل التحقق';
        });
        return;
      }
      // Mark flag off
      await sl<SettingsRepository>().set('admin_password_reset_required', '0');
      if (!mounted) return;
      context.read<AuthCubit>().setUser(user);
    } catch (e) {
      setState(() {
        _error = 'خطأ أثناء الحفظ';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('ضبط كلمة مرور المدير'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'يجب تعيين كلمة مرور قوية لحساب المدير قبل المتابعة.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              CupertinoTextField(
                controller: _p1,
                placeholder: 'كلمة المرور الجديدة',
                obscureText: true,
                style: const TextStyle(color: CupertinoColors.label),
                placeholderStyle: const TextStyle(
                  color: CupertinoColors.systemGrey,
                ),
                obscuringCharacter: '•',
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _p2,
                placeholder: 'تأكيد كلمة المرور',
                obscureText: true,
                style: const TextStyle(color: CupertinoColors.label),
                placeholderStyle: const TextStyle(
                  color: CupertinoColors.systemGrey,
                ),
                obscuringCharacter: '•',
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: CupertinoColors.systemRed),
                ),
              const SizedBox(height: 12),
              CupertinoButton.filled(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CupertinoActivityIndicator()
                    : const Text('حفظ ومتابعة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

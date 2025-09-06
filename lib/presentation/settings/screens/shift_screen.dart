import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/cash_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/presentation/common/widgets/app_buttons.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/presentation/design/system/app_typography.dart';
import 'package:clothes_pos/presentation/common/overlay/app_toast.dart';

class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  final CashRepository _cash = sl<CashRepository>();
  Map<String, Object?>? _session;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final s = await _cash.getOpenSession();
      if (!mounted) return;
      setState(() => _session = s);
    } catch (_) {}
  }

  Future<double?> _promptForAmount(String title, String placeholder) async {
    final ctrl = TextEditingController();
    return showCupertinoModalPopup<double>(
      context: context,
      builder: (ctx) => CupertinoPopupSurface(
        isSurfacePainted: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: ctrl,
                  placeholder: placeholder,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppPrimaryButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppPrimaryButton(
                        onPressed: () {
                          final v = double.tryParse(ctrl.text.trim());
                          if (v == null) return;
                          Navigator.of(ctx).pop(v);
                        },
                        child: const Text('تأكيد'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSession() async {
    final c = context;
    final userId = c.read<AuthCubit>().state.user?.id ?? 1;
    final amount = await _promptForAmount('بدء الجلسة', 'قيمة بداية الكاش');
    if (amount == null) return;
    setState(() => _loading = true);
    try {
      await _cash.openSession(openedBy: userId, openingFloat: amount);
      if (c.mounted) {
        AppToast.show(c, message: 'تم بدء الجلسة', type: ToastType.success);
      }
      await _loadSession();
    } catch (e) {
      if (c.mounted) {
        AppToast.show(
          c,
          message: 'فشل بدء الجلسة: ${e.toString()}',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _closeSession() async {
    if (_session == null) return;
    final sessionId = _session!['id'] as int;
    final c = context;
    final userId = c.read<AuthCubit>().state.user?.id ?? 1;
    final amount = await _promptForAmount('إغلاق الجلسة', 'أدخل مبلغ الإغلاق');
    if (amount == null) return;
    setState(() => _loading = true);
    try {
      final variance = await _cash.closeSession(
        sessionId: sessionId,
        closedBy: userId,
        closingAmount: amount,
      );
      if (c.mounted) {
        AppToast.show(
          c,
          message: 'تم إغلاق الجلسة (الفرق: ${variance.toStringAsFixed(2)})',
          type: ToastType.success,
        );
      }
      await _loadSession();
    } catch (e) {
      if (c.mounted) {
        AppToast.show(
          c,
          message: 'فشل إغلاق الجلسة: ${e.toString()}',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('إدارة الجلسة')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              if (_session == null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'لا توجد جلسة مفتوحة',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    AppPrimaryButton(
                      onPressed: _loading ? null : _openSession,
                      child: const Text('بدء جلسة جديدة'),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'جلسة مفتوحة',
                      style: AppTypography.bodyStrong.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'معرف الجلسة: ${_session!['id']}',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'فتح بواسطة: ${_session!['opened_by'] ?? '؟'}',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    AppPrimaryButton(
                      onPressed: _loading ? null : _closeSession,
                      child: const Text('إغلاق الجلسة'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

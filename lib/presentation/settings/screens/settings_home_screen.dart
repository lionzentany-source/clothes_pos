import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/cash_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';
import 'db_backup_restore_screen.dart';
// store_info_screen.dart was problematic (zero-length on disk); using new implementation file instead.
import 'store_information_screen.dart';
import 'change_password_screen.dart';
import 'inventory_settings_screen.dart';
import 'printing_settings_screen.dart';
import 'rfid_settings_screen.dart';
import 'users_management_screen.dart';
import 'roles_permissions_screen.dart';
import 'package:clothes_pos/core/backup/backup_service.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';
import 'package:clothes_pos/presentation/settings/bloc/settings_cubit.dart';
import 'package:flutter/material.dart' show ThemeMode; // for toggle
// Simplified inline expenses tab
import 'package:clothes_pos/data/repositories/expense_repository.dart';
import 'package:clothes_pos/data/models/expense.dart';
import 'package:clothes_pos/data/models/expense_category.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/core/auth/permissions.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';

import 'package:clothes_pos/assistant/ai/ai_settings_screen.dart';
import 'package:clothes_pos/assistant/assistant_screen.dart';
import 'package:clothes_pos/presentation/attributes/screens/manage_attributes_screen.dart';
import 'package:clothes_pos/presentation/attributes/bloc/attributes_cubit.dart';
import 'package:clothes_pos/core/config/feature_flags.dart';

class SettingsHomeScreen extends StatefulWidget {
  const SettingsHomeScreen({super.key});

  @override
  State<SettingsHomeScreen> createState() => _SettingsHomeScreenState();
}

class _SettingsHomeScreenState extends State<SettingsHomeScreen> {
  final _cashRepo = sl<CashRepository>();
  // Simplified expenses data (no filters/search/pagination)
  ExpenseRepository? _expenseRepo;
  List<Expense> _expenses = [];
  List<ExpenseCategory> _expenseCats = [];
  bool _expLoading = false;
  int? _filterCategoryId; // for simplified filter
  double _expensesTotal = 0;
  Future<void> _pickFilterCategory() async {
    if (_expenseCats.isEmpty) return;
    int? picked = _filterCategoryId;
    final result = await showCupertinoModalPopup<int?>(
      context: context,
      builder: (sheetCtx) => CupertinoActionSheet(
        title: const Text('الفئة'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetCtx, null),
            child: const Text('الكل'),
          ),
          for (final c in _expenseCats)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(sheetCtx, c.id),
              child: Text(c.name),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetCtx, picked),
          isDefaultAction: true,
          child: const Text('إلغاء'),
        ),
      ),
    );
    if (!mounted) return;
    if (result != picked) {
      setState(() => _filterCategoryId = result);
      _loadExpenses();
    }
  }

  void _ensureExpenseRepo() {
    if (_expenseRepo != null) return;
    try {
      _expenseRepo = sl<ExpenseRepository>();
    } catch (_) {
      _expenseRepo = null; // not registered
    }
  }

  Future<void> _loadExpenses() async {
    _ensureExpenseRepo();
    setState(() => _expLoading = true);
    if (_expenseRepo == null) {
      if (mounted) setState(() => _expLoading = false);
      return;
    }
    try {
      _expenseCats = await _expenseRepo!.listCategories();
      _expenses = await _expenseRepo!.listExpenses(
        limit: 500,
        offset: 0,
        categoryId: _filterCategoryId,
      );
      _expensesTotal = _expenses.fold(0, (p, e) => p + e.amount);
    } catch (_) {
      // ignore errors silently in simplified view
    } finally {
      if (mounted) setState(() => _expLoading = false);
    }
  }

  Future<void> _addExpense() async {
    _ensureExpenseRepo();
    if (_expenseRepo == null) return;
    final canEdit =
        context.read<AuthCubit>().state.user?.permissions.contains(
          AppPermissions.recordExpenses,
        ) ??
        false;
    if (!canEdit) return;
    // Very small inline add dialog (category, amount, note)
    int? selectedCatId = _expenseCats.isNotEmpty ? _expenseCats.first.id : null;
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    await showCupertinoDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => CupertinoAlertDialog(
          title: const Text('مصروف جديد'),
          content: Column(
            children: [
              const SizedBox(height: 8),
              if (_expenseCats.isNotEmpty)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    await showCupertinoModalPopup(
                      context: ctx,
                      builder: (_) => CupertinoActionSheet(
                        title: const Text('الفئة'),
                        actions: [
                          for (final c in _expenseCats)
                            CupertinoActionSheetAction(
                              onPressed: () {
                                Navigator.pop(ctx);
                                setSt(() => selectedCatId = c.id);
                              },
                              child: Text(c.name),
                            ),
                        ],
                        cancelButton: CupertinoActionSheetAction(
                          onPressed: () => Navigator.pop(ctx),
                          isDefaultAction: true,
                          child: const Text('إلغاء'),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    _expenseCats
                        .firstWhere(
                          (e) => e.id == selectedCatId,
                          orElse: () => _expenseCats.first,
                        )
                        .name,
                  ),
                ),
              CupertinoTextField(
                controller: amountCtrl,
                placeholder: 'المبلغ',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 4),
              CupertinoTextField(
                controller: noteCtrl,
                placeholder: 'وصف (اختياري)',
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text.trim());
                if (amt == null || amt <= 0 || selectedCatId == null) {
                  return; // invalid
                }
                final userId = context.read<AuthCubit>().state.user?.id;
                await _expenseRepo!.createExpense(
                  Expense(
                    categoryId: selectedCatId!,
                    amount: amt,
                    paidVia: 'cash',
                    date: DateTime.now(),
                    description: noteCtrl.text.trim().isEmpty
                        ? null
                        : noteCtrl.text.trim(),
                  ),
                  userId: userId,
                );
                if (!mounted) return;
                Navigator.pop(ctx);
                await _loadExpenses();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _toast(BuildContext ctx, String msg) {
    showCupertinoDialog(
      context: ctx,
      builder: (_) => CupertinoAlertDialog(
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final user = context.read<AuthCubit>().state.user;
    // If there is an open session, prompt to close it
    final session = await _cashRepo.getOpenSession();
    if (session != null && user != null) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      final title = l.logoutConfirmCloseSessionTitle;
      final amountLabel = l.logoutConfirmCloseSessionAmount;
      final closing = await _promptForNumber(title, amountLabel);
      if (closing == null) return; // cancelled
      await _cashRepo.closeSession(
        sessionId: session['id'] as int,
        closedBy: user.id,
        closingAmount: closing,
      );
    }
    if (!mounted) return;
    context.read<AuthCubit>().logout();
  }

  Future<double?> _promptForNumber(String title, String placeholder) async {
    final ctrl = TextEditingController();
    return showCupertinoModalPopup<double>(
      context: context,
      builder: (ctx) {
        final l = AppLocalizations.of(context);
        return CupertinoPopupSurface(
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
                    style: const TextStyle(color: CupertinoColors.label),
                    placeholderStyle: const TextStyle(
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(l.cancel),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CupertinoButton.filled(
                          onPressed: () {
                            final v = double.tryParse(ctrl.text.trim());
                            if (v == null) {
                              showCupertinoDialog(
                                context: ctx,
                                builder: (_) => CupertinoAlertDialog(
                                  title: Text(l.error),
                                  content: Text(l.enterValidNumber),
                                ),
                              );
                              return;
                            }
                            Navigator.of(ctx).pop(v);
                          },
                          child: Text(l.endSession),
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(l.settingsTitle)),
      child: SafeArea(
        child: ListView(
          children: [
            _SectionTitle(l.generalSection),
            _GroupCard(
              children: [
                _NavTile(
                  title: l.storeInfo,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => const StoreInformationScreen(),
                    ),
                  ),
                ),
                _NavTile(
                  title: l.changePassword,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  ),
                ),
                if (FeatureFlags.useDynamicAttributes)
                  _NavTile(
                    title: 'Manage Attributes',
                    onTap: () => Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => BlocProvider<AttributesCubit>(
                          create: (_) => sl<AttributesCubit>()..loadAttributes(),
                          child: const ManageAttributesScreen(),
                        ),
                      ),
                    ),
                  ),
                Builder(
                  builder: (ctx) {
                    final settings = ctx.watch<SettingsCubit>().state;
                    final mode = settings.themeMode;
                    Color activeColor = ctx.colors.primary;
                    return Row(
                      children: [
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'السمة',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        CupertinoSegmentedControl<ThemeMode>(
                          groupValue: mode,
                          children: {
                            ThemeMode.light: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                'فاتح',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            ThemeMode.dark: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                'داكن',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            ThemeMode.system: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                'النظام',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          },
                          onValueChanged: (m) =>
                              ctx.read<SettingsCubit>().setThemeMode(m),
                          pressedColor: activeColor.withValues(alpha: .15),
                          selectedColor: activeColor,
                          unselectedColor: CupertinoColors.systemGrey5,
                          borderColor: activeColor,
                        ),
                        const SizedBox(width: 12),
                      ],
                    );
                  },
                ),
              ],
            ),
            _SectionTitle(l.databaseSection),
            _GroupCard(
              children: [
                _NavTile(
                  title: l.dbBackupRestore,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => const DbBackupRestoreScreen(),
                    ),
                  ),
                ),
                CupertinoListTile(
                  title: const Text('نسخ احتياطي الآن'),
                  trailing: const Icon(CupertinoIcons.cloud_upload),
                  onTap: () async {
                    final ctx = context; // capture for async safety
                    final svc = sl.isRegistered<BackupService>()
                        ? sl<BackupService>()
                        : null;
                    if (svc == null) return;
                    showCupertinoDialog(
                      context: ctx,
                      builder: (_) => const CupertinoAlertDialog(
                        content: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CupertinoActivityIndicator(),
                        ),
                      ),
                    );
                    try {
                      await svc.runManual();
                      if (!mounted) return;
                      Navigator.of(ctx).pop();
                      _toast(ctx, 'تم إنشاء النسخة الاحتياطية بنجاح');
                    } catch (e) {
                      AppLogger.e('Manual backup failed', error: e);
                      if (!mounted) return;
                      Navigator.of(ctx).pop();
                      _toast(ctx, 'فشل النسخ الاحتياطي');
                    }
                  },
                ),
              ],
            ),
            _SectionTitle(l.inventoryPrintRfidSection),
            _GroupCard(
              children: [
                _NavTile(
                  title: l.inventorySettings,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => const InventorySettingsScreen(),
                    ),
                  ),
                ),
                // Expenses tab below inventory settings
                _NavTile(
                  title: 'المصروفات',
                  onTap: () {
                    if (_expenses.isEmpty) _loadExpenses();
                    if (!mounted) return;
                    showCupertinoModalPopup(
                      context: context,
                      builder: (ctx) => CupertinoPageScaffold(
                        navigationBar: CupertinoNavigationBar(
                          middle: const Text('المصروفات'),
                          leading: CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: const Icon(CupertinoIcons.back),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ),
                        child: SafeArea(child: _buildExpensesTab()),
                      ),
                    );
                  },
                ),
                _NavTile(
                  title: 'المساعد التدريبي (بدون إنترنت)',
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => const AssistantScreen()),
                  ),
                ),
                _NavTile(
                  title: 'إعدادات الذكاء الاصطناعي',
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => const AiSettingsScreen(),
                    ),
                  ),
                ),

                _NavTile(
                  title: l.printingSettings,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => const PrintingSettingsScreen(),
                    ),
                  ),
                ),
                _NavTile(
                  title: l.rfidSettings,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (_) => const RfidSettingsScreen(),
                    ),
                  ),
                ),
              ],
            ),
            _SectionTitle(l.userAccountSection),
            Builder(
              builder: (ctx) {
                final perms =
                    ctx.watch<AuthCubit>().state.user?.permissions ?? const [];
                final hasManage = perms.contains(AppPermissions.manageUsers);
                final note = hasManage ? null : 'مقيد: لا تملك صلاحية الإدارة';
                return _GroupCard(
                  children: [
                    _NavTile(
                      title: 'إدارة المستخدمين',
                      subtitle: note,
                      enabled: hasManage,
                      onTap: () {
                        final nav = Navigator.of(ctx);
                        nav.push(
                          CupertinoPageRoute(
                            builder: (_) => const UsersManagementScreen(),
                          ),
                        );
                      },
                    ),
                    _NavTile(
                      title: 'الأدوار و الصلاحيات',
                      subtitle: note,
                      enabled: hasManage,
                      onTap: () {
                        final nav = Navigator.of(ctx);
                        nav.push(
                          CupertinoPageRoute(
                            builder: (_) => const RolesPermissionsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            _GroupCard(
              children: [
                Builder(
                  builder: (context) {
                    return CupertinoListTile(
                      title: Text(
                        l.logout,
                        style: const TextStyle(
                          color: CupertinoColors.destructiveRed,
                        ),
                      ),
                      trailing: const Icon(
                        CupertinoIcons.arrow_right_square,
                        color: CupertinoColors.destructiveRed,
                      ),
                      onTap: _logout,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Simplified expenses tab widget pieces
extension on _SettingsHomeScreenState {
  Widget _buildExpensesTab() {
    final canEdit =
        context.watch<AuthCubit>().state.user?.permissions.contains(
          AppPermissions.recordExpenses,
        ) ??
        false;
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 12),
            const Text('المصروفات (مبسط)'),
            const Spacer(),
            // Category filter button
            if (_expenseCats.isNotEmpty)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _pickFilterCategory,
                child: Icon(
                  _filterCategoryId == null
                      ? CupertinoIcons.line_horizontal_3_decrease_circle
                      : CupertinoIcons.line_horizontal_3_decrease_circle_fill,
                ),
              ),
            if (canEdit)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _addExpense,
                child: const Icon(CupertinoIcons.add_circled),
              ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _expLoading ? null : _loadExpenses,
              child: _expLoading
                  ? const CupertinoActivityIndicator()
                  : const Icon(CupertinoIcons.refresh),
            ),
            const SizedBox(width: 8),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                'الإجمالي: ${_expensesTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_filterCategoryId != null)
                Text(
                  _expenseCats
                      .firstWhere(
                        (c) => c.id == _filterCategoryId,
                        orElse: () => ExpenseCategory(
                          id: _filterCategoryId!,
                          name: 'فئة',
                        ),
                      )
                      .name,
                  style: const TextStyle(color: CupertinoColors.secondaryLabel),
                ),
            ],
          ),
        ),
        Expanded(
          child: _expLoading && _expenses.isEmpty
              ? const Center(child: CupertinoActivityIndicator())
              : _expenses.isEmpty
              ? const Center(child: Text('لا توجد مصروفات'))
              : ListView.separated(
                  itemCount: _expenses.length,
                  separatorBuilder: (_, __) =>
                      Container(height: 1, color: CupertinoColors.separator),
                  itemBuilder: (ctx, i) {
                    final e = _expenses[i];
                    final catName = _expenseCats
                        .firstWhere(
                          (c) => c.id == e.categoryId,
                          orElse: () =>
                              ExpenseCategory(id: e.categoryId, name: 'فئة'),
                        )
                        .name;
                    return CupertinoListTile(
                      title: Text(catName),
                      subtitle: Text(
                        '${e.amount.toStringAsFixed(2)} • ${e.date.toIso8601String().substring(0, 10)}',
                      ),
                      trailing: canEdit
                          ? CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () async {
                                final ok = await showCupertinoDialog<bool>(
                                  context: context,
                                  builder: (_) => CupertinoAlertDialog(
                                    title: const Text('حذف'),
                                    content: const Text('تأكيد حذف المصروف؟'),
                                    actions: [
                                      CupertinoDialogAction(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('إلغاء'),
                                      ),
                                      CupertinoDialogAction(
                                        isDestructiveAction: true,
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('حذف'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true && e.id != null) {
                                  final userId = context
                                      .read<AuthCubit>()
                                      .state
                                      .user
                                      ?.id;
                                  await _expenseRepo!.deleteExpense(
                                    e.id!,
                                    userId: userId,
                                  );
                                  if (!mounted) return;
                                  await _loadExpenses();
                                }
                              },
                              child: const Icon(
                                CupertinoIcons.delete,
                                size: 20,
                                color: CupertinoColors.destructiveRed,
                              ),
                            )
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  final List<Widget> children;
  const _GroupCard({required this.children});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(children: children),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
          fontSize: 17,
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  const _NavTile({
    required this.title,
    this.subtitle,
    this.onTap,
    this.enabled = true,
  });
  @override
  Widget build(BuildContext context) {
    final baseStyle = CupertinoTheme.of(context).textTheme.textStyle;
    final disabled = context.colors.textSecondary;
    return CupertinoListTile(
      title: Text(
        title,
        style: (enabled
            ? baseStyle.copyWith(
                color: CupertinoColors.label,
                fontWeight: FontWeight.w500,
                fontSize: (baseStyle.fontSize ?? 16) + 1,
              )
            : baseStyle.copyWith(color: disabled)),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: baseStyle.copyWith(
                fontSize: 12,
                color: enabled ? context.colors.textSecondary : disabled,
              ),
            ),
      trailing: Icon(
        CupertinoIcons.chevron_forward,
        color: enabled ? CupertinoColors.systemGrey : disabled,
        size: 18,
      ),
      onTap: enabled ? onTap : null,
    );
  }
}

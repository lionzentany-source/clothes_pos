import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/l10n/app_localizations.dart';
import 'package:clothes_pos/data/repositories/expense_repository.dart';
import 'package:clothes_pos/data/models/expense.dart';
import 'package:clothes_pos/data/models/expense_category.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/core/auth/permissions.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/presentation/common/view_only_banner.dart';
import 'package:clothes_pos/data/repositories/cash_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExpenseEditorScreen extends StatefulWidget {
  final Expense? existing;
  const ExpenseEditorScreen({super.key, this.existing});

  @override
  State<ExpenseEditorScreen> createState() => _ExpenseEditorScreenState();
}

class _ExpenseEditorScreenState extends State<ExpenseEditorScreen> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  ExpenseCategory? _category;
  DateTime _date = DateTime.now();
  String _paidVia = 'cash';
  bool _saving = false;
  List<ExpenseCategory> _cats = [];

  ExpenseRepository get _repo => sl<ExpenseRepository>();

  @override
  void initState() {
    super.initState();
    _loadCats();
    final e = widget.existing;
    if (e != null) {
      _amountCtrl.text = e.amount.toString();
      _descCtrl.text = e.description ?? '';
      _date = e.date;
      _paidVia = e.paidVia;
    }
  }

  Future<void> _loadCats() async {
    final cats = await _repo.listCategories();
    if (mounted) setState(() => _cats = cats);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    await showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(
          AppLocalizations.of(context)?.chooseCategory ?? 'اختر الفئة',
        ),
        actions: [
          for (final c in _cats)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _category = c);
              },
              child: Text(c.name),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          isDefaultAction: true,
          child: Text(AppLocalizations.of(context)?.cancel ?? 'إلغاء'),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    DateTime temp = _date;
    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        color: CupertinoColors.systemGroupedBackground,
        height: 300,
        child: Column(
          children: [
            SizedBox(
              height: 216,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _date,
                onDateTimeChanged: (d) => temp = d,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)?.cancel ?? 'إلغاء'),
                ),
                CupertinoButton(
                  onPressed: () {
                    setState(() => _date = temp);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    AppLocalizations.of(context)?.pickAction ?? 'اختر',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final canEdit =
        context.read<AuthCubit>().state.user?.permissions.contains(
          AppPermissions.recordExpenses,
        ) ??
        false;
    if (!canEdit) return;
    final amt = double.tryParse(_amountCtrl.text.trim());
    if (amt == null || amt <= 0) {
      _showErr(
        AppLocalizations.of(context)?.enterValidNumber ?? 'أدخل مبلغ صالح',
      );
      return;
    }
    if (_category == null && widget.existing == null) {
      _showErr(AppLocalizations.of(context)?.chooseCategory ?? 'اختر فئة');
      return;
    }
    setState(() => _saving = true);
    try {
      int? cashSessionId;
      if (_paidVia == 'cash') {
        final open = await sl<CashRepository>().getOpenSession();
        cashSessionId = open == null ? null : open['id'] as int;
      }
      final exp = Expense(
        id: widget.existing?.id,
        categoryId: _category?.id ?? widget.existing!.categoryId,
        amount: amt,
        paidVia: _paidVia,
        cashSessionId: cashSessionId,
        date: DateTime(_date.year, _date.month, _date.day),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
      );
      if (exp.id == null) {
        await _repo.createExpense(exp);
      } else {
        await _repo.updateExpense(exp);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _showErr(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showErr(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context)?.error ?? 'خطأ'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)?.ok ?? 'حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canEdit =
        context.watch<AuthCubit>().state.user?.permissions.contains(
          AppPermissions.recordExpenses,
        ) ??
        false;
    final existing = widget.existing;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          existing == null
              ? (AppLocalizations.of(context)?.newExpenseTitle ?? 'مصروف جديد')
              : (AppLocalizations.of(context)?.editExpenseTitle ??
                    'تعديل مصروف'),
        ),
        trailing: canEdit
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CupertinoActivityIndicator()
                    : const Icon(CupertinoIcons.check_mark),
              )
            : null,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!canEdit)
              ViewOnlyBanner(
                message:
                    (AppLocalizations.of(context)?.viewOnlyRecordExpenses ??
                    'عرض فقط: لا تملك صلاحية تسجيل المصروفات'),
                margin: const EdgeInsets.only(bottom: 12),
              ),
            CupertinoButton(
              onPressed: canEdit ? _pickCategory : null,
              padding: EdgeInsets.zero,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _category?.name ??
                      existing?.categoryName ??
                      (AppLocalizations.of(context)?.chooseCategory ??
                          'اختر الفئة'),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _amountCtrl,
              placeholder:
                  AppLocalizations.of(context)?.amountPlaceholder ?? 'المبلغ',
              enabled: canEdit,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              onPressed: canEdit ? _pickDate : null,
              padding: EdgeInsets.zero,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${AppLocalizations.of(context)?.dateLabel ?? 'التاريخ:'} ${_date.toIso8601String().substring(0, 10)}',
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AbsorbPointer(
                  absorbing: !canEdit,
                  child: CupertinoSegmentedControl<String>(
                    groupValue: _paidVia,
                    children: {
                      'cash': Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          AppLocalizations.of(context)?.cashShort ?? 'نقد',
                        ),
                      ),
                      'bank': Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          AppLocalizations.of(context)?.bankShort ?? 'بنكي',
                        ),
                      ),
                      'other': Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          AppLocalizations.of(context)?.otherShort ?? 'أخرى',
                        ),
                      ),
                    },
                    onValueChanged: (v) => setState(() => _paidVia = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _descCtrl,
              placeholder:
                  AppLocalizations.of(context)?.descriptionOptional ??
                  'وصف (اختياري)',
              enabled: canEdit,
              maxLines: 3,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 24),
            if (canEdit)
              CupertinoButton.filled(
                onPressed: _saving ? null : _save,
                child: Text(
                  existing == null
                      ? (AppLocalizations.of(context)?.save ?? 'حفظ')
                      : (AppLocalizations.of(context)?.updateAction ?? 'تحديث'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

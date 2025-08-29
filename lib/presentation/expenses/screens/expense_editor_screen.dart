import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/data/repositories/expense_repository.dart';
import 'package:clothes_pos/data/models/expense.dart';
import 'package:clothes_pos/data/models/expense_category.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/core/auth/permissions.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/presentation/common/view_only_banner.dart';
import 'package:clothes_pos/data/repositories/cash_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/common/sql_error_helper.dart';

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
                  child: const Text('إلغاء'),
                ),
                CupertinoButton(
                  onPressed: () {
                    setState(() => _date = temp);
                    Navigator.of(context).pop();
                  },
                  child: const Text('اختر'),
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
      _showErr('أدخل مبلغ صالح');
      return;
    }
    if (_category == null && widget.existing == null) {
      _showErr('اختر فئة');
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
      if (!mounted) return;
      final userId = context.read<AuthCubit>().state.user?.id;
      if (exp.id == null) {
        await _repo.createExpense(exp, userId: userId);
      } else {
        await _repo.updateExpense(exp, userId: userId);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _showErr(SqlErrorHelper.toArabicMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showErr(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('خطأ'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
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
        middle: Text(existing == null ? 'مصروف جديد' : 'تعديل مصروف'),
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
              const ViewOnlyBanner(
                message: 'عرض فقط: لا تملك صلاحية تسجيل المصروفات',
                margin: EdgeInsets.only(bottom: 12),
              ),
            CupertinoButton(
              onPressed: canEdit
                  ? () async {
                      // استخدم نفس قائمة الفئات من شاشة التصفية
                      final cats = _cats;
                      await showCupertinoModalPopup(
                        context: context,
                        builder: (_) => CupertinoActionSheet(
                          title: const Text('اختر الفئة'),
                          actions: [
                            for (final c in cats)
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
                            child: const Text('إلغاء'),
                          ),
                        ),
                      );
                    }
                  : null,
              padding: EdgeInsets.zero,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _category?.name ?? existing?.categoryName ?? 'اختر الفئة',
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _amountCtrl,
              placeholder: 'المبلغ',
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
                  'التاريخ: ${_date.toIso8601String().substring(0, 10)}',
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
                    children: const {
                      'cash': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('نقد'),
                      ),
                      'bank': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('بنكي'),
                      ),
                      'other': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('أخرى'),
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
              placeholder: 'أدخل وصفًا تفصيليًا',
              enabled: canEdit,
              maxLines: 3,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 24),
            if (canEdit)
              CupertinoButton.filled(
                onPressed: _saving ? null : _save,
                child: Text(existing == null ? 'حفظ' : 'تحديث'),
              ),
          ],
        ),
      ),
    );
  }
}

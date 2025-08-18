import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/l10n/app_localizations.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/expense_repository.dart';
import 'package:clothes_pos/data/models/expense.dart';
import 'package:clothes_pos/data/models/expense_category.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/core/auth/permissions.dart';
import 'package:clothes_pos/presentation/common/view_only_banner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'expense_editor_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final _repo = sl<ExpenseRepository>();
  List<Expense> _items = [];
  List<ExpenseCategory> _cats = [];
  ExpenseCategory? _selectedCat;
  String? _paidVia; // cash | bank | other
  DateTime? _start;
  DateTime? _end;
  bool _loading = true;
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
  }

  Future<void> _load({bool initial = false}) async {
    setState(() => _loading = true);
    try {
      if (initial) {
        _cats = await _repo.listCategories();
      }
      final items = await _repo.listExpenses(
        start: _start,
        end: _end,
        categoryId: _selectedCat?.id,
        paidVia: _paidVia,
      );
      final total = await _repo.sumExpenses(
        start: _start,
        end: _end,
        categoryId: _selectedCat?.id,
      );
      if (mounted) {
        setState(() {
          _items = items;
          _total = total;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    DateTime base = (isStart ? _start : _end) ?? DateTime.now();
    DateTime temp = base;
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
                initialDateTime: base,
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
                    setState(() {
                      if (isStart) {
                        _start = DateTime(temp.year, temp.month, temp.day);
                      } else {
                        _end = DateTime(temp.year, temp.month, temp.day);
                      }
                    });
                    Navigator.of(context).pop();
                    _load();
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

  Future<void> _pickCategory() async {
    await showCupertinoModalPopup(
      context: context,
      builder: (sheetCtx) => CupertinoActionSheet(
        title: Text(AppLocalizations.of(context)?.categoryTitle ?? 'الفئة'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetCtx);
              setState(() => _selectedCat = null);
              _load();
            },
            child: Text(AppLocalizations.of(context)?.filterAll ?? 'الكل'),
          ),
          for (final c in _cats)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(sheetCtx);
                setState(() => _selectedCat = c);
                _load();
              },
              child: Text(c.name),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetCtx),
          isDefaultAction: true,
          child: Text(AppLocalizations.of(context)?.cancel ?? 'إلغاء'),
        ),
      ),
    );
  }

  Future<void> _pickPaidVia() async {
    await showCupertinoModalPopup(
      context: context,
      builder: (sheetCtx) => CupertinoActionSheet(
        title: Text(
          AppLocalizations.of(context)?.paymentMethodTitle ?? 'طريقة الدفع',
        ),
        actions: [
          for (final v in ['all', 'cash', 'bank', 'other'])
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(sheetCtx);
                setState(() => _paidVia = v == 'all' ? null : (v));
                _load();
              },
              child: Text(
                v == 'cash'
                    ? (AppLocalizations.of(context)?.cashShort ?? 'نقد')
                    : v == 'bank'
                    ? (AppLocalizations.of(context)?.bankShort ?? 'بنكي')
                    : v == 'other'
                    ? (AppLocalizations.of(context)?.otherShort ?? 'أخرى')
                    : (AppLocalizations.of(context)?.filterAll ?? 'الكل'),
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetCtx),
          isDefaultAction: true,
          child: Text(AppLocalizations.of(context)?.cancel ?? 'إلغاء'),
        ),
      ),
    );
  }

  Future<void> _openEditor([Expense? e]) async {
    final changed = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(builder: (_) => ExpenseEditorScreen(existing: e)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit =
        context.watch<AuthCubit>().state.user?.permissions.contains(
          AppPermissions.recordExpenses,
        ) ??
        false;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppLocalizations.of(context)?.expensesTab ?? 'المصروفات'),
        trailing: canEdit
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _openEditor(),
                child: const Icon(CupertinoIcons.add),
              )
            : null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (!canEdit)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: ViewOnlyBanner(
                  message:
                      (AppLocalizations.of(context)?.viewOnlyRecordExpenses ??
                      'عرض فقط: لا تملك صلاحية تسجيل المصروفات'),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: _pickCategory,
                      child: Text(
                        _selectedCat?.name ??
                            (AppLocalizations.of(context)?.filterAll ??
                                'كل الفئات'),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: _pickPaidVia,
                      child: Text(
                        _paidVia == null
                            ? (AppLocalizations.of(context)?.allMethods ??
                                  'كل الطرق')
                            : _paidVia == 'cash'
                            ? (AppLocalizations.of(context)?.cashShort ?? 'نقد')
                            : _paidVia == 'bank'
                            ? (AppLocalizations.of(context)?.bankShort ??
                                  'بنكي')
                            : (AppLocalizations.of(context)?.otherShort ??
                                  'أخرى'),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: () => _pickDate(isStart: true),
                      child: Text(
                        _start == null
                            ? (AppLocalizations.of(context)?.fromLabel ?? 'من')
                            : _start!.toIso8601String().substring(0, 10),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: () => _pickDate(isStart: false),
                      child: Text(
                        _end == null
                            ? (AppLocalizations.of(context)?.toLabel ?? 'إلى')
                            : _end!.toIso8601String().substring(0, 10),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: _loading
                          ? null
                          : () {
                              setState(() {
                                _start = null;
                                _end = null;
                                _selectedCat = null;
                                _paidVia = null;
                              });
                              _load();
                            },
                      child: const Icon(CupertinoIcons.clear_circled),
                    ),
                  ].reversed.toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppLocalizations.of(context)?.totalLabelExpenses ?? 'الإجمالي:'} ${_total.toStringAsFixed(2)}',
                  ),
                  if (_loading)
                    const CupertinoActivityIndicator()
                  else
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _load,
                      child: const Icon(CupertinoIcons.refresh),
                    ),
                ],
              ),
            ),
            Container(height: 1, color: CupertinoColors.separator),
            Expanded(
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _items.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)?.noData ??
                            'لا توجد بيانات',
                      ),
                    )
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => Container(
                        height: 1,
                        color: CupertinoColors.separator,
                      ),
                      itemBuilder: (context, i) {
                        final e = _items[i];
                        return CupertinoListTile(
                          title: Text(e.categoryName ?? ''),
                          subtitle: Text(
                            '${e.amount.toStringAsFixed(2)} — ${e.paidVia == 'cash'
                                ? (AppLocalizations.of(context)?.cashShort ?? 'نقد')
                                : e.paidVia == 'bank'
                                ? (AppLocalizations.of(context)?.bankShort ?? 'بنكي')
                                : (AppLocalizations.of(context)?.otherShort ?? 'أخرى')}\n${e.date.toIso8601String().substring(0, 10)}',
                            textDirection: TextDirection.rtl,
                          ),
                          onTap: () => _openEditor(e),
                          trailing: canEdit
                              ? CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () async {
                                    final ok = await showCupertinoDialog<bool>(
                                      context: context,
                                      builder: (_) => CupertinoAlertDialog(
                                        title: Text(
                                          AppLocalizations.of(
                                                context,
                                              )?.deleteTitle ??
                                              'حذف',
                                        ),
                                        content: Text(
                                          AppLocalizations.of(
                                                context,
                                              )?.deleteExpenseConfirm ??
                                              'تأكيد حذف المصروف؟',
                                        ),
                                        actions: [
                                          CupertinoDialogAction(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text(
                                              AppLocalizations.of(
                                                    context,
                                                  )?.cancel ??
                                                  'إلغاء',
                                            ),
                                          ),
                                          CupertinoDialogAction(
                                            isDestructiveAction: true,
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text(
                                              AppLocalizations.of(
                                                    context,
                                                  )?.deleteTitle ??
                                                  'حذف',
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true) {
                                      await _repo.deleteExpense(e.id!);
                                      _load();
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
        ),
      ),
    );
  }
}

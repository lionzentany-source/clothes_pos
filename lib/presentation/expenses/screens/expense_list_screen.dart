import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';
import 'package:clothes_pos/presentation/common/widgets/action_button.dart';
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
  final DateTime? initialStart;
  final DateTime? initialEnd;
  const ExpenseListScreen({super.key, this.initialStart, this.initialEnd});

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
  bool _exporting = false;
  bool _slow = false;
  static const _pageSize = 250;
  int _currentOffset = 0;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
    _load(initial: true);
  }

  Future<void> _exportCsv() async {
    if (_items.isEmpty || _exporting) return;
    setState(() => _exporting = true);
    try {
      final buf = StringBuffer();
      buf.writeln(
        'id,date,category,amount,paid_via,cash_session_id,description',
      );
      for (final e in _items) {
        buf.writeln(
          [
            e.id ?? '',
            e.date.toIso8601String().substring(0, 10),
            (e.categoryName ?? '').replaceAll(',', ' '),
            e.amount.toStringAsFixed(2),
            e.paidVia,
            e.cashSessionId ?? '',
            (e.description ?? '').replaceAll('\n', ' ').replaceAll(',', ' '),
          ].join(','),
        );
      }
      final data = buf.toString();
      // Simple approach: show share sheet via Printing if available
      // (If not added, ignore silently)
      // ignore: avoid_print
      // Placeholder: could integrate a file saver plugin.
      await showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('تم إنشاء CSV'),
          content: const Text('انسخ النص ثم الصقه في ملف .csv'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
      // Copy to clipboard
      // ignore: deprecated_member_use
      await Clipboard.setData(ClipboardData(text: data));
    } catch (_) {
      // ignore silently
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _load({bool initial = false}) async {
    setState(() => _loading = true);
    final swAll = Stopwatch()..start();
    AppLogger.d(
      'ExpenseListScreen._load start initial=$initial start=$_start end=$_end cat=${_selectedCat?.id} paidVia=$_paidVia',
    );
    try {
      // Guard: if load takes more than 5 seconds, log warning (will still continue)
      Future.delayed(const Duration(seconds: 5), () {
        if (_loading && mounted) {
          AppLogger.w('ExpenseListScreen._load still running after 5s');
          setState(() => _slow = true);
        }
      });
      _slow = false;
      if (initial) {
        try {
          final swCats = Stopwatch()..start();
          _cats = await _repo.listCategories();
          swCats.stop();
          AppLogger.d(
            'ExpenseListScreen categories loaded count=${_cats.length} in ${swCats.elapsedMilliseconds}ms',
          );
        } catch (e, st) {
          AppLogger.e(
            'ExpenseListScreen listCategories failed',
            error: e,
            stackTrace: st,
          );
          rethrow;
        }
      }
      late List<Expense> items;
      late double total;
      try {
        final swItems = Stopwatch()..start();
        _currentOffset = 0;
        items = await _repo.listExpenses(
          start: _start,
          end: _end,
          categoryId: _selectedCat?.id,
          paidVia: _paidVia,
          limit: _pageSize + 1,
          offset: _currentOffset,
        );
        swItems.stop();
        AppLogger.d(
          'ExpenseListScreen listExpenses count=${items.length} in ${swItems.elapsedMilliseconds}ms',
        );
        if (items.length > _pageSize) {
          _hasMore = true;
          items = items.take(_pageSize).toList();
        } else {
          _hasMore = false;
        }
      } catch (e, st) {
        AppLogger.e(
          'ExpenseListScreen listExpenses failed',
          error: e,
          stackTrace: st,
        );
        rethrow;
      }
      try {
        final swTotal = Stopwatch()..start();
        total = await _repo.sumExpenses(
          start: _start,
          end: _end,
          categoryId: _selectedCat?.id,
        );
        swTotal.stop();
        AppLogger.d(
          'ExpenseListScreen sumExpenses total=$total in ${swTotal.elapsedMilliseconds}ms',
        );
      } catch (e, st) {
        AppLogger.e(
          'ExpenseListScreen sumExpenses failed',
          error: e,
          stackTrace: st,
        );
        rethrow;
      }
      if (mounted) {
        setState(() {
          _items = items;
          _total = total;
        });
      }
    } catch (e) {
      if (!mounted) return;
      await showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('خطأ تحميل المصروفات'),
          content: Text(e.toString()),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
      swAll.stop();
      AppLogger.d(
        'ExpenseListScreen._load end loading=$_loading items=${_items.length} totalTimeMs=${swAll.elapsedMilliseconds}',
      );
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loading) return;
    setState(() => _loading = true);
    try {
      _currentOffset += _pageSize;
      final more = await _repo.listExpenses(
        start: _start,
        end: _end,
        categoryId: _selectedCat?.id,
        paidVia: _paidVia,
        limit: _pageSize + 1,
        offset: _currentOffset,
      );
      if (mounted) {
        setState(() {
          if (more.length > _pageSize) {
            _hasMore = true;
            _items.addAll(more.take(_pageSize));
          } else {
            _hasMore = false;
            _items.addAll(more);
          }
        });
      }
    } catch (e) {
      AppLogger.e('ExpenseListScreen _loadMore failed', error: e);
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
                  child: const Text('إلغاء'),
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
                  child: const Text('اختر'),
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
        title: const Text('الفئة'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetCtx);
              setState(() => _selectedCat = null);
              _load();
            },
            child: const Text('الكل'),
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
          child: const Text('إلغاء'),
        ),
      ),
    );
  }

  Future<void> _pickPaidVia() async {
    await showCupertinoModalPopup(
      context: context,
      builder: (sheetCtx) => CupertinoActionSheet(
        title: const Text('طريقة الدفع'),
        actions: [
          for (final v in ['الكل', 'cash', 'bank', 'other'])
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(sheetCtx);
                setState(() => _paidVia = v == 'الكل' ? null : (v));
                _load();
              },
              child: Text(
                v == 'cash'
                    ? 'نقد'
                    : v == 'bank'
                    ? 'بنكي'
                    : v == 'other'
                    ? 'أخرى'
                    : 'الكل',
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetCtx),
          isDefaultAction: true,
          child: const Text('إلغاء'),
        ),
      ),
    );
  }

  Future<void> _openEditor([Expense? e]) async {
    final changed = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(builder: (_) => ExpenseEditorScreen(existing: e)),
    );
    if (changed == true) {
      AppLogger.d('ExpenseListScreen editor returned changed');
      _load();
    }
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
        middle: const Text('المصروفات'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _exporting ? null : _exportCsv,
              child: _exporting
                  ? const CupertinoActivityIndicator()
                  : const Icon(CupertinoIcons.arrow_down_doc),
            ),
            if (canEdit)
              ActionButton(
                onPressed: () => _openEditor(),
                label: 'إضافة',
                leading: const Icon(
                  CupertinoIcons.add,
                  color: CupertinoColors.white,
                ),
              ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (!canEdit)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ViewOnlyBanner(
                  message: 'عرض فقط: لا تملك صلاحية تسجيل المصروفات',
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
                      child: Text(_selectedCat?.name ?? 'كل الفئات'),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: _pickPaidVia,
                      child: Text(
                        _paidVia == null
                            ? 'كل الطرق'
                            : _paidVia == 'cash'
                            ? 'نقد'
                            : _paidVia == 'bank'
                            ? 'بنكي'
                            : 'أخرى',
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: () => _pickDate(isStart: true),
                      child: Text(
                        _start == null
                            ? 'من'
                            : _start!.toIso8601String().substring(0, 10),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: () => _pickDate(isStart: false),
                      child: Text(
                        _end == null
                            ? 'إلى'
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
                  Text('الإجمالي: ${_total.toStringAsFixed(2)}'),
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
              child: Builder(
                builder: (_) {
                  if (_loading && _items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CupertinoActivityIndicator(),
                          if (_slow) ...[
                            const SizedBox(height: 12),
                            const Text('جاري التحميل...'),
                            const SizedBox(height: 8),
                            // يمكن لاحقاً إضافة زر إلغاء وظيفي
                          ],
                        ],
                      ),
                    );
                  }
                  if (_items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.doc_text,
                            size: 40,
                            color: CupertinoColors.inactiveGray,
                          ),
                          const SizedBox(height: 8),
                          const Text('لا توجد مصروفات'),
                          const SizedBox(height: 12),
                          ActionButton(
                            onPressed: () => _openEditor(),
                            label: 'إضافة أول مصروف',
                            leading: const Icon(
                              CupertinoIcons.add,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollEndNotification) {
                        final pos = n.metrics.pixels;
                        final max = n.metrics.maxScrollExtent;
                        if (max - pos < 200 && _hasMore && !_loading) {
                          _loadMore();
                        }
                      }
                      return false;
                    },
                    child: ListView.separated(
                      itemCount: _items.length + (_hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => Container(
                        height: 1,
                        color: CupertinoColors.separator,
                      ),
                      itemBuilder: (context, i) {
                        if (i >= _items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CupertinoActivityIndicator()),
                          );
                        }
                        final e = _items[i];
                        return CupertinoListTile(
                          title: Text(e.categoryName ?? ''),
                          subtitle: Text(
                            '${e.amount.toStringAsFixed(2)} — ${e.paidVia == 'cash'
                                ? 'نقد'
                                : e.paidVia == 'bank'
                                ? 'بنكي'
                                : 'أخرى'}${e.cashSessionId != null ? ' • جلسة ${e.cashSessionId}' : ''}\n${e.date.toIso8601String().substring(0, 10)}',
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
                                        title: const Text('حذف'),
                                        content: const Text(
                                          'تأكيد حذف المصروف؟',
                                        ),
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
                                    if (ok == true) {
                                      final userId = context
                                          .read<AuthCubit>()
                                          .state
                                          .user
                                          ?.id;
                                      await _repo.deleteExpense(
                                        e.id!,
                                        userId: userId,
                                      );
                                      if (!mounted) return;
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

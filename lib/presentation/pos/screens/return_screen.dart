import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/datasources/returns_dao.dart';
import 'package:clothes_pos/data/repositories/returns_repository.dart';
import 'package:clothes_pos/presentation/common/money.dart';
import 'package:clothes_pos/presentation/common/sql_error_helper.dart';
import 'package:clothes_pos/presentation/common/widgets/action_button.dart';

import 'package:flutter/cupertino.dart';

class ReturnScreen extends StatefulWidget {
  const ReturnScreen({super.key});

  @override
  State<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends State<ReturnScreen> {
  final _saleIdCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  List<_ReturnLineModel> _lines = [];
  bool _loading = false;

  ReturnsRepository get _repo => sl<ReturnsRepository>();

  Future<void> _load() async {
    final saleId = int.tryParse(_saleIdCtrl.text.trim());
    if (saleId == null) return;
    setState(() => _loading = true);
    try {
      final rows = await _repo.getReturnableItems(saleId);
      _lines = rows
          .map(
            (r) => _ReturnLineModel(
              saleItemId: r['sale_item_id'] as int,
              variantId: r['variant_id'] as int,
              remaining: r['remaining_qty'] as int,
              unitPrice: (r['price_per_unit'] as num).toDouble(),
            ),
          )
          .toList();
      setState(() {});
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final saleId = int.tryParse(_saleIdCtrl.text.trim());
    if (saleId == null) return;
    final items = <ReturnLineInput>[];
    for (final m in _lines) {
      if (m.qty > 0) {
        items.add(
          ReturnLineInput(
            saleItemId: m.saleItemId,
            variantId: m.variantId,
            quantity: m.qty,
            refundAmount: m.qty * m.unitPrice,
          ),
        );
      }
    }
    if (items.isEmpty) return;
    try {
      await _repo.createReturn(
        saleId: saleId,
        userId: 1,
        reason: _reasonCtrl.text.trim().isEmpty
            ? null
            : _reasonCtrl.text.trim(),
        items: items,
      );
      if (!mounted) return;
      if (!context.mounted) return;
      final ctx = context;
      showCupertinoDialog(
        context: ctx,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('تم'),
          content: const Text('تم تسجيل المرتجع'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('حسنًا'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted || !context.mounted) return;
      final friendly = SqlErrorHelper.toArabicMessage(e);
      await showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('خطأ'),
          content: Text(friendly),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('مرتجع بيع'),
        trailing: ActionButton(onPressed: _save, label: 'حفظ'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Text(
              'أدخل رقم الفاتورة ثم حمّل العناصر',
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _saleIdCtrl,
              placeholder: 'Sale ID',
              keyboardType: TextInputType.number,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              color: CupertinoColors.activeBlue,
              onPressed: _loading ? null : _load,
              child: _loading
                  ? const CupertinoActivityIndicator()
                  : const Text('تحميل العناصر'),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _reasonCtrl,
              placeholder: 'سبب المرتجع (اختياري)',
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),
            for (final m in _lines) _ReturnLineEditor(model: m),
          ],
        ),
      ),
    );
  }
}

class _ReturnLineModel {
  final int saleItemId;
  final int variantId;
  final int remaining;
  final double unitPrice;
  int qty = 0;
  _ReturnLineModel({
    required this.saleItemId,
    required this.variantId,
    required this.remaining,
    required this.unitPrice,
  });
}

class _ReturnLineEditor extends StatefulWidget {
  final _ReturnLineModel model;
  const _ReturnLineEditor({required this.model});

  @override
  State<_ReturnLineEditor> createState() => _ReturnLineEditorState();
}

class _ReturnLineEditorState extends State<_ReturnLineEditor> {
  @override
  Widget build(BuildContext context) {
    final m = widget.model;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGroupedBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'SaleItem ${m.saleItemId} - المتبقي: ${m.remaining} - السعر: ${money(context, m.unitPrice)}',
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.minus_circled),
                onPressed: () =>
                    setState(() => m.qty = m.qty > 0 ? m.qty - 1 : 0),
              ),
              Text('${m.qty}'),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.add_circled),
                onPressed: () => setState(
                  () => m.qty = m.qty < m.remaining ? m.qty + 1 : m.qty,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

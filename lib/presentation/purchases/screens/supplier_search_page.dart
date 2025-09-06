import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Tooltip;
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/supplier_repository.dart';
import 'package:clothes_pos/data/models/supplier.dart';
import 'package:clothes_pos/presentation/common/widgets/action_button.dart';

import 'package:clothes_pos/presentation/common/sql_error_helper.dart';

class SupplierSearchPage extends StatefulWidget {
  const SupplierSearchPage({super.key});
  @override
  State<SupplierSearchPage> createState() => _SupplierSearchPageState();
}

class _SupplierSearchPageState extends State<SupplierSearchPage> {
  final _repo = sl<SupplierRepository>();
  final _q = TextEditingController();
  bool _loading = false;
  List<Supplier> _results = [];

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final q = _q.text.trim();
      _results = q.isEmpty
          ? await _repo.listAll(limit: 50)
          : await _repo.search(q, limit: 50);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('اختيار المورد'),
        trailing: ActionButton(
          label: 'إضافة',
          leading: const Icon(CupertinoIcons.add, color: CupertinoColors.white),
          onPressed: () async {
            final nameCtrl = TextEditingController();
            final contactCtrl = TextEditingController();
            if (!context.mounted) return; // safety
            await showCupertinoDialog(
              context: context,
              builder: (ctx) => CupertinoAlertDialog(
                title: const Text('إضافة مورد'),
                content: Column(
                  children: [
                    SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(ctx).size.height * 0.6,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            CupertinoTextField(
                              controller: nameCtrl,
                              placeholder: 'اسم المورد',
                              textDirection: TextDirection.rtl,
                            ),
                            const SizedBox(height: 8),
                            CupertinoTextField(
                              controller: contactCtrl,
                              placeholder: 'بيانات التواصل (اختياري)',
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('إلغاء'),
                  ),
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      try {
                        final id = await _repo.create(
                          name,
                          contactInfo: contactCtrl.text.trim(),
                        );
                        if (!mounted || !ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        final created = Supplier(
                          id: id,
                          name: name,
                          contactInfo: contactCtrl.text.trim().isEmpty
                              ? null
                              : contactCtrl.text.trim(),
                        );
                        if (!context.mounted) return;
                        Navigator.of(context).pop<Supplier>(created);
                      } catch (e) {
                        if (!mounted || !ctx.mounted) return;
                        final friendly = SqlErrorHelper.toArabicMessage(e);
                        if (!ctx.mounted) return; // safety
                        await showCupertinoDialog(
                          context: ctx,
                          builder: (_) => CupertinoAlertDialog(
                            title: const Text('خطأ'),
                            content: Text(friendly),
                            actions: [
                              CupertinoDialogAction(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('إغلاق'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    child: const Text('حفظ'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: CupertinoSearchTextField(
                controller: _q,
                onSubmitted: (_) => _search(),
                onChanged: (_) => _search(),
                placeholder: 'اسم المورد',
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final s = _results[i];
                        return CupertinoListTile(
                          title: Tooltip(
                            message: 'ID ${s.id}',
                            child: Text(s.name),
                          ),
                          subtitle: const SizedBox.shrink(),
                          onTap: () => Navigator.of(context).pop<Supplier>(s),
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

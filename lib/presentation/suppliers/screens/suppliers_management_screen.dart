// ignore_for_file: use_build_context_synchronously
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/data/repositories/supplier_repository.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/presentation/common/widgets/app_buttons.dart';

class SuppliersManagementScreen extends StatefulWidget {
  const SuppliersManagementScreen({super.key});

  @override
  State<SuppliersManagementScreen> createState() =>
      _SuppliersManagementScreenState();
}

class _SuppliersManagementScreenState extends State<SuppliersManagementScreen> {
  final _supplierRepo = sl<SupplierRepository>();
  final _nameController = TextEditingController();
  List<dynamic> _suppliers = [];
  bool _loading = true;
  dynamic _editingSupplier;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _loading = true);
    try {
      final suppliers = await _supplierRepo.listAll();
      if (!mounted) return;
      setState(() {
        _suppliers = suppliers;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      final sc = context;
      if (!sc.mounted) return;
      showCupertinoDialog(
        context: sc,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('خطأ'),
          content: Text('فشل في تحميل الموردين: $e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('موافق'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showAddEditDialog([dynamic supplier]) async {
    _editingSupplier = supplier;
    _nameController.text = supplier?.name ?? '';

    return showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoPopupSurface(
        isSurfacePainted: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  supplier == null ? 'إضافة مورد جديد' : 'تعديل المورد',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: _nameController,
                  placeholder: 'اسم المورد',
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AppTextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppPrimaryButton(
                        onPressed: () => _saveSupplier(ctx),
                        child: Text(supplier == null ? 'إضافة' : 'حفظ'),
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

  Future<void> _saveSupplier(BuildContext dialogContext) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    try {
      if (_editingSupplier == null) {
        // إضافة مورد جديد
        await _supplierRepo.create(name);
      } else {
        // تعديل مورد موجود - سنحتاج لإضافة هذه الطريقة لاحقاً
        if (dialogContext.mounted) {
          showCupertinoDialog(
            context: dialogContext,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('عذراً'),
              content: const Text('ميزة التعديل غير متاحة حالياً'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('موافق'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (!dialogContext.mounted) return;
      // Defer pop to next microtask to avoid desktop re-entrancy issues
      Future.microtask(() {
        final nav = Navigator.of(dialogContext);
        if (nav.canPop()) nav.pop(true);
      }); // إرجاع true للإشارة إلى النجاح
      if (!mounted) return;
      _loadSuppliers();
      _nameController.clear();
    } catch (e) {
      if (dialogContext.mounted) {
        showCupertinoDialog(
          context: dialogContext,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('خطأ'),
            content: Text('فشل في حفظ المورد: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('موافق'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _deleteSupplier(dynamic supplier) async {
    final sc = context;
    final confirmed = await showCupertinoDialog<bool>(
      context: sc,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف المورد "${supplier.name}"؟'),
        actions: [
          CupertinoDialogAction(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('حذف'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // await _supplierRepo.delete(supplier.id); // ميزة الحذف غير متاحة حالياً
        if (sc.mounted) {
          showCupertinoDialog(
            context: sc,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('عذراً'),
              content: const Text('ميزة الحذف غير متاحة حالياً'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('موافق'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (sc.mounted) {
          showCupertinoDialog(
            context: sc,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('خطأ'),
              content: Text('فشل في حذف المورد: $e'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('موافق'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('إدارة الموردين'),
        trailing: AppIconButton(
          onPressed: () => _showAddEditDialog(),
          icon: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : _suppliers.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.building_2_fill,
                      size: 64,
                      color: context.colors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد موردين',
                      style: TextStyle(
                        fontSize: 18,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppPrimaryButton(
                      onPressed: () => _showAddEditDialog(),
                      child: const Text('إضافة مورد جديد'),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _suppliers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final supplier = _suppliers[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: CupertinoListTile(
                      title: Text(
                        supplier.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'معرف: ${supplier.id}',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.colors.textSecondary,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIconButton(
                            onPressed: () => _showAddEditDialog(supplier),
                            icon: Icon(
                              CupertinoIcons.pencil,
                              color: context.colors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppIconButton(
                            onPressed: () => _deleteSupplier(supplier),
                            icon: const Icon(
                              CupertinoIcons.delete,
                              color: CupertinoColors.systemRed,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

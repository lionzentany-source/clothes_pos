// ignore_for_file: use_build_context_synchronously
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/data/repositories/category_repository.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/presentation/common/widgets/app_buttons.dart';

class CategoriesManagementScreen extends StatefulWidget {
  const CategoriesManagementScreen({super.key});

  @override
  State<CategoriesManagementScreen> createState() =>
      _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState
    extends State<CategoriesManagementScreen> {
  final _categoryRepo = sl<CategoryRepository>();
  final _nameController = TextEditingController();
  List<dynamic> _categories = [];
  bool _loading = true;
  dynamic _editingCategory;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    try {
      final categories = await _categoryRepo.listAll();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      final sc = context; // capture context
      if (!sc.mounted) return;
      showCupertinoDialog(
        context: sc,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('خطأ'),
          content: Text('فشل في تحميل التصنيفات: $e'),
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

  Future<void> _showAddEditDialog([dynamic category]) async {
    _editingCategory = category;
    _nameController.text = category?.name ?? '';

    final c = context;
    return showCupertinoModalPopup(
      context: c,
      builder: (ctx) => CupertinoPopupSurface(
        isSurfacePainted: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category == null ? 'إضافة تصنيف جديد' : 'تعديل التصنيف',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: _nameController,
                  placeholder: 'اسم التصنيف',
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
                        onPressed: () => _saveCategory(ctx),
                        child: Text(category == null ? 'إضافة' : 'حفظ'),
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

  Future<void> _saveCategory(BuildContext dialogContext) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    try {
      if (_editingCategory == null) {
        // إضافة تصنيف جديد
        await _categoryRepo.create(name);
      } else {
        // تعديل تصنيف موجود - سنحتاج لإضافة هذه الطريقة لاحقاً
        // await _categoryRepo.update(
        //   id: _editingCategory.id,
        //   name: name,
        // );
        if (!dialogContext.mounted) return; // safety
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
        return;
      }

      if (!dialogContext.mounted) return;
      Future.microtask(() {
        final nav = Navigator.of(dialogContext);
        if (nav.canPop()) nav.pop(true);
      }); // إرجاع true للإشارة إلى النجاح
      if (!mounted) return;
      _loadCategories();
      _nameController.clear();
    } catch (e) {
      if (dialogContext.mounted) {
        showCupertinoDialog(
          context: dialogContext,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('خطأ'),
            content: Text('فشل في حفظ التصنيف: $e'),
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

  Future<void> _deleteCategory(dynamic category) async {
    final c = context;
    final confirmed = await showCupertinoDialog<bool>(
      context: c,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف تصنيف "${category.name}"؟'),
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
        // await _categoryRepo.delete(category.id); // ميزة الحذف غير متاحة حالياً
        if (!c.mounted) return;
        showCupertinoDialog(
          context: c,
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
      } catch (e) {
        if (c.mounted) {
          if (!c.mounted) return; // safety
          showCupertinoDialog(
            context: c,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('خطأ'),
              content: Text('فشل في حذف التصنيف: $e'),
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
        middle: const Text('إدارة التصنيفات'),
        trailing: AppIconButton(
          onPressed: () => _showAddEditDialog(),
          icon: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : _categories.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.tags,
                      size: 64,
                      color: context.colors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد تصنيفات',
                      style: TextStyle(
                        fontSize: 18,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppPrimaryButton(
                      onPressed: () => _showAddEditDialog(),
                      child: const Text('إضافة تصنيف جديد'),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: CupertinoListTile(
                      title: Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'معرف: ${category.id}',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.colors.textSecondary,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIconButton(
                            onPressed: () => _showAddEditDialog(category),
                            icon: Icon(
                              CupertinoIcons.pencil,
                              color: context.colors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppIconButton(
                            onPressed: () => _deleteCategory(category),
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

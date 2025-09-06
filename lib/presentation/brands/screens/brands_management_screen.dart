// ignore_for_file: use_build_context_synchronously
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/data/repositories/brand_repository.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/presentation/common/widgets/app_buttons.dart';

class BrandsManagementScreen extends StatefulWidget {
  const BrandsManagementScreen({super.key});

  @override
  State<BrandsManagementScreen> createState() => _BrandsManagementScreenState();
}

class _BrandsManagementScreenState extends State<BrandsManagementScreen> {
  final _brandRepo = sl<BrandRepository>();
  final _nameController = TextEditingController();
  List<dynamic> _brands = [];
  bool _loading = true;
  dynamic _editingBrand;

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    setState(() => _loading = true);
    try {
      final brands = await _brandRepo.listAll();
      if (!mounted) return;
      setState(() {
        _brands = brands;
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
          content: Text('فشل في تحميل العلامات التجارية: $e'),
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

  Future<void> _showAddEditDialog([dynamic brand]) async {
    _editingBrand = brand;
    _nameController.text = brand?.name ?? '';

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
                  brand == null
                      ? 'إضافة علامة تجارية جديدة'
                      : 'تعديل العلامة التجارية',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: _nameController,
                  placeholder: 'اسم العلامة التجارية',
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
                        onPressed: () => _saveBrand(ctx),
                        child: Text(brand == null ? 'إضافة' : 'حفظ'),
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

  Future<void> _saveBrand(BuildContext dialogContext) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    try {
      if (_editingBrand == null) {
        // إضافة علامة تجارية جديدة
        await _brandRepo.create(name);
      } else {
        // تعديل علامة تجارية موجودة - سنحتاج لإضافة هذه الطريقة لاحقاً
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
      _loadBrands();
      _nameController.clear();
    } catch (e) {
      if (dialogContext.mounted) {
        showCupertinoDialog(
          context: dialogContext,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('خطأ'),
            content: Text('فشل في حفظ العلامة التجارية: $e'),
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

  Future<void> _deleteBrand(dynamic brand) async {
    final c = context;
    final confirmed = await showCupertinoDialog<bool>(
      context: c,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف العلامة التجارية "${brand.name}"؟'),
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
        // await _brandRepo.delete(brand.id); // ميزة الحذف غير متاحة حالياً
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
          showCupertinoDialog(
            context: c,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('خطأ'),
              content: Text('فشل في حذف العلامة التجارية: $e'),
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
        middle: const Text('إدارة العلامات التجارية'),
        trailing: AppIconButton(
          onPressed: () => _showAddEditDialog(),
          icon: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : _brands.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.star_circle,
                      size: 64,
                      color: context.colors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد علامات تجارية',
                      style: TextStyle(
                        fontSize: 18,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppPrimaryButton(
                      onPressed: () => _showAddEditDialog(),
                      child: const Text('إضافة علامة تجارية جديدة'),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _brands.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final brand = _brands[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: CupertinoListTile(
                      title: Text(
                        brand.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'معرف: ${brand.id}',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.colors.textSecondary,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIconButton(
                            onPressed: () => _showAddEditDialog(brand),
                            icon: Icon(
                              CupertinoIcons.pencil,
                              color: context.colors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppIconButton(
                            onPressed: () => _deleteBrand(brand),
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

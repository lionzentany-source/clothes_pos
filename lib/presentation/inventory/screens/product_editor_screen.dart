import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/models/parent_product.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:clothes_pos/data/models/category.dart';
import 'package:clothes_pos/data/models/supplier.dart';
import 'package:clothes_pos/data/models/brand.dart';
import 'package:clothes_pos/data/repositories/product_repository.dart';
import 'package:clothes_pos/data/repositories/category_repository.dart';
import 'package:clothes_pos/data/repositories/supplier_repository.dart';
import 'package:clothes_pos/data/repositories/brand_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/common/widgets/app_labeled_field.dart';
import 'package:clothes_pos/presentation/common/sql_error_helper.dart';
import 'package:clothes_pos/presentation/common/widgets/action_button.dart';

class ProductEditorScreen extends StatefulWidget {
  final int? parentId; // null => create, otherwise edit existing
  const ProductEditorScreen({super.key, this.parentId});

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  Category? _selectedCategory;
  Supplier? _selectedSupplier;
  Brand? _selectedBrand;

  // Cached lists
  List<Category> _categories = [];
  List<Supplier> _suppliers = [];
  List<Brand> _brands = [];

  // size/color suggestions
  List<String> _sizeSuggestions = [];
  List<String> _colorSuggestions = [];

  final _variants = <_VariantEditModel>[];
  bool _loading = true;
  ParentProduct? _loadedParent;

  ProductRepository get _repo => sl<ProductRepository>();
  CategoryRepository get _categoryRepo => sl<CategoryRepository>();
  SupplierRepository get _supplierRepo => sl<SupplierRepository>();
  BrandRepository get _brandRepo => sl<BrandRepository>();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Load categories & suppliers
    final cats = await _categoryRepo.listAll(limit: 500);
    final sups = await _supplierRepo.listAll(limit: 500);
    final brs = await _brandRepo.listAll(limit: 500);

    // Distinct size/color suggestions from existing variants
    final distinctSizes = await _repo.distinctSizes(limit: 100);
    final distinctColors = await _repo.distinctColors(limit: 100);
    const seedSizes = ['S', 'M', 'L', 'XL', 'XXL'];
    const seedColors = ['أسود', 'أبيض', 'أزرق', 'أحمر', 'أخضر'];
    _sizeSuggestions = {
      ...seedSizes,
      ...distinctSizes.where((e) => e.trim().isNotEmpty),
    }.toList();
    _colorSuggestions = {
      ...seedColors,
      ...distinctColors.where((e) => e.trim().isNotEmpty),
    }.toList();

    if (widget.parentId != null) {
      final p = await _repo.getParentById(widget.parentId!);
      final vs = await _repo.getVariantsByParent(widget.parentId!);
      _loadedParent = p;
      _nameCtrl.text = p?.name ?? '';
      _descCtrl.text = p?.description ?? '';
      if (p != null) {
        _selectedCategory = cats.firstWhere(
          (c) => c.id == p.categoryId,
          orElse: () => const Category(id: null, name: ''),
        );
        _selectedSupplier = sups.firstWhere(
          (s) => s.id == p.supplierId,
          orElse: () => const Supplier(id: null, name: ''),
        );
        if (_selectedCategory?.id == null) {
          _selectedCategory = null; // fallback cleanup
        }
        if (_selectedSupplier?.id == null) {
          _selectedSupplier = null;
        }
        _selectedBrand = brs.firstWhere(
          (b) => b.id == p.brandId,
          orElse: () => const Brand(id: null, name: ''),
        );
        if (_selectedBrand?.id == null) {
          _selectedBrand = null;
        }
      }
      _variants
        ..clear()
        ..addAll(vs.map(_VariantEditModel.fromVariant));
    } else {
      _variants.add(_VariantEditModel.empty());
    }
    _categories = cats;
    _suppliers = sups;
    _brands = brs;
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showError('الاسم مطلوب');
      return;
    }
    final categoryId = _selectedCategory?.id;
    if (categoryId == null) {
      _showError('يجب اختيار الفئة');
      return;
    }
    final supplierId = _selectedSupplier?.id;
    final brandId = _selectedBrand?.id;

    // Build variants
    final builtVariants = <ProductVariant>[];
    for (final m in _variants) {
      final skuText = m.sku.text.trim();
      final sku = skuText.isEmpty ? null : skuText;
      final cost =
          double.tryParse(
            m.cost.text.trim() == '' ? '0' : m.cost.text.trim(),
          ) ??
          0;
      final sale =
          double.tryParse(
            m.sale.text.trim() == '' ? '0' : m.sale.text.trim(),
          ) ??
          0;
      final qty =
          int.tryParse(m.qty.text.trim() == '' ? '0' : m.qty.text.trim()) ?? 0;
      final reorder =
          int.tryParse(
            m.reorder.text.trim() == '' ? '0' : m.reorder.text.trim(),
          ) ??
          0;
      builtVariants.add(
        ProductVariant(
          id: m.id,
          parentProductId: widget.parentId ?? 0,
          size: m.size.text.trim().isEmpty ? null : m.size.text.trim(),
          color: m.color.text.trim().isEmpty ? null : m.color.text.trim(),
          sku: sku,
          barcode: m.barcode.text.trim().isEmpty ? null : m.barcode.text.trim(),
          rfidTag: null,
          costPrice: cost,
          salePrice: sale,
          reorderPoint: reorder,
          quantity: qty,
        ),
      );
    }

    final parent = ParentProduct(
      id: _loadedParent?.id,
      name: name,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      categoryId: categoryId,
      supplierId: supplierId,
      brandId: brandId,
      imagePath: _loadedParent?.imagePath,
    );

    try {
      if (widget.parentId == null) {
        await _repo.createWithVariants(parent, builtVariants);
      } else {
        await _repo.updateWithVariants(parent, builtVariants);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final friendly = SqlErrorHelper.toArabicMessage(e);
      _showError(friendly);
    }
  }

  void _addVariant() {
    setState(() => _variants.add(_VariantEditModel.empty()));
  }

  void _removeVariant(int index) {
    setState(() => _variants.removeAt(index));
  }

  void _showError(String msg) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (dialogCtx) => CupertinoAlertDialog(
        title: const Text('خطأ'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('حسنًا'),
            onPressed: () => Navigator.of(dialogCtx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('محرر المنتج')),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('محرر المنتج'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _save,
          child: const Text('حفظ'),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const _SectionTitle('بيانات المنتج'),
            AppLabeledField(
              label: 'الاسم',
              controller: _nameCtrl,
              placeholder: 'اسم المنتج',
            ),
            AppLabeledField(
              label: 'الوصف',
              controller: _descCtrl,
              placeholder: 'وصف (اختياري)',
            ),
            _PickerTile(
              label: 'الفئة',
              value: _selectedCategory?.name ?? 'اختر الفئة',
              onTap: _pickCategory,
            ),
            _PickerTile(
              label: 'المورد (اختياري)',
              value: _selectedSupplier?.name ?? 'اختر المورد',
              onTap: _pickSupplier,
            ),
            _PickerTile(
              label: 'العلامة التجارية (اختياري)',
              value: _selectedBrand?.name ?? 'اختر العلامة التجارية',
              onTap: _pickBrand,
            ),
            const _SectionTitle('المتغيرات (مقاس/لون/سعر/كمية)'),
            for (int i = 0; i < _variants.length; i++)
              _VariantEditor(
                model: _variants[i],
                onRemove: () => _removeVariant(i),
                onPickSize: () => _pickSize(_variants[i]),
                onPickColor: () => _pickColor(_variants[i]),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ActionButton(onPressed: _addVariant, label: 'إضافة متغير'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCategory() async {
    await _showSelectionSheet<Category>(
      title: 'اختر الفئة',
      items: _categories,
      getLabel: (c) => c.name,
      onAddNew: () async {
        final name = await _promptText('إضافة فئة جديدة', 'اسم الفئة');
        if (name != null && name.trim().isNotEmpty) {
          final id = await _categoryRepo.create(name.trim());
          final cat = Category(id: id, name: name.trim());
          setState(() {
            _categories = [..._categories, cat];
            _selectedCategory = cat;
          });
        }
      },
      onSelected: (c) => setState(() => _selectedCategory = c),
    );
  }

  Future<void> _pickSupplier() async {
    await _showSelectionSheet<Supplier>(
      title: 'اختر المورد',
      items: _suppliers,
      getLabel: (s) => s.name,
      onAddNew: () async {
        final name = await _promptText('إضافة مورد جديد', 'اسم المورد');
        if (name != null && name.trim().isNotEmpty) {
          final id = await _supplierRepo.create(name.trim());
          final supplier = Supplier(id: id, name: name.trim());
          setState(() {
            _suppliers = [..._suppliers, supplier];
            _selectedSupplier = supplier;
          });
        }
      },
      onSelected: (s) => setState(() => _selectedSupplier = s),
      allowClear: true,
      onClear: () => setState(() => _selectedSupplier = null),
    );
  }

  Future<void> _pickBrand() async {
    await _showSelectionSheet<Brand>(
      title: 'اختر العلامة التجارية',
      items: _brands,
      getLabel: (b) => b.name,
      onAddNew: () async {
        final name = await _promptText('إضافة علامة تجارية', 'اسم العلامة');
        if (name != null && name.trim().isNotEmpty) {
          final id = await _brandRepo.create(name.trim());
          final brand = Brand(id: id, name: name.trim());
          setState(() {
            _brands = [..._brands, brand];
            _selectedBrand = brand;
          });
        }
      },
      onSelected: (b) => setState(() => _selectedBrand = b),
      allowClear: true,
      onClear: () => setState(() => _selectedBrand = null),
    );
  }

  Future<void> _pickSize(_VariantEditModel model) async {
    await _showStringSheet(
      title: 'اختر المقاس',
      suggestions: _sizeSuggestions,
      current: model.size.text,
      onAddNew: () async {
        final v = await _promptText('إضافة مقاس', 'مثال: XXL');
        if (v != null && v.trim().isNotEmpty) {
          setState(() {
            if (!_sizeSuggestions.contains(v.trim())) {
              _sizeSuggestions = [..._sizeSuggestions, v.trim()];
            }
            model.size.text = v.trim();
          });
        }
      },
      onSelected: (s) => setState(() => model.size.text = s),
      allowClear: true,
      onClear: () => setState(() => model.size.clear()),
    );
  }

  Future<void> _pickColor(_VariantEditModel model) async {
    await _showStringSheet(
      title: 'اختر اللون',
      suggestions: _colorSuggestions,
      current: model.color.text,
      onAddNew: () async {
        final v = await _promptText('إضافة لون', 'مثال: بنفسجي');
        if (v != null && v.trim().isNotEmpty) {
          setState(() {
            if (!_colorSuggestions.contains(v.trim())) {
              _colorSuggestions = [..._colorSuggestions, v.trim()];
            }
            model.color.text = v.trim();
          });
        }
      },
      onSelected: (s) => setState(() => model.color.text = s),
      allowClear: true,
      onClear: () => setState(() => model.color.clear()),
    );
  }

  Future<String?> _promptText(String title, String placeholder) async {
    final ctrl = TextEditingController();
    return showCupertinoDialog<String?>(
      context: context,
      builder: (dialogCtx) {
        return CupertinoAlertDialog(
          title: Text(title, textDirection: TextDirection.rtl),
          content: Column(
            children: [
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: ctrl,
                placeholder: placeholder,
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(dialogCtx).pop(null),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('حفظ'),
              onPressed: () => Navigator.of(dialogCtx).pop(ctrl.text.trim()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showStringSheet({
    required String title,
    required List<String> suggestions,
    required String current,
    required VoidCallback onAddNew,
    required ValueChanged<String> onSelected,
    bool allowClear = false,
    VoidCallback? onClear,
  }) async {
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return _BottomSheetContainer(
          title: title,
          children: [
            if (allowClear)
              CupertinoButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onClear?.call();
                },
                child: const Text('مسح القيمة'),
              ),
            ...suggestions.map(
              (s) => CupertinoButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onSelected(s);
                },
                child: Text(s),
              ),
            ),
            CupertinoButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onAddNew();
              },
              child: const Text('إضافة جديد'),
            ),
            CupertinoButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSelectionSheet<T>({
    required String title,
    required List<T> items,
    required String Function(T) getLabel,
    required ValueChanged<T> onSelected,
    required Future<void> Function() onAddNew,
    bool allowClear = false,
    VoidCallback? onClear,
  }) async {
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _BottomSheetContainer(
        title: title,
        children: [
          if (allowClear)
            CupertinoButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onClear?.call();
              },
              child: const Text('مسح الاختيار'),
            ),
          ...items.map(
            (e) => CupertinoButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onSelected(e);
              },
              child: Text(getLabel(e)),
            ),
          ),
          CupertinoButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onAddNew();
            },
            child: const Text('إضافة جديد'),
          ),
          CupertinoButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

class _VariantEditModel {
  final int? id;
  final TextEditingController size;
  final TextEditingController color;
  final TextEditingController sku;
  final TextEditingController barcode;
  final TextEditingController cost;
  final TextEditingController sale;
  final TextEditingController qty;
  final TextEditingController reorder;

  _VariantEditModel({
    this.id,
    required this.size,
    required this.color,
    required this.sku,
    required this.barcode,
    required this.cost,
    required this.sale,
    required this.qty,
    required this.reorder,
  });

  factory _VariantEditModel.empty() => _VariantEditModel(
    id: null,
    size: TextEditingController(),
    color: TextEditingController(),
    sku: TextEditingController(),
    barcode: TextEditingController(),
    cost: TextEditingController(text: '0'),
    sale: TextEditingController(text: '0'),
    qty: TextEditingController(text: '0'),
    reorder: TextEditingController(text: '0'),
  );

  factory _VariantEditModel.fromVariant(ProductVariant v) => _VariantEditModel(
    id: v.id,
    size: TextEditingController(text: v.size ?? ''),
    color: TextEditingController(text: v.color ?? ''),
    sku: TextEditingController(text: v.sku ?? ''),
    barcode: TextEditingController(text: v.barcode ?? ''),
    cost: TextEditingController(text: v.costPrice.toString()),
    sale: TextEditingController(text: v.salePrice.toString()),
    qty: TextEditingController(text: v.quantity.toString()),
    reorder: TextEditingController(text: v.reorderPoint.toString()),
  );

  void dispose() {
    size.dispose();
    color.dispose();
    sku.dispose();
    barcode.dispose();
    cost.dispose();
    sale.dispose();
    qty.dispose();
    reorder.dispose();
  }
}

class _VariantEditor extends StatelessWidget {
  final _VariantEditModel model;
  final VoidCallback onRemove;
  final VoidCallback onPickSize;
  final VoidCallback onPickColor;
  const _VariantEditor({
    required this.model,
    required this.onRemove,
    required this.onPickSize,
    required this.onPickColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGroupedBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('متغير', textDirection: TextDirection.rtl),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onRemove,
                child: const Text('حذف'),
              ),
            ],
          ),
          _TwoFieldsRow(
            leftLabel: 'المقاس',
            left: model.size,
            rightLabel: 'اللون',
            right: model.color,
            leftTrailing: AppInlineIconButton(
              icon: CupertinoIcons.search,
              onTap: onPickSize,
            ),
            rightTrailing: AppInlineIconButton(
              icon: CupertinoIcons.search,
              onTap: onPickColor,
            ),
          ),
          _TwoFieldsRow(
            leftLabel: 'SKU',
            left: model.sku,
            rightLabel: 'Barcode',
            right: model.barcode,
            leftTrailing: AppInlineIconButton(
              icon: CupertinoIcons.barcode,
              onTap: () {},
            ),
          ),
          _TwoFieldsRow(
            leftLabel: 'التكلفة',
            left: model.cost,
            rightLabel: 'البيع',
            right: model.sale,
            keyboardType: TextInputType.number,
          ),
          _TwoFieldsRow(
            leftLabel: 'الكمية',
            left: model.qty,
            rightLabel: 'حد إعادة الطلب',
            right: model.reorder,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
}

class _TwoFieldsRow extends StatelessWidget {
  final String leftLabel;
  final TextEditingController left;
  final String rightLabel;
  final TextEditingController right;
  final TextInputType? keyboardType;
  final Widget? leftTrailing;
  final Widget? rightTrailing;
  const _TwoFieldsRow({
    required this.leftLabel,
    required this.left,
    required this.rightLabel,
    required this.right,
    this.keyboardType,
    this.leftTrailing,
    this.rightTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppLabeledField(
            label: leftLabel,
            controller: left,
            keyboardType: keyboardType,
            trailing: leftTrailing == null
                ? null
                : _InlineIconButton(child: leftTrailing!),
          ),
        ),
        Expanded(
          child: AppLabeledField(
            label: rightLabel,
            controller: right,
            keyboardType: keyboardType,
            trailing: rightTrailing == null
                ? null
                : _InlineIconButton(child: rightTrailing!),
          ),
        ),
      ],
    );
  }
}

// Wrap trailing button to shrink tap target & avoid layout overflow inside field
class _InlineIconButton extends StatelessWidget {
  final Widget child;
  const _InlineIconButton({required this.child});
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 0, minWidth: 0),
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontSize: 13),
        child: IconTheme.merge(
          data: const IconThemeData(size: 16),
          child: child,
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _PickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _CupertinoListTile(
      title: Text(label, textDirection: TextDirection.rtl),
      additionalInfo: Text(value, textDirection: TextDirection.rtl),
      onTap: onTap,
    );
  }
}

// Minimal CupertinoListTile substitute (avoid extra dependency if not already in project)
class _CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget? additionalInfo;
  final VoidCallback? onTap;
  const _CupertinoListTile({
    required this.title,
    this.additionalInfo,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Align(alignment: Alignment.centerRight, child: title),
            ),
            if (additionalInfo != null) ...[
              const SizedBox(width: 12),
              DefaultTextStyle(
                style: const TextStyle(color: CupertinoColors.inactiveGray),
                child: additionalInfo!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BottomSheetContainer extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _BottomSheetContainer({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12, bottom: 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/models/parent_product.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:clothes_pos/data/models/attribute.dart';
import 'package:clothes_pos/presentation/inventory/widgets/attribute_picker.dart';
import 'package:clothes_pos/presentation/attributes/screens/manage_attributes_screen.dart';
import 'package:clothes_pos/data/models/category.dart';
import 'package:clothes_pos/data/models/supplier.dart';
import 'package:clothes_pos/data/models/brand.dart';
import 'package:clothes_pos/data/repositories/product_repository.dart';
import 'package:clothes_pos/data/repositories/category_repository.dart';
import 'package:clothes_pos/data/repositories/supplier_repository.dart';
import 'package:clothes_pos/data/repositories/brand_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/attributes/bloc/attributes_cubit.dart';
import 'package:clothes_pos/core/config/feature_flags.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:clothes_pos/presentation/common/widgets/app_labeled_field.dart';
import 'package:clothes_pos/presentation/common/sql_error_helper.dart';
import 'package:clothes_pos/presentation/common/widgets/action_button.dart';

class ProductEditorScreen extends StatefulWidget {
  final int? parentId; // null => create, otherwise edit existing
  /// When true the screen will skip async init that touches repositories.
  /// Useful for widget tests that assert presence of UI elements without setting up DI.
  final bool skipInit;
  const ProductEditorScreen({super.key, this.parentId, this.skipInit = false});

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

  // Parent-level selected attributes (UI-only for now; persisted later)
  List<Attribute> _selectedParentAttributes = [];

  final _variants = <_VariantEditModel>[];
  bool _loading = true;
  ParentProduct? _loadedParent;
  String? _imagePath;

  ProductRepository get _repo => sl<ProductRepository>();
  CategoryRepository get _categoryRepo => sl<CategoryRepository>();
  SupplierRepository get _supplierRepo => sl<SupplierRepository>();
  BrandRepository get _brandRepo => sl<BrandRepository>();

  @override
  void initState() {
    super.initState();
    if (!widget.skipInit) {
      _init();
    } else {
      // Ensure minimal state for tests
      if (_variants.isEmpty) _variants.add(_VariantEditModel.empty());
      _loading = false;
    }
  }

  Future<void> _pickParentAttributes() async {
    try {
      final repo = sl<ProductRepository>();
      final attrs = await repo.getAllAttributes();
      final selectedIds = _selectedParentAttributes
          .map((a) => a.id)
          .whereType<int>()
          .toSet();

      await showCupertinoModalPopup(
        context: context,
        builder: (ctx) {
          return _BottomSheetContainer(
            title: 'اختر الخصائص التي تنطبق على المنتج الأب',
            children: [
              ...attrs.map((a) {
                final isSelected = selectedIds.contains(a.id);
                return CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  onPressed: () {
                    if (a.id == null) return;
                    // Apply selection immediately and close the sheet
                    setState(() {
                      final already = _selectedParentAttributes.any(
                        (s) => s.id == a.id,
                      );
                      if (already) {
                        _selectedParentAttributes.removeWhere(
                          (s) => s.id == a.id,
                        );
                      } else {
                        _selectedParentAttributes = [
                          ..._selectedParentAttributes,
                          a,
                        ];
                      }
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(a.name),
                      if (isSelected)
                        const Icon(CupertinoIcons.check_mark)
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 12),
              CupertinoButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // Open ManageAttributesScreen after closing sheet to avoid
                  // showing a route from the sheet context.
                  Future.microtask(() {
                    if (!mounted) return;
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => BlocProvider<AttributesCubit>(
                          create: (_) =>
                              sl<AttributesCubit>()..loadAttributes(),
                          child: const ManageAttributesScreen(),
                        ),
                      ),
                    );
                  });
                },
                child: const Text('إدارة/إضافة خاصية'),
              ),
              CupertinoButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إلغاء'),
              ),
            ],
          );
        },
      );
    } catch (_) {
      // ignore failures in tests
    }
  }

  Future<void> _init() async {
    debugPrint('[ProductEditorScreen._init] start');
    // Load categories & suppliers
    final cats = await _categoryRepo.listAll(limit: 500);
    debugPrint('[ProductEditorScreen._init] loaded categories=${cats.length}');
    final sups = await _supplierRepo.listAll(limit: 500);
    debugPrint('[ProductEditorScreen._init] loaded suppliers=${sups.length}');
    final brs = await _brandRepo.listAll(limit: 500);
    debugPrint('[ProductEditorScreen._init] loaded brands=${brs.length}');

    // Distinct size/color suggestions from existing variants
    final distinctSizes = await _repo.distinctSizes(limit: 100);
    final distinctColors = await _repo.distinctColors(limit: 100);
    const seedSizes = ['S', 'M', 'L', 'XL', 'XXL'];
    const seedColors = [
      'أسود',
      'أبيض',
      'أزرق',
      'أحمر',
      'أخضر',
      'أصفر',
      'برتقالي',
      'بنفسجي',
      'وردي',
      'بني',
      'رمادي',
      'سماوي',
    ];
    _sizeSuggestions = {
      ...seedSizes,
      ...distinctSizes.where((e) => e.trim().isNotEmpty),
    }.toList();
    _colorSuggestions = {
      ...seedColors,
      ...distinctColors.where((e) => e.trim().isNotEmpty),
    }.toList();
    debugPrint(
      '[ProductEditorScreen._init] sizes=${_sizeSuggestions.length} colors=${_colorSuggestions.length}',
    );

    if (widget.parentId != null) {
      debugPrint('[ProductEditorScreen._init] parentId=${widget.parentId}');
      Map<String, Object?>? parentWithAttrs;
      if (FeatureFlags.useDynamicAttributes) {
        debugPrint(
          '[ProductEditorScreen._init] feature dynamic attrs ON - fetching parentWithAttrs',
        );
        parentWithAttrs = await _repo.getParentWithAttributes(widget.parentId!);
        debugPrint(
          '[ProductEditorScreen._init] parentWithAttrs fetched: ${parentWithAttrs.isNotEmpty}',
        );
      }
      debugPrint('[ProductEditorScreen._init] fetching parent and variants');
      final p = parentWithAttrs != null && parentWithAttrs.isNotEmpty
          ? parentWithAttrs['parent'] as ParentProduct
          : await _repo.getParentById(widget.parentId!);
      debugPrint('[ProductEditorScreen._init] parent loaded: ${p?.id}');
      final vs = await _repo.getVariantsByParent(widget.parentId!);
      debugPrint('[ProductEditorScreen._init] variants count=${vs.length}');
      _loadedParent = p;
      _nameCtrl.text = p?.name ?? '';
      _descCtrl.text = p?.description ?? '';
      _imagePath = p?.imagePath;
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
        if (parentWithAttrs != null && parentWithAttrs.isNotEmpty) {
          final raw = (parentWithAttrs['attributes'] as List)
              .cast<Map<String, Object?>>();
          _selectedParentAttributes = raw
              .map((r) => Attribute.fromMap(r))
              .toList();
        }
      }
      _variants
        ..clear()
        ..addAll(vs.map(_VariantEditModel.fromVariant));
    }
    // دائماً أضف متغير واحد إذا كانت القائمة فارغة
    if (_variants.isEmpty) {
      _variants.add(_VariantEditModel.empty());
    }
    _categories = cats;
    _suppliers = sups;
    _brands = brs;
    // اختيار الفئة الأولى تلقائيًا إذا لم يتم اختيار فئة مسبقًا
    if (_selectedCategory == null && _categories.isNotEmpty) {
      _selectedCategory = _categories.first;
    }
    debugPrint('[ProductEditorScreen._init] finished, setting _loading=false');
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
    // تحقق من الكمية السالبة أولاً
    for (final m in _variants) {
      final qty =
          int.tryParse(m.qty.text.trim() == '' ? '0' : m.qty.text.trim()) ?? 0;
      debugPrint(
        '[ProductEditorScreen._save] تحقق الكمية: ${m.qty.text} => $qty',
      );
      if (qty < 0) {
        debugPrint(
          '[ProductEditorScreen._save] الكمية سالبة، سيتم عرض رسالة خطأ',
        );
        _showError('الكمية يجب أن تكون موجبة');
        return;
      }
    }
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
          size: FeatureFlags.useDynamicAttributes
              ? null
              : (m.size.text.trim().isEmpty ? null : m.size.text.trim()),
          color: FeatureFlags.useDynamicAttributes
              ? null
              : (m.color.text.trim().isEmpty ? null : m.color.text.trim()),
          sku: sku,
          barcode: m.barcode.text.trim().isEmpty ? null : m.barcode.text.trim(),
          rfidTag: null,
          costPrice: cost,
          salePrice: sale,
          reorderPoint: reorder,
          quantity: qty,
          imagePath: m.imagePath,
          attributes: FeatureFlags.useDynamicAttributes ? m.attributes : null,
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
      imagePath: _imagePath,
    );

    try {
      final parentAttrs = FeatureFlags.useDynamicAttributes
          ? (_selectedParentAttributes.isEmpty
                ? null
                : _selectedParentAttributes)
          : null;
      if (widget.parentId == null) {
        await _repo.createWithVariants(parent, builtVariants, parentAttrs);
      } else {
        await _repo.updateWithVariants(parent, builtVariants, parentAttrs);
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
    debugPrint('[_showError] سيتم عرض مربع حوار بالرسالة: $msg');
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text(
          'تنبيه إدخال غير صحيح',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg,
                  style: const TextStyle(
                    color: Color(0xFFD32F2F),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                if (msg.contains('كمية'))
                  const Text(
                    'يرجى إدخال كمية موجبة فقط. مثال: 5 أو 10',
                    style: TextStyle(fontSize: 14),
                  ),
                if (msg.contains('الاسم'))
                  const Text(
                    'اسم المنتج مطلوب ولا يمكن تركه فارغًا.',
                    style: TextStyle(fontSize: 14),
                  ),
                if (msg.contains('فئة'))
                  const Text(
                    'يرجى اختيار فئة للمنتج قبل الحفظ.',
                    style: TextStyle(fontSize: 14),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('موافق'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _imagePath = picked.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[ProductEditorScreen.build] _loading=$_loading');
    if (_loading) {
      debugPrint(
        '[ProductEditorScreen.build] في حالة التحميل، لن يتم عرض ActionButton',
      );
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('محرر المنتج')),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    // عد أزرار ActionButton
    WidgetsBinding.instance.addPostFrameCallback((_) {
      int count = 0;
      void countActionButtons(Element element) {
        if (element.widget is ActionButton) count++;
        element.visitChildElements(countActionButtons);
      }

      if (context is Element) {
        countActionButtons(context);
      }
      debugPrint(
        '[ProductEditorScreen.build] عدد أزرار ActionButton في الشجرة: $count',
      );
    });
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      AppLabeledField(
                        label: 'الا سم',
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
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 110,
                            height: 110,
                            color: CupertinoColors.systemGrey5,
                            child: _imagePath != null
                                ? Image.file(
                                    File(_imagePath!),
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    CupertinoIcons.photo,
                                    size: 48,
                                    color: CupertinoColors.inactiveGray,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _pickImage,
                        child: const Text('رفع صورة المنتج'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const _SectionTitle('المتغيرات (مقاس/لون/سعر/كمية)'),
            // When dynamic attributes are enabled, show a shortcut to manage them
            if (FeatureFlags.useDynamicAttributes)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ActionButton(
                  key: const Key('manage-attributes-button'),
                  onPressed: () async {
                    // Open ManageAttributesScreen in a dialog-free route; tests can stub navigation.
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => BlocProvider<AttributesCubit>(
                          create: (_) =>
                              sl<AttributesCubit>()..loadAttributes(),
                          child: const ManageAttributesScreen(),
                        ),
                      ),
                    );
                  },
                  label: 'إدارة الخصائص',
                ),
              ),
            // Parent-level attribute selector (new)
            if (FeatureFlags.useDynamicAttributes)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ActionButton(
                      key: const Key('pick-parent-attributes-button'),
                      onPressed: _pickParentAttributes,
                      label: 'اختيار خصائص المنتج الأب',
                    ),
                    const SizedBox(height: 8),
                    // Display selected attributes as chips with delete affordance
                    if (_selectedParentAttributes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 6.0,
                          children: _selectedParentAttributes.map((a) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey5,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(a.name),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedParentAttributes.removeWhere(
                                          (s) => s.id == a.id,
                                        );
                                      });
                                    },
                                    child: Icon(
                                      CupertinoIcons.delete,
                                      size: 16,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            for (int i = 0; i < _variants.length; i++)
              _VariantEditor(
                model: _variants[i],
                parentAttributes: _selectedParentAttributes,
                onRemove: () => _removeVariant(i),
                onPickSize: () => _pickSize(_variants[i]),
                onPickColor: () => _pickColor(_variants[i]),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ActionButton(
                key: const Key('add-variant-button'),
                onPressed: _addVariant,
                label: 'إضافة متغير',
              ),
            ),
          ],
        ),
      ),
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

  Future<void> _pickCategory() async {
    await _showSelectionSheet<Category>(
      title: 'اختر الفئة',
      items: _categories,
      getLabel: (c) => c.name,
      onSelected: (c) => setState(() => _selectedCategory = c),
      onAddNew: () async {},
    );
  }

  Future<void> _pickSupplier() async {
    await _showSelectionSheet<Supplier>(
      title: 'اختر المورد',
      items: _suppliers,
      getLabel: (s) => s.name,
      onSelected: (s) => setState(() => _selectedSupplier = s),
      onAddNew: () async {},
    );
  }

  Future<void> _pickBrand() async {
    await _showSelectionSheet<Brand>(
      title: 'اختر العلامة التجارية',
      items: _brands,
      getLabel: (b) => b.name,
      onSelected: (b) => setState(() => _selectedBrand = b),
      onAddNew: () async {},
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
  String? imagePath;
  List<AttributeValue>? attributes;

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
    this.imagePath,
    this.attributes,
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
    imagePath: null,
    attributes: null,
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
    imagePath: v.imagePath,
    attributes: v.attributes,
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
  final List<Attribute> parentAttributes;
  final VoidCallback onRemove;
  final VoidCallback onPickSize;
  final VoidCallback onPickColor;
  const _VariantEditor({
    required this.model,
    required this.parentAttributes,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
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
                if (!FeatureFlags.useDynamicAttributes)
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
                const SizedBox(height: 8),
                // سعر البيع (غير قابل للتعديل من شاشة المنتج)
                AppLabeledField(
                  label: 'سعر البيع',
                  controller: model.sale,
                  placeholder: 'مثال: 20.0',
                ),
                const SizedBox(height: 8),
                // Attributes button (dynamic attributes feature)
                if (FeatureFlags.useDynamicAttributes)
                  _DynamicAttributesDisplay(model: model),
                if (FeatureFlags.useDynamicAttributes)
                  // Only allow picking attribute values when parent attributes are defined
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: parentAttributes.isEmpty
                        ? null
                        : () async {
                            try {
                              final repo = sl<ProductRepository>();
                              // Load only the parent attributes and their values
                              await showCupertinoModalPopup(
                                context: context,
                                builder: (ctx) {
                                  return AttributePicker(
                                    loadAttributes: () async =>
                                        parentAttributes,
                                    loadAttributeValues: (id) =>
                                        repo.getAttributeValues(id),
                                    initialSelected: model.attributes,
                                    onDone: (sel) {
                                      model.attributes = sel;
                                      Navigator.of(ctx).pop();
                                      (context as Element).markNeedsBuild();
                                    },
                                  );
                                },
                              );
                            } catch (_) {
                              showCupertinoDialog(
                                context: context,
                                builder: (dCtx) => CupertinoAlertDialog(
                                  title: const Text('لا توجد بيانات'),
                                  content: const Text(
                                    'لا تتوفر مستودعات الخصائص في بيئة الاختبار.',
                                  ),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text('موافق'),
                                      onPressed: () => Navigator.of(dCtx).pop(),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                    child: parentAttributes.isEmpty
                        ? const Text('لا توجد خصائص معرفة للمنتج الأب')
                        : const Text('إعداد قيم الخصائص'),
                  ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Column(
            children: [
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (picked != null) {
                    model.imagePath = picked.path;
                    (context as Element).markNeedsBuild();
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: CupertinoColors.systemGrey5,
                    child: model.imagePath != null
                        ? Image.file(File(model.imagePath!), fit: BoxFit.cover)
                        : Icon(
                            CupertinoIcons.photo,
                            size: 32,
                            color: CupertinoColors.inactiveGray,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text(
                  'رفع صورة المتغير',
                  style: TextStyle(fontSize: 13),
                ),
                onPressed: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (picked != null) {
                    model.imagePath = picked.path;
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DynamicAttributesDisplay extends StatelessWidget {
  final _VariantEditModel model;

  const _DynamicAttributesDisplay({required this.model});

  @override
  Widget build(BuildContext context) {
    if (model.attributes == null || model.attributes!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: model.attributes!.map((attr) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(attr.value),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    // remove this attribute value from the model and refresh
                    model.attributes?.removeWhere((a) => a.id == attr.id);
                    try {
                      (context as Element).markNeedsBuild();
                    } catch (_) {}
                  },
                  child: Icon(
                    CupertinoIcons.clear_circled_solid,
                    size: 16,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TwoFieldsRow extends StatelessWidget {
  final String leftLabel;
  final TextEditingController left;
  final String rightLabel;
  final TextEditingController right;
  // Removed unused keyboardType parameter
  final Widget? leftTrailing;
  final Widget? rightTrailing;
  const _TwoFieldsRow({
    required this.leftLabel,
    required this.left,
    required this.rightLabel,
    required this.right,
    // Removed unused keyboardType parameter
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
            trailing: leftTrailing == null
                ? null
                : _InlineIconButton(child: leftTrailing!),
          ),
        ),
        Expanded(
          child: AppLabeledField(
            label: rightLabel,
            controller: right,
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
        child: SingleChildScrollView(
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
      ),
    );
  }
}

// placeholder removed - real ManageAttributesScreen is used by navigation

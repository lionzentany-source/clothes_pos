// ignore_for_file: use_build_context_synchronously
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/pos/screens/advanced_product_search_screen.dart';
import 'package:flutter/material.dart' show Tooltip;
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/models/parent_product.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:clothes_pos/data/repositories/product_repository.dart';
import 'package:clothes_pos/presentation/common/widgets/variant_attributes_display.dart';
import 'package:clothes_pos/core/config/feature_flags.dart';
import 'package:clothes_pos/data/models/attribute.dart';

class ParentSearchPage extends StatefulWidget {
  const ParentSearchPage({super.key});

  @override
  State<ParentSearchPage> createState() => _ParentSearchPageState();
}

class _ParentSearchPageState extends State<ParentSearchPage> {
  final _repo = sl<ProductRepository>();
  final _q = TextEditingController();
  bool _loading = false;
  List<ParentProduct> _results = [];

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      _results = await _repo.searchParentsByName(_q.text.trim(), limit: 50);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _openParentVariants(ParentProduct p) async {
    // Fetch variants and show a simple chooser
    final c = context; // capture
    final nav = Navigator.of(c);
    final vs = await _repo.getVariantsByParent(p.id!);
    if (!c.mounted) return;
    final selected = await showCupertinoModalPopup<ProductVariant?>(
      context: c,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: vs.isEmpty
                    ? Center(child: Text('لا يوجد متغيرات للمنتج'))
                    : ListView.builder(
                        itemCount: vs.length,
                        itemBuilder: (ctx, i) {
                          final v = vs[i];
                          return CupertinoButton(
                            padding: const EdgeInsets.all(12),
                            onPressed: () => Navigator.of(ctx).pop(v),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    v.sku?.isNotEmpty == true
                                        ? v.sku!
                                        : (v.color?.isNotEmpty == true
                                              ? v.color!
                                              : (v.size?.isNotEmpty == true
                                                    ? v.size!
                                                    : 'Variant')),
                                  ),
                                ),
                                VariantAttributesDisplay(
                                  attributes: v.attributes,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              CupertinoButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        );
      },
    );

    if (!c.mounted) return;
    if (selected != null) {
      nav.pop<ProductVariant>(selected);
    }
  }

  Future<void> _createVariantForParent(ParentProduct p) async {
    final c = context; // capture
    final nav = Navigator.of(c);
    // Show modal to collect inputs and optional attribute values
    final skuCtrl = TextEditingController();
    final costCtrl = TextEditingController(text: '0');
    final saleCtrl = TextEditingController(text: '0');
    final qtyCtrl = TextEditingController(text: '0');

    // Load parent attributes if dynamic attributes enabled
    List<Attribute> parentAttrs = [];
    if (FeatureFlags.useDynamicAttributes) {
      try {
        final m = await _repo.getParentWithAttributes(p.id!);
        if (m.isNotEmpty) {
          final raw = (m['attributes'] as List<dynamic>);
          if (raw.isNotEmpty && raw.first is Attribute) {
            parentAttrs = raw.cast<Attribute>().toList();
          } else {
            parentAttrs = raw
                .cast<Map<String, Object?>>()
                .map((r) => Attribute.fromMap(r))
                .toList();
          }
        }
      } catch (_) {}
    }

    // Debug trace: help diagnose why attributes section may be empty at runtime
    debugPrint(
      '[ParentSearchPage._createVariantForParent] useDynamic=${FeatureFlags.useDynamicAttributes} parentAttrs.count=${parentAttrs.length} for parentId=${p.id}',
    );

    // If the parent has no assigned attributes, do NOT show all attributes
    // (to avoid mixing parent and variant attributes). Instead show a clear
    // message in the modal instructing the user to assign attributes on the
    // parent product editor.

    final Map<int, AttributeValue?> selectedValues = {};

    if (!c.mounted) return;
    final created = await showCupertinoModalPopup<ProductVariant?>(
      context: c,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sctx, setModalState) {
            return Container(
              height: MediaQuery.of(sctx).size.height * 0.8,
              decoration: const BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    'إنشاء متغير للمنتج ${p.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SKU',
                        style: TextStyle(color: CupertinoColors.inactiveGray),
                      ),
                      CupertinoTextField(
                        controller: skuCtrl,
                        placeholder: '(اختياري) SKU',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'التكلفة',
                        style: TextStyle(color: CupertinoColors.inactiveGray),
                      ),
                      CupertinoTextField(
                        controller: costCtrl,
                        placeholder: 'التكلفة',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'سعر البيع',
                        style: TextStyle(color: CupertinoColors.inactiveGray),
                      ),
                      CupertinoTextField(
                        controller: saleCtrl,
                        placeholder: 'سعر البيع',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'الكمية الافتراضية',
                        style: TextStyle(color: CupertinoColors.inactiveGray),
                      ),
                      CupertinoTextField(
                        controller: qtyCtrl,
                        placeholder: 'الكمية الافتراضية',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Selected attribute-value chips
                  if (selectedValues.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: selectedValues.entries.map((e) {
                          final aid = e.key;
                          final val = e.value;
                          final attr = parentAttrs.firstWhere(
                            (a) => a.id == aid,
                            orElse: () => Attribute(id: aid, name: ''),
                          );
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${attr.name}: ${val?.value ?? ''}'),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => setModalState(
                                    () => selectedValues.remove(aid),
                                  ),
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
                    ),
                  if (FeatureFlags.useDynamicAttributes)
                    if (parentAttrs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Column(
                          children: [
                            Text(
                              'لا توجد خصائص معرفة لهذا المنتج الأب. انتقل إلى صفحة تحرير المنتج لإضافة خصائص الأب.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: CupertinoColors.inactiveGray,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            const SizedBox(height: 8),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () async {
                                // Try reloading attributes on demand
                                try {
                                  final m = await _repo.getParentWithAttributes(
                                    p.id!,
                                  );
                                  if (m.isNotEmpty) {
                                    final raw =
                                        (m['attributes'] as List<dynamic>);
                                    List<Attribute> loaded;
                                    if (raw.isNotEmpty &&
                                        raw.first is Attribute) {
                                      loaded = raw.cast<Attribute>().toList();
                                    } else {
                                      loaded = raw
                                          .cast<Map<String, Object?>>()
                                          .map((r) => Attribute.fromMap(r))
                                          .toList();
                                    }
                                    setModalState(() {
                                      parentAttrs = loaded;
                                    });
                                  } else {
                                    debugPrint(
                                      '[ParentSearchPage] retry load: no parent_attributes rows for parent ${p.id}',
                                    );
                                  }
                                } catch (e) {
                                  debugPrint(
                                    '[ParentSearchPage] retry load attributes failed: $e',
                                  );
                                }
                              },
                              child: const Text('تحميل خصائص الأب'),
                            ),
                          ],
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: parentAttrs.length,
                          itemBuilder: (c, idx) {
                            final attr = parentAttrs[idx];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(attr.name),
                                const SizedBox(height: 6),
                                FutureBuilder<List<AttributeValue>>(
                                  future: _repo.getAttributeValues(attr.id!),
                                  builder: (ctx2, snap) {
                                    if (!snap.hasData) {
                                      return const CupertinoActivityIndicator();
                                    }
                                    final vals = snap.data!;
                                    return CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        if (!sctx.mounted) return;
                                        final sel =
                                            await showCupertinoModalPopup<
                                              AttributeValue?
                                            >(
                                              context: sctx,
                                              builder: (c2) => Container(
                                                height: 300,
                                                decoration: const BoxDecoration(
                                                  color: CupertinoColors
                                                      .systemBackground,
                                                  borderRadius:
                                                      BorderRadius.vertical(
                                                        top: Radius.circular(
                                                          16,
                                                        ),
                                                      ),
                                                ),
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      'اختر قيمة ${attr.name}',
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Expanded(
                                                      child: ListView.builder(
                                                        itemCount: vals.length,
                                                        itemBuilder: (c, i) =>
                                                            CupertinoButton(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    12,
                                                                  ),
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                    c,
                                                                  ).pop(
                                                                    vals[i],
                                                                  ),
                                                              child: Text(
                                                                vals[i].value,
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                    CupertinoButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            c2,
                                                          ).pop(null),
                                                      child: const Text(
                                                        'إلغاء',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                        if (sel != null) {
                                          setModalState(
                                            () =>
                                                selectedValues[attr.id!] = sel,
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.systemGrey6,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          selectedValues[attr.id!]?.value ??
                                              'اختر قيمة ${attr.name}',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                              ],
                            );
                          },
                        ),
                      ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CupertinoButton(
                        onPressed: () => Navigator.of(ctx).pop(null),
                        child: const Text('إلغاء'),
                      ),
                      CupertinoButton(
                        onPressed: () async {
                          final attrsList = selectedValues.values
                              .whereType<AttributeValue>()
                              .toList();
                          final v = ProductVariant(
                            parentProductId: p.id!,
                            sku: skuCtrl.text.trim().isEmpty
                                ? null
                                : skuCtrl.text.trim(),
                            costPrice:
                                double.tryParse(costCtrl.text.trim()) ?? 0.0,
                            salePrice:
                                double.tryParse(saleCtrl.text.trim()) ?? 0.0,
                            quantity: int.tryParse(qtyCtrl.text.trim()) ?? 0,
                            attributes: attrsList.isEmpty ? null : attrsList,
                          );
                          try {
                            final id = await _repo.addVariant(v);
                            final inserted = v.copyWith(id: id);
                            Navigator.of(ctx).pop(inserted);
                          } catch (_) {
                            Navigator.of(ctx).pop(null);
                          }
                        },
                        child: const Text('إنشاء'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!c.mounted) return;
    if (created != null) {
      nav.pop<ProductVariant>(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('بحث عن المنتج الأب'),
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
                placeholder: 'اسم المنتج الأب',
                prefixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => AdvancedProductSearchScreen.open(context),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          CupertinoIcons.slider_horizontal_3,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(CupertinoIcons.search, size: 18),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (ctx, i) {
                        final p = _results[i];
                        return CupertinoListTile(
                          title: Tooltip(
                            message: 'ID ${p.id}',
                            child: Text(p.name),
                          ),
                          subtitle: const SizedBox.shrink(),
                          onTap: () => _openParentVariants(p),
                          trailing: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => _createVariantForParent(p),
                            child: const Text('إنشاء متغير'),
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

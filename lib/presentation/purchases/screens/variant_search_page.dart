import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/pos/screens/advanced_product_search_screen.dart';
import 'package:flutter/material.dart' show Tooltip;
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/product_repository.dart';
import 'package:clothes_pos/data/repositories/category_repository.dart';
import 'package:clothes_pos/data/models/category.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:clothes_pos/presentation/common/widgets/variant_attributes_display.dart';

class VariantSearchPage extends StatefulWidget {
  const VariantSearchPage({super.key});
  @override
  State<VariantSearchPage> createState() => _VariantSearchPageState();
}

class _VariantSearchPageState extends State<VariantSearchPage> {
  Future<String> getFullVariantName(ProductVariant v) async {
    final sku = v.sku ?? '';
    final size = v.size ?? '';
    final color = v.color ?? '';
    String parentName = '';
    try {
      final parent = await _repo.getParentById(v.parentProductId);
      parentName = parent?.name ?? '';
    } catch (_) {}
    List<String> parts = [];
    if (parentName.isNotEmpty) parts.add(parentName);
    if (color.isNotEmpty) parts.add(color);
    if (size.isNotEmpty) parts.add(size);
    if (sku.isNotEmpty) parts.add('[$sku]');
    return parts.join(' ');
  }

  final _repo = sl<ProductRepository>();
  final _q = TextEditingController();
  List<Category> _cats = [];
  int? _selectedCat;

  bool _loading = false;
  List<ProductVariant> _results = [];
  final Map<int, String> _parentNamesCache = {};

  Future<void> _loadCats() async {
    _cats = await sl<CategoryRepository>().listAll(limit: 200);
    if (mounted) setState(() {});
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      _results = await _repo.searchVariants(
        name: _q.text.trim().isEmpty ? null : _q.text.trim(),
        categoryId: _selectedCat,
        limit: 30,
      );
      // Prefetch parent names for all variants
      for (final v in _results) {
        if (!_parentNamesCache.containsKey(v.parentProductId)) {
          final parent = await _repo.getParentById(v.parentProductId);
          _parentNamesCache[v.parentProductId] = parent?.name ?? '';
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCats();
    _search();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('بحث عن متغير')),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoSearchTextField(
                      controller: _q,
                      onSubmitted: (_) => _search(),
                      onChanged: (_) => _search(),
                      placeholder: 'اسم/باركود/ SKU',
                      prefixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                AdvancedProductSearchScreen.open(context),
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
                ],
              ),
            ),
            if (_cats.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (ctx, i) {
                    final c = _cats[i];
                    final selected = _selectedCat == c.id;
                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      color: selected
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey6,
                      onPressed: () async {
                        setState(() => _selectedCat = selected ? null : c.id);
                        await _search();
                      },
                      child: Text(
                        c.name,
                        style: TextStyle(
                          color: selected
                              ? CupertinoColors.white
                              : CupertinoColors.label,
                          fontSize: 13,
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemCount: _cats.length,
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : LayoutBuilder(
                      builder: (ctx, constraints) {
                        final isWide = constraints.maxWidth >= 700;
                        if (!isWide) {
                          return ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (context, i) {
                              final v = _results[i];
                              final parentName =
                                  _parentNamesCache[v.parentProductId] ?? '';
                              final sku = v.sku ?? '';
                              final size = v.size ?? '';
                              final color = v.color ?? '';
                              List<String> parts = [];
                              if (parentName.isNotEmpty) parts.add(parentName);
                              if (color.isNotEmpty) parts.add(color);
                              if (size.isNotEmpty) parts.add(size);
                              if (sku.isNotEmpty) parts.add('[$sku]');
                              final fullName = parts.join(' ');
                              return CupertinoListTile(
                                title: Tooltip(
                                  message: 'ID ${v.id}',
                                  child: Text(fullName),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    VariantAttributesDisplay(
                                      attributes: v.attributes,
                                    ),
                                  ],
                                ),
                                onTap: () => Navigator.of(
                                  context,
                                ).pop<ProductVariant>(v),
                              );
                            },
                          );
                        }
                        final crossAxisCount = (constraints.maxWidth / 220)
                            .floor()
                            .clamp(2, 6);
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 2.8,
                              ),
                          itemCount: _results.length,
                          itemBuilder: (context, i) {
                            final v = _results[i];
                            final parentName =
                                _parentNamesCache[v.parentProductId] ?? '';
                            final sku = v.sku ?? '';
                            final size = v.size ?? '';
                            final color = v.color ?? '';
                            List<String> parts = [];
                            if (parentName.isNotEmpty) parts.add(parentName);
                            if (color.isNotEmpty) parts.add(color);
                            if (size.isNotEmpty) parts.add(size);
                            if (sku.isNotEmpty) parts.add('[$sku]');
                            final fullName = parts.join(' ');
                            return CupertinoButton(
                              padding: const EdgeInsets.all(12),
                              onPressed: () =>
                                  Navigator.of(context).pop<ProductVariant>(v),
                              color: CupertinoColors.systemGrey6,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Tooltip(
                                    message: 'ID ${v.id}',
                                    child: Text(
                                      fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  VariantAttributesDisplay(
                                    attributes: v.attributes,
                                  ),
                                  const SizedBox(height: 4),
                                  const SizedBox.shrink(),
                                ],
                              ),
                            );
                          },
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

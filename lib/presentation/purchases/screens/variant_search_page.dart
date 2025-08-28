import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/product_repository.dart';
import 'package:clothes_pos/data/repositories/category_repository.dart';
import 'package:clothes_pos/data/models/category.dart';
import 'package:clothes_pos/data/models/product_variant.dart';

class VariantSearchPage extends StatefulWidget {
  const VariantSearchPage({super.key});
  @override
  State<VariantSearchPage> createState() => _VariantSearchPageState();
}

class _VariantSearchPageState extends State<VariantSearchPage> {
  final _repo = sl<ProductRepository>();
  final _q = TextEditingController();
  List<Category> _cats = [];
  int? _selectedCat;

  bool _loading = false;
  List<ProductVariant> _results = [];

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
                              return CupertinoListTile(
                                title: Text(v.sku ?? ''),
                                subtitle: Text(
                                  'ID ${v.id} — ${v.size ?? ''} ${v.color ?? ''}'
                                      .trim(),
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
                            return CupertinoButton(
                              padding: const EdgeInsets.all(12),
                              onPressed: () =>
                                  Navigator.of(context).pop<ProductVariant>(v),
                              color: CupertinoColors.systemGrey6,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    v.sku ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${v.size ?? ''} ${v.color ?? ''}'.trim(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: CupertinoColors.secondaryLabel,
                                    ),
                                  ),
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

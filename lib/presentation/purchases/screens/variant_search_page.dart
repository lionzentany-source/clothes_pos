import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/product_repository.dart';
import 'package:clothes_pos/data/models/product_variant.dart';

class VariantSearchPage extends StatefulWidget {
  const VariantSearchPage({super.key});
  @override
  State<VariantSearchPage> createState() => _VariantSearchPageState();
}

class _VariantSearchPageState extends State<VariantSearchPage> {
  final _repo = sl<ProductRepository>();
  final _q = TextEditingController();
  bool _loading = false;
  List<ProductVariant> _results = [];

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      _results = await _repo.searchVariants(name: _q.text.trim().isEmpty ? null : _q.text.trim(), limit: 30);
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
      navigationBar: const CupertinoNavigationBar(middle: Text('بحث عن متغير')),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: CupertinoSearchTextField(
                controller: _q,
                onSubmitted: (_) => _search(),
                onChanged: (_) => _search(),
                placeholder: 'اسم/باركود/ SKU',
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final v = _results[i];
                        return CupertinoListTile(
                          title: Text(v.sku),
                          subtitle: Text('ID ${v.id} — ${v.size ?? ''} ${v.color ?? ''}'.trim()),
                          onTap: () => Navigator.of(context).pop<ProductVariant>(v),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}


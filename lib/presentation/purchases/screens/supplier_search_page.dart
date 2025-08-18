import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/supplier_repository.dart';
import 'package:clothes_pos/data/models/supplier.dart';

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
      _results = q.isEmpty ? await _repo.listAll(limit: 50) : await _repo.search(q, limit: 50);
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
      navigationBar: const CupertinoNavigationBar(middle: Text('اختيار المورد')),
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
                          title: Text(s.name),
                          subtitle: Text('ID ${s.id}'),
                          onTap: () => Navigator.of(context).pop<Supplier>(s),
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


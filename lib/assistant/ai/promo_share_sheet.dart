import 'package:flutter/cupertino.dart';
import 'package:share_plus/share_plus.dart';
import 'package:clothes_pos/data/models/parent_product.dart';

class PromoShareSheet extends StatefulWidget {
  final List<ParentProduct> products;
  final Future<String> Function(ParentProduct) generatePromoText;
  const PromoShareSheet({
    super.key,
    required this.products,
    required this.generatePromoText,
  });

  @override
  State<PromoShareSheet> createState() => _PromoShareSheetState();
}

class _PromoShareSheetState extends State<PromoShareSheet> {
  ParentProduct? _selectedProduct;
  String _promoText = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('إنشاء منشور ترويجي'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('اختر المنتج:'),
              CupertinoPicker(
                itemExtent: 40,
                onSelectedItemChanged: (i) async {
                  setState(() {
                    _selectedProduct = widget.products[i];
                    _promoText = '';
                    _loading = true;
                  });
                  final text = await widget.generatePromoText(
                    widget.products[i],
                  );
                  setState(() {
                    _promoText = text;
                    _loading = false;
                  });
                },
                children: widget.products.map((p) => Text(p.name)).toList(),
              ),
              const SizedBox(height: 16),
              if (_selectedProduct != null) ...[
                Text('تفاصيل المنتج:'),
                Text(_selectedProduct!.description ?? '-'),
                const SizedBox(height: 12),
                const Text('النص التسويقي:'),
                if (_loading)
                  const CupertinoActivityIndicator()
                else
                  CupertinoTextField(
                    controller: TextEditingController(text: _promoText),
                    maxLines: 5,
                    readOnly: true,
                  ),
                const SizedBox(height: 16),
                CupertinoButton.filled(
                  onPressed: _promoText.isNotEmpty
                      ? () {
                          final imagePath = _selectedProduct?.imagePath;
                          if (imagePath != null && imagePath.isNotEmpty) {
                            Share.shareXFiles([
                              XFile(imagePath),
                            ], text: _promoText);
                          } else {
                            Share.share(_promoText);
                          }
                        }
                      : null,
                  child: const Text('مشاركة'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

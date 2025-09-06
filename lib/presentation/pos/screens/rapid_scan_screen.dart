import 'package:flutter/cupertino.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:clothes_pos/presentation/pos/bloc/pos_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/pos/utils/cart_helpers.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';
import 'package:clothes_pos/presentation/common/widgets/app_buttons.dart';

class RapidScanScreen extends StatefulWidget {
  const RapidScanScreen({super.key});
  @override
  State<RapidScanScreen> createState() => _RapidScanScreenState();
}

class _RapidScanScreenState extends State<RapidScanScreen> {
  bool _scanning = false;
  final List<String> _recent = [];

  Future<void> _loopScan() async {
    if (_scanning) return;
    setState(() => _scanning = true);
    final c = context; // capture the context used inside the loop
    while (c.mounted && _scanning) {
      final result = await BarcodeScanner.scan();
      if (!c.mounted) break;
      final code = result.rawContent;
      if (code.isEmpty) break; // cancelled
      final pos = c.read<PosCubit>();
      final resolved = await pos.addByBarcode(code);
      var ok = false;
      if (resolved != null) {
        if (!c.mounted) break;
        await safeAddToCart(c, resolved.id, resolved.price);
        ok = true;
      }
      if (!c.mounted) break;
      setState(() {
        _recent.insert(0, '${ok ? '' : '❌ '}$code');
        if (_recent.length > 10) _recent.removeLast();
      });
    }
    if (c.mounted) setState(() => _scanning = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('وضع المسح السريع'),
        trailing: AppIconButton(
          size: 40,
          onPressed: () => Navigator.pop(context),
          icon: const Icon(CupertinoIcons.xmark),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: c.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  alignment: Alignment.center,
                  child: _scanning
                      ? const CupertinoActivityIndicator(radius: 18)
                      : const Icon(CupertinoIcons.barcode_viewfinder, size: 96),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'آخر الأكواد:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  itemCount: _recent.length,
                  itemBuilder: (_, i) => Text(
                    _recent[i],
                    style: TextStyle(color: c.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppPrimaryButton(
                onPressed: _scanning ? null : _loopScan,
                child: Text(_scanning ? 'جارٍ المسح...' : 'ابدأ المسح المتكرر'),
              ),
              if (_scanning)
                AppPrimaryButton(
                  onPressed: () => setState(() => _scanning = false),
                  child: const Text('إيقاف'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

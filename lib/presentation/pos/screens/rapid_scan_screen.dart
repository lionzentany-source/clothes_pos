import 'package:flutter/cupertino.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:clothes_pos/presentation/pos/bloc/pos_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';

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
    while (mounted && _scanning) {
      final code = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666',
        'إلغاء',
        true,
        ScanMode.BARCODE,
      );
      if (!mounted || code == '-1') break;
      final ok = await context.read<PosCubit>().addByBarcode(code);
      setState(() {
        _recent.insert(0, '${ok ? '' : '❌ '}$code');
        if (_recent.length > 10) _recent.removeLast();
      });
    }
    if (mounted) setState(() => _scanning = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('وضع المسح السريع'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.xmark),
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
              CupertinoButton.filled(
                onPressed: _scanning ? null : _loopScan,
                child: Text(_scanning ? 'جارٍ المسح...' : 'ابدأ المسح المتكرر'),
              ),
              if (_scanning)
                CupertinoButton(
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

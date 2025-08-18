import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/core/hardware/uhf/uhf_reader.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/l10n/app_localizations.dart';
import 'package:clothes_pos/core/hardware/uhf/uhf_reader_bridge.dart';

/// Presents a live scanning dialog and returns the distinct EPC list when closed.
Future<List<String>?> showRfidScanDialog(BuildContext context) async {
  return showCupertinoDialog<List<String>>(
    context: context,
    barrierDismissible: true,
    builder: (dialogCtx) => _RfidScanDialog(dialogCtx: dialogCtx),
  );
}

class _RfidScanDialog extends StatefulWidget {
  final BuildContext dialogCtx;
  const _RfidScanDialog({required this.dialogCtx});
  @override
  State<_RfidScanDialog> createState() => _RfidScanDialogState();
}

class _RfidScanDialogState extends State<_RfidScanDialog> {
  final List<String> _seen = [];
  final List<Object> _errors = [];
  UHFReader? _reader;
  StreamSubscription? _sub;
  StreamSubscription? _errSub;
  bool _stopping = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      _reader = sl<UHFReader>();
      await _reader!.initialize();
      await _reader!.open();
      if (!mounted) return;
      _sub = _reader!.stream.listen((t) {
        if (!_seen.contains(t.epc)) {
          setState(() => _seen.add(t.epc));
        }
      }, onError: (e, st) => setState(() => _errors.add(e)));
      if (_reader is UHFReaderBridgeProcess) {
        _errSub = (_reader as UHFReaderBridgeProcess).errors.listen((e) {
          setState(() => _errors.add(e));
        });
      }
      await _reader!.startInventory();
    } catch (e) {
      setState(() => _errors.add(e));
    }
  }

  Future<void> _stopAndClose() async {
    if (_stopping) return; // debounce
    _stopping = true;
    try {
      await _reader?.stopInventory();
      await _sub?.cancel();
      await _errSub?.cancel();
      await _reader?.close();
    } finally {
      if (mounted) Navigator.of(widget.dialogCtx).pop(_seen);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _errSub?.cancel();
    _reader?.stopInventory();
    _reader?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return CupertinoAlertDialog(
      title: Text(l.scanning),
      content: SizedBox(
        height: 170,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(l.pressStop, textDirection: TextDirection.rtl),
            const SizedBox(height: 6),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: ListView.builder(
                      itemCount: _seen.length,
                      itemBuilder: (_, i) =>
                          Text(_seen[i], style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
              ),
            ),
            if (_errors.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _errors.first.toString(),
                  style: const TextStyle(
                    color: CupertinoColors.systemRed,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _stopAndClose,
          child: Text(l.stop),
        ),
      ],
    );
  }
}

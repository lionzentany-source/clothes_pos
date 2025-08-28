import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/core/hardware/uhf/uhf_reader.dart';
import 'package:clothes_pos/presentation/pos/bloc/pos_cubit.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';

class RfidToggle extends StatefulWidget {
  const RfidToggle({super.key});

  @override
  State<RfidToggle> createState() => _RfidToggleState();
}

class _RfidToggleState extends State<RfidToggle> {
  UHFReader? _reader;
  StreamSubscription? _sub;
  bool _scanning = false;
  final _seen = <String, DateTime>{};

  @override
  void initState() {
    super.initState();
    try {
      _reader = sl<UHFReader>();
    } catch (_) {
      _reader = null;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_reader == null) {
      _show('غير متاح', 'قارئ RFID غير متوفر على هذه المنصة');
      return;
    }
    try {
      final settings = sl<SettingsRepository>();
      final enabled = await settings.get('rfid_enabled');
      if (enabled != '1' && enabled?.toLowerCase() != 'true') {
        _show('غير مفعّل', 'يرجى تفعيل RFID من الإعدادات أولاً');
        return;
      }
      final debounceMs =
          int.tryParse(await settings.get('rfid_debounce_ms') ?? '') ?? 800;
      final rfPower = int.tryParse(await settings.get('rfid_rf_power') ?? '');
      final region = int.tryParse(await settings.get('rfid_region') ?? '');

      if (!_scanning) {
        // If it's a mock reader, اخبر المستخدم أنه مجرد وضع تجريبي
        final readerType = _reader.runtimeType.toString();
        if (readerType.contains('Mock')) {
          _show('وضع تجريبي', 'يتم تشغيل RFID بوضع محاكي بدون جهاز فعلي');
        }
        await _reader!.initialize();
        await _reader!.open();
        if (rfPower != null || region != null) {
          await _reader!.configure(rfPower: rfPower, region: region);
        }
        _sub = _reader!.stream.listen((t) {
          final last = _seen[t.epc];
          final now = DateTime.now();
          if (last != null &&
              now.difference(last).inMilliseconds < debounceMs) {
            return;
          }
          _seen[t.epc] = now;
          if (!mounted) return;
          // Safely schedule on next frame to avoid using possibly stale context
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.read<PosCubit>().addByRfid(t.epc);
          });
        });
        await _reader!.startInventory();
        if (mounted) setState(() => _scanning = true);
      } else {
        await _reader!.stopInventory();
        await _reader!.close();
        await _sub?.cancel();
        _sub = null;
        if (mounted) setState(() => _scanning = false);
      }
    } catch (e) {
      _show('خطأ', e.toString());
    }
  }

  void _show(String t, String m) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(t),
        content: Text(m),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final available = _reader != null;
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      onPressed: available ? _toggle : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _scanning
                ? CupertinoIcons.radiowaves_left
                : CupertinoIcons.dot_radiowaves_left_right,
          ),
          const SizedBox(width: AppSpacing.xxs + 2),
          Text(_scanning ? 'إيقاف RFID' : 'تشغيل RFID'),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/core/hardware/uhf/uhf_reader.dart';
import 'package:clothes_pos/core/hardware/uhf/uhf_reader_bridge.dart';
import 'package:clothes_pos/core/hardware/uhf/models.dart';
import 'package:clothes_pos/core/logging/app_logger.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';

/// Periodically checks UHF reader availability and attempts recovery.
class UHFHealthMonitor {
  final Duration interval;
  Timer? _timer;
  bool _checking = false;
  int _consecutiveFailures = 0;
  final int maxFailuresBeforeRestart;

  UHFHealthMonitor({
    this.interval = const Duration(minutes: 2),
    this.maxFailuresBeforeRestart = 2,
  });

  void start() {
    _timer ??= Timer.periodic(interval, (_) => _check());
  }

  Future<void> _check() async {
    if (_checking) return;
    _checking = true;
    try {
      // Check RFID toggle from settings before any hardware operation
      final settingsRepo = sl<SettingsRepository>();
      final enabled = await settingsRepo.get('rfid_enabled');
      if (enabled != '1' && enabled != 'true') {
        AppLogger.i('UHF health: skipped (rfid disabled)');
        return;
      }
      final reader = sl<UHFReader>();
      if (reader is UHFReaderBridgeProcess) {
        if (reader.status == UHFStatus.unavailable) {
          _consecutiveFailures++;
          AppLogger.w('UHF health: unavailable (fail=$_consecutiveFailures)');
          if (_consecutiveFailures >= maxFailuresBeforeRestart) {
            AppLogger.w('UHF health: restarting bridge process');
            try {
              await reader.dispose();
            } catch (_) {}
            try {
              await reader.open();
            } catch (e) {
              AppLogger.e('UHF reopen failed', error: e);
            }
            _consecutiveFailures = 0;
          }
        } else {
          _consecutiveFailures = 0;
        }
      }
    } catch (e) {
      AppLogger.w('UHF health check error: $e');
    } finally {
      _checking = false;
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

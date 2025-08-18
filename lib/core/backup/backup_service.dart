import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../logging/app_logger.dart';

/// Periodic backup service that creates timestamped copies of the SQLite DB.
class BackupService {
  final String dbPath;
  final Directory backupRoot;
  final Duration interval;
  final int maxFiles;
  final Duration maxAge;
  Timer? _timer;
  bool _running = false;
  final _fmt = DateFormat('yyyyMMdd_HHmmss');

  BackupService({
    required this.dbPath,
    required this.backupRoot,
    this.interval = const Duration(hours: 6),
    this.maxFiles = 20,
    this.maxAge = const Duration(days: 14),
  });

  Future<void> start() async {
    if (_running) return;
    _running = true;
    await _ensureDir();
    _schedule();
    Future.delayed(const Duration(seconds: 20), () => _run(manual: false));
    AppLogger.i(
      'BackupService started interval=$interval path=${backupRoot.path}',
    );
  }

  Future<void> stop() async {
    _timer?.cancel();
    _running = false;
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _run(manual: false));
  }

  Future<void> runManual() => _run(manual: true);

  Future<void> _ensureDir() async {
    if (!await backupRoot.exists()) {
      await backupRoot.create(recursive: true);
    }
  }

  Future<void> _run({required bool manual}) async {
    final started = DateTime.now();
    try {
      final src = File(dbPath);
      if (!await src.exists()) {
        AppLogger.w('BackupService: source DB missing at $dbPath');
        return;
      }
      final name = 'db_${_fmt.format(DateTime.now())}.sqlite';
      final dest = File(p.join(backupRoot.path, name));
      await src.copy(dest.path);
      AppLogger.i(
        'BackupService: created ${dest.path} size=${await dest.length()} manual=$manual',
      );
      await _retention();
    } catch (e) {
      AppLogger.e('BackupService run failed manual=$manual', error: e);
    } finally {
      final dur = DateTime.now().difference(started).inMilliseconds;
      AppLogger.d(
        'BackupService cycle ${manual ? 'manual' : 'auto'} took ${dur}ms',
      );
    }
  }

  Future<void> _retention() async {
    try {
      final files = await backupRoot
          .list()
          .where((e) => e is File && e.path.endsWith('.sqlite'))
          .cast<File>()
          .toList();
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );
      final now = DateTime.now();
      final purge = <File>[];
      for (var i = 0; i < files.length; i++) {
        final f = files[i];
        final age = now.difference(f.lastModifiedSync());
        if (age > maxAge || i >= maxFiles) purge.add(f);
      }
      for (final f in purge) {
        try {
          await f.delete();
          AppLogger.d('BackupService: deleted old backup ${f.path}');
        } catch (e) {
          AppLogger.w('BackupService: failed to delete ${f.path}: $e');
        }
      }
    } catch (e) {
      AppLogger.e('BackupService retention failed', error: e);
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clothes_pos/core/hardware/uhf/uhf_reader.dart';
import 'package:clothes_pos/core/hardware/uhf/models.dart';

/// Bridge implementation: launches external 32-bit helper that talks to the
/// real 32-bit DLL and streams EPC codes over stdout as JSON lines.
/// Helper exe contract:
///  - On start: tries to open reader, prints {"event":"ready"}\n
///  - For each tag: prints {"event":"tag","epc":"..."}\n
///  - On error: prints {"event":"error","message":"..."}\n then exits (optional non-zero)
///  - Accepts commands via stdin: {"cmd":"start"}, {"cmd":"stop"}, {"cmd":"shutdown"}
class UHFReaderBridgeProcess implements UHFReader {
  final String executablePath; // path to helper x86 exe
  Process? _proc;
  UHFStatus _status = UHFStatus.unavailable;
  final _controller = StreamController<TagRead>.broadcast();
  StreamSubscription<String>? _linesSub;
  Completer<void>? _readyCompleter; // Completes when we receive 'ready'
  StreamSubscription<int>? _exitSub;
  final _errorsController = StreamController<Object>.broadcast();

  UHFReaderBridgeProcess({required this.executablePath});

  @override
  @override
  UHFStatus get status => _status;

  @override
  @override
  Stream<TagRead> get stream => _controller.stream;

  /// Consumers can also listen to low-level bridge errors (process exit, stderr, protocol) if desired.
  Stream<Object> get errors => _errorsController.stream;

  @override
  @override
  Future<void> initialize() async {
    _status = UHFStatus.idle; // Assume ready after spawn
  }

  @override
  @override
  Future<void> open() async {
    if (_proc != null) return; // already running
    try {
      // Ensure executable exists before attempting to start
      final file = File(executablePath);
      if (!file.existsSync()) {
        throw Exception('bridge executable not found at: $executablePath');
      }
      // Log launch
      // ignore: avoid_print
      print('[UHF] launching bridge at $executablePath');
      _proc = await Process.start(
        executablePath,
        const <String>[],
        runInShell: false,
      );
    } on Object catch (e) {
      throw Exception('فشل تشغيل عملية الجسر x86: $e');
    }
    _status = UHFStatus.unavailable; // waiting for ready
    _readyCompleter = Completer<void>();
    _linesSub = _proc!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          _handleLine,
          onError: (e, st) {
            _controller.addError(e, st);
            _errorsController.add(e);
          },
          onDone: () {
            _status = UHFStatus.unavailable;
          },
        );
    _proc!.stderr.transform(utf8.decoder).listen((err) {
      if (err.trim().isNotEmpty) {
        final ex = Exception('Bridge stderr: $err');
        _controller.addError(ex);
        _errorsController.add(ex);
      }
    });

    _exitSub = _proc!.exitCode.asStream().listen((code) {
      if (_status == UHFStatus.scanning) {
        _status = UHFStatus.unavailable;
      }
      if (code != 0) {
        final ex = Exception('Bridge process exited unexpectedly (code=$code)');
        _controller.addError(ex);
        _errorsController.add(ex);
      }
    });

    // Wait for ready handshake (max 3s)
    try {
      await _readyCompleter!.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw TimeoutException('Bridge ready timeout (3s)');
        },
      );
      // ignore: avoid_print
      print('[UHF] bridge ready');
    } catch (e) {
      _proc?.kill(ProcessSignal.sigkill);
      _proc = null;
      rethrow;
    } finally {
      _readyCompleter = null; // release
    }
  }

  void _handleLine(String line) {
    if (line.trim().isEmpty) return;
    try {
      final map = json.decode(line) as Map<String, dynamic>;
      switch (map['event']) {
        case 'ready':
          _status = UHFStatus.idle;
          if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
            _readyCompleter!.complete();
          }
          break;
        case 'tag':
          final epc = (map['epc'] ?? '').toString();
          if (epc.isNotEmpty) {
            _controller.add(
              TagRead(epc: epc.toUpperCase(), timestamp: DateTime.now()),
            );
          }
          break;
        case 'error':
          final msg = map['message'] ?? 'bridge error';
          if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
            _readyCompleter!.completeError(Exception(msg));
          }
          _controller.addError(Exception(msg));
          _errorsController.add(Exception(msg));
          _status = UHFStatus.unavailable;
          break;
      }
    } catch (e) {
      _controller.addError(Exception('Parse line failed: $line -> $e'));
      _errorsController.add(e);
    }
  }

  @override
  @override
  Future<void> close() async {
    await stopInventory();
    await _proc?.stdin.close();
    _proc = null;
    _status = UHFStatus.idle;
  }

  @override
  @override
  Future<void> startInventory() async {
    if (_proc == null) throw StateError('Bridge process غير مفتوح');
    _status = UHFStatus.scanning;
    _proc!.stdin.write('{"cmd":"start"}\n');
  }

  @override
  @override
  Future<void> stopInventory() async {
    if (_proc == null) return;
    if (_status == UHFStatus.scanning) {
      _proc!.stdin.write('{"cmd":"stop"}\n');
    }
    _status = UHFStatus.idle;
  }

  @override
  @override
  Future<void> dispose() async {
    await stopInventory();
    await _linesSub?.cancel();
    _linesSub = null;
    await _exitSub?.cancel();
    _exitSub = null;
    _proc?.kill(ProcessSignal.sigkill);
    _proc = null;
    await _controller.close();
    await _errorsController.close();
  }

  @override
  Future<void> configure({int? rfPower, int? region}) async {
    // Forward future configuration commands to bridge if we extend protocol.
  }
}

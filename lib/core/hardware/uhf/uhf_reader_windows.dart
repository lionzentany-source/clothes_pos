import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:path/path.dart' as p;

import 'package:ffi/ffi.dart';

import 'models.dart';
import 'uhf_reader.dart';

// ignore_for_file: non_constant_identifier_names, constant_identifier_names

// Error codes (subset)
const int ERROR_SUCCESS = 0x00;
const int ERROR_CMD_NO_TAG = -249;

// C struct mapping for TagInfo
final class _TagInfo extends ffi.Struct {
  @ffi.Uint16()
  external int m_no;

  @ffi.Int16()
  external int m_rssi;

  @ffi.Uint8()
  external int m_ant;

  @ffi.Uint8()
  external int m_channel;

  @ffi.Array(2)
  external ffi.Array<ffi.Uint8> m_crc;

  @ffi.Array(2)
  external ffi.Array<ffi.Uint8> m_pc;

  @ffi.Uint8()
  external int m_len;

  @ffi.Array(255)
  external ffi.Array<ffi.Uint8> m_code;
}

// DevicePara mapping from CFApi.h
final class _DevicePara extends ffi.Struct {
  @ffi.Uint8()
  external int DEVICEARRD;
  @ffi.Uint8()
  external int RFIDPRO;
  @ffi.Uint8()
  external int WORKMODE;
  @ffi.Uint8()
  external int INTERFACE;
  @ffi.Uint8()
  external int BAUDRATE;
  @ffi.Uint8()
  external int WGSET;
  @ffi.Uint8()
  external int ANT;
  @ffi.Uint8()
  external int REGION;
  @ffi.Array(2)
  external ffi.Array<ffi.Uint8> STRATFREI;
  @ffi.Array(2)
  external ffi.Array<ffi.Uint8> STRATFRED;
  @ffi.Array(2)
  external ffi.Array<ffi.Uint8> STEPFRE;
  @ffi.Uint8()
  external int CN;
  @ffi.Uint8()
  external int RFIDPOWER;
  @ffi.Uint8()
  external int INVENTORYAREA;
  @ffi.Uint8()
  external int QVALUE;
  @ffi.Uint8()
  external int SESSION;
  @ffi.Uint8()
  external int ACSADDR;
  @ffi.Uint8()
  external int ACSDATALEN;
  @ffi.Uint8()
  external int FILTERTIME;
  @ffi.Uint8()
  external int TRIGGLETIME;
  @ffi.Uint8()
  external int BUZZERTIME;
  @ffi.Uint8()
  external int INTENERLTIME;
}

// FFI typedefs
typedef CFHidGetUsbCountNative = ffi.Int32 Function();
typedef CFHidGetUsbCountDart = int Function();

typedef _OpenHidConnectionNative =
    ffi.Int32 Function(
      ffi.Pointer<ffi.Pointer<ffi.Void>> handler,
      ffi.Uint16 index,
    );
typedef _OpenHidConnectionDart =
    int Function(ffi.Pointer<ffi.Pointer<ffi.Void>> handler, int index);

typedef _CloseDeviceNative = ffi.Int32 Function(ffi.Pointer<ffi.Void> handler);
typedef _CloseDeviceDart = int Function(ffi.Pointer<ffi.Void> handler);

typedef _InventoryContinueNative =
    ffi.Int32 Function(
      ffi.Pointer<ffi.Void> handler,
      ffi.Uint8 invCount,
      ffi.Uint32 invParam,
    );
typedef _InventoryContinueDart =
    int Function(ffi.Pointer<ffi.Void> handler, int invCount, int invParam);

typedef _GetTagUiiNative =
    ffi.Int32 Function(
      ffi.Pointer<ffi.Void> handler,
      ffi.Pointer<_TagInfo> tagInfo,
      ffi.Uint16 timeoutMs,
    );
typedef _GetTagUiiDart =
    int Function(
      ffi.Pointer<ffi.Void> handler,
      ffi.Pointer<_TagInfo> tagInfo,
      int timeoutMs,
    );

typedef _InventoryStopNative =
    ffi.Int32 Function(ffi.Pointer<ffi.Void> handler, ffi.Uint16 timeoutMs);
typedef _InventoryStopDart =
    int Function(ffi.Pointer<ffi.Void> handler, int timeoutMs);

class UHFReaderWindows implements UHFReader {
  UHFStatus _status = UHFStatus.unavailable;
  final _controller = StreamController<TagRead>.broadcast();
  late final ffi.DynamicLibrary _lib;

  // Resolved functions
  late final CFHidGetUsbCountDart _getUsbCount;
  late final _OpenHidConnectionDart _openHid;
  late final _CloseDeviceDart _close;
  late final _InventoryContinueDart _inventoryContinue;
  late final _GetTagUiiDart _getTagUii;
  late final _InventoryStopDart _inventoryStop;

  ffi.Pointer<ffi.Void>? _handler;
  Timer? _pollTimer;

  @override
  UHFStatus get status => _status;

  @override
  Stream<TagRead> get stream => _controller.stream;

  @override
  Future<void> configure({int? rfPower, int? region}) async {
    if (_handler == null) return;
    // Optional: SetRFPower and SetFreq/Region via DevicePara APIs.
    // We implement RF power via SetRFPower if provided.
    try {
      if (rfPower != null) {
        // SetRFPower(h, power, reserved)
        final setRfPower = _lib
            .lookupFunction<
              ffi.Int32 Function(ffi.Pointer<ffi.Void>, ffi.Uint8, ffi.Uint8),
              int Function(ffi.Pointer<ffi.Void>, int, int)
            >('SetRFPower');
        final r = setRfPower(_handler!, rfPower, 0);
        if (r != ERROR_SUCCESS) {
          throw Exception('SetRFPower فشل: $r');
        }
      }
      if (region != null) {
        // Read current DevicePara as bytes -> cast struct -> modify REGION -> write back
        final getPara = _lib
            .lookupFunction<
              ffi.Int32 Function(
                ffi.Pointer<ffi.Void>,
                ffi.Pointer<_DevicePara>,
              ),
              int Function(ffi.Pointer<ffi.Void>, ffi.Pointer<_DevicePara>)
            >('GetDevicePara');
        final setPara = _lib
            .lookupFunction<
              ffi.Int32 Function(
                ffi.Pointer<ffi.Void>,
                ffi.Pointer<_DevicePara>,
              ),
              int Function(ffi.Pointer<ffi.Void>, ffi.Pointer<_DevicePara>)
            >('SetDevicePara');
        final p = calloc<_DevicePara>();
        try {
          final r1 = getPara(_handler!, p);
          if (r1 != ERROR_SUCCESS) {
            throw Exception('GetDevicePara فشل: $r1');
          }
          p.ref.REGION = region;
          final r2 = setPara(_handler!, p);
          if (r2 != ERROR_SUCCESS) {
            throw Exception('SetDevicePara فشل: $r2');
          }
        } finally {
          calloc.free(p);
        }
      }
    } catch (e) {
      // If functions missing, ignore gracefully
      // Optionally rethrow for visibility
      rethrow;
    }
  }

  @override
  Future<void> initialize() async {
    // Try multiple candidate paths to load the DLL. Provide clearer diagnostics
    // when architecture mismatch (%1 is not a valid Win32 application - error 193)
    final envOverride = io.Platform.environment['UHF_READER_DLL_PATH'];
    final candidates = <String>{
      if (envOverride != null && envOverride.trim().isNotEmpty)
        envOverride.trim(),
      'UHFPrimeReader.dll',
      p.join(io.Directory.current.path, 'UHFPrimeReader.dll'),
      p.join(
        io.Directory.current.path,
        'build',
        'windows',
        'x64',
        'runner',
        'Debug',
        'UHFPrimeReader.dll',
      ),
      p.join(
        io.Directory.current.path,
        'build',
        'windows',
        'x64',
        'runner',
        'Release',
        'UHFPrimeReader.dll',
      ),
      p.join(
        io.Directory.current.path,
        'UHF Desk Reader SDK',
        'API',
        'UHFPrimeReader.dll',
      ),
      p.join(
        io.Directory.current.path,
        'windows',
        'UHF Desk Reader SDK',
        'API',
        'UHFPrimeReader.dll',
      ),
    }..removeWhere((e) => e.trim().isEmpty);

    Object? lastError;
    var anyX64Found = false;
    for (final path in candidates) {
      try {
        if (!io.File(path).existsSync()) {
          continue; // skip non-existent
        }
        // Determine architecture of DLL before attempting to load (PE header parse)
        String? archLabel;
        try {
          final bytes = io.File(path).readAsBytesSync();
          if (bytes.length >= 0x40) {
            final peOffset = bytes.buffer.asByteData().getUint32(
              0x3C,
              Endian.little,
            );
            if (peOffset + 6 < bytes.length &&
                bytes[peOffset] == 0x50 && // 'P'
                bytes[peOffset + 1] == 0x45 && // 'E'
                bytes[peOffset + 2] == 0x00 &&
                bytes[peOffset + 3] == 0x00) {
              final machine = bytes.buffer.asByteData().getUint16(
                peOffset + 4,
                Endian.little,
              );
              switch (machine) {
                case 0x8664:
                  archLabel = 'x64';
                  break;
                case 0x014c:
                  archLabel = 'x86';
                  break;
                case 0xAA64:
                  archLabel = 'ARM64';
                  break;
                default:
                  archLabel = '0x${machine.toRadixString(16)}';
              }
            }
          }
        } catch (_) {
          archLabel = null;
        }
        // Debug print: attempting to load this path with detected architecture
        // ignore: avoid_print
        print('[UHF] Trying DLL: $path  (arch: ${archLabel ?? 'unknown'})');
        // Skip obvious mismatch (Flutter desktop = x64)
        if (archLabel == 'x86') {
          // ignore: avoid_print
          print(
            '[UHF] Skipping $path because it is 32-bit (x86) and app is x64',
          );
          continue;
        } else if (archLabel == 'x64') {
          anyX64Found = true;
        }
        _lib = ffi.DynamicLibrary.open(path);
        // Success -> resolve symbols then break
        _getUsbCount = _lib
            .lookupFunction<CFHidGetUsbCountNative, CFHidGetUsbCountDart>(
              'CFHid_GetUsbCount',
            );
        _openHid = _lib
            .lookupFunction<_OpenHidConnectionNative, _OpenHidConnectionDart>(
              'OpenHidConnection',
            );
        _close = _lib.lookupFunction<_CloseDeviceNative, _CloseDeviceDart>(
          'CloseDevice',
        );
        _inventoryContinue = _lib
            .lookupFunction<_InventoryContinueNative, _InventoryContinueDart>(
              'InventoryContinue',
            );
        _getTagUii = _lib.lookupFunction<_GetTagUiiNative, _GetTagUiiDart>(
          'GetTagUii',
        );
        _inventoryStop = _lib
            .lookupFunction<_InventoryStopNative, _InventoryStopDart>(
              'InventoryStop',
            );
        _status = UHFStatus.idle;
        return;
      } catch (e) {
        // ignore: avoid_print
        print('[UHF] Failed to load: ' + path + ' -> ' + e.toString());
        lastError = e;
        // continue trying next path
      }
    }

    // Deep fallback: حاول البحث العميق داخل مجلد المشروع / build عن أي نسخة DLL
    String? deepFound;
    try {
      final root = io.Directory(io.Directory.current.path);
      final toVisit = <io.Directory>[root];
      final seen = <String>{};
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (toVisit.isNotEmpty && DateTime.now().isBefore(deadline)) {
        final dir = toVisit.removeLast();
        if (!seen.add(dir.path)) continue;
        // حد أقصى للعمق لتجنب الدوران الكبير
        final depth =
            dir.path.split(RegExp(r'[\\/]')).length -
            root.path.split(RegExp(r'[\\/]')).length;
        if (depth > 8) continue;
        try {
          for (final entity in dir.listSync(followLinks: false)) {
            if (entity is io.File &&
                p.basename(entity.path).toLowerCase() == 'uhfprimereader.dll') {
              deepFound = entity.path;
              break;
            } else if (entity is io.Directory) {
              toVisit.add(entity);
            }
          }
          if (deepFound != null) break;
        } catch (_) {
          // تجاهل أدلة بلا صلاحيات
        }
      }
      if (deepFound != null) {
        try {
          // ignore: avoid_print
          print('[UHF] Deep found DLL: ' + deepFound);
          _lib = ffi.DynamicLibrary.open(deepFound);
          _getUsbCount = _lib
              .lookupFunction<CFHidGetUsbCountNative, CFHidGetUsbCountDart>(
                'CFHid_GetUsbCount',
              );
          _openHid = _lib
              .lookupFunction<_OpenHidConnectionNative, _OpenHidConnectionDart>(
                'OpenHidConnection',
              );
          _close = _lib.lookupFunction<_CloseDeviceNative, _CloseDeviceDart>(
            'CloseDevice',
          );
          _inventoryContinue = _lib
              .lookupFunction<_InventoryContinueNative, _InventoryContinueDart>(
                'InventoryContinue',
              );
          _getTagUii = _lib.lookupFunction<_GetTagUiiNative, _GetTagUiiDart>(
            'GetTagUii',
          );
          _inventoryStop = _lib
              .lookupFunction<_InventoryStopNative, _InventoryStopDart>(
                'InventoryStop',
              );
          _status = UHFStatus.idle;
          return;
        } catch (e) {
          // ignore: avoid_print
          print('[UHF] Deep load failed: ' + deepFound + ' -> ' + e.toString());
          lastError = e;
        }
      }
    } catch (e) {
      lastError = e; // احتفظ بآخر خطأ لو لزم
    }

    if (!anyX64Found) {
      throw Exception(
        'لم يتم العثور على نسخة 64-bit من UHFPrimeReader.dll (كل النسخ x86). يجب توفير DLL x64 متوافق، أو بناء نسخة x64 من السورس C/C++ (راجع مجلد Sample/CDemo/Source/x64) ثم وضعها بجانب التنفيذ.',
      );
    }

    _status = UHFStatus.unavailable;
    final archHint = io.Platform.version.contains('x64')
        ? 'x64'
        : (io.Platform.version.contains('arm64') ? 'ARM64' : 'Unknown');
    final message = StringBuffer()
      ..writeln('فشل تحميل مكتبة UHFPrimeReader.dll')
      ..writeln(
        envOverride == null
            ? 'يمكنك تحديد مسار مخصص عبر متغير البيئة UHF_READER_DLL_PATH'
            : 'تم تمرير مسار عبر UHF_READER_DLL_PATH: $envOverride',
      )
      ..writeln('- أو أنك وضعت الملف بعد تشغيل التطبيق (أعد التشغيل)')
      ..writeln('تمت المحاولة في المسارات التالية:')
      ..writeln(
        candidates.where((c) => io.File(c).existsSync()).isEmpty
            ? ' (لم يتم العثور على أي ملف DLL في المسارات المتوقعة)'
            : candidates
                  .map(
                    (p) =>
                        ' - ${io.File(p).existsSync() ? '[موجود]' : '[غير موجود]'} $p',
                  )
                  .join('\n'),
      )
      ..writeln('\nقد يكون السبب:')
      ..writeln('- عدم وجود الملف في مجلد صحيح')
      ..writeln(
        '- أو عدم تطابق بنية الملف (مثلاً DLL 32-bit مع تطبيق Flutter 64-bit)',
      )
      ..writeln('- أو تلف الملف')
      ..writeln('- أو عدم منح صلاحية الوصول للمجلد (جرب التشغيل كمسؤول)')
      ..writeln('\nبنية التطبيق الحالية: $archHint')
      ..writeln('تأكد أن DLL مبني لنفس البنية ثم أعد التشغيل.')
      ..writeln('\nOriginal error: $lastError');
    throw Exception(message.toString());
  }

  @override
  Future<void> dispose() async {
    await stopInventory();
    if (_handler != null) {
      try {
        _close(_handler!);
      } catch (_) {}
      _handler = null;
    }
    await _controller.close();
  }

  @override
  Future<void> open() async {
    final count = _getUsbCount();
    if (count <= 0) {
      throw Exception('لم يتم العثور على قارئ UHF عبر USB/HID');
    }
    final ph = calloc<ffi.Pointer<ffi.Void>>();
    try {
      final res = _openHid(ph, 0); // افتح أول جهاز
      if (res != ERROR_SUCCESS) {
        throw Exception('OpenHidConnection فشل: $res');
      }
      _handler = ph.value;
      _status = UHFStatus.idle;
    } finally {
      calloc.free(ph);
    }
  }

  @override
  Future<void> close() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (_handler != null) {
      final r = _close(_handler!);
      if (r != ERROR_SUCCESS) {
        throw Exception('CloseDevice فشل: $r');
      }
      _handler = null;
    }
    _status = UHFStatus.idle;
  }

  @override
  Future<void> startInventory() async {
    if (_handler == null) throw StateError('الجهاز غير مفتوح');
    // invCount: 0 (single) / >0 count / 0xFF continuous. نستخدم continuous
    final r = _inventoryContinue(_handler!, 0xFF, 0);
    if (r != ERROR_SUCCESS) {
      throw Exception('InventoryContinue فشل: $r');
    }
    _status = UHFStatus.scanning;

    // Poll tags periodically via GetTagUii
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (_handler == null) return;
      final pInfo = calloc<_TagInfo>();
      try {
        final code = _getTagUii(_handler!, pInfo, 50);
        if (code == ERROR_SUCCESS) {
          final len = pInfo.ref.m_len;
          if (len > 0) {
            final bytes = List<int>.generate(len, (i) => pInfo.ref.m_code[i]);
            final epc = bytes
                .map((b) => b.toRadixString(16).padLeft(2, '0'))
                .join()
                .toUpperCase();
            _controller.add(TagRead(epc: epc, timestamp: DateTime.now()));
          }
        } else if (code == ERROR_CMD_NO_TAG) {
          // ignore
        } else {
          // Other errors: we can ignore transient ones
        }
      } finally {
        calloc.free(pInfo);
      }
    });
  }

  @override
  Future<void> stopInventory() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (_handler != null) {
      final r = _inventoryStop(_handler!, 1000);
      if (r != ERROR_SUCCESS) {
        // Keep status but report
        throw Exception('InventoryStop فشل: $r');
      }
    }
    _status = UHFStatus.idle;
  }
}

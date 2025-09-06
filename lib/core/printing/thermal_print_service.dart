import 'dart:io';
import 'dart:typed_data';

/// Minimal service to send ESC/POS bytes to a network (Ethernet/WiFi) printer.
/// Many thermal printers listen on TCP port 9100 (a.k.a. RAW printing or JetDirect).
/// This avoids plugin conflicts and works on Windows/macOS/Linux/Android/iOS
/// as long as network sockets are permitted.
class ThermalPrintService {
  const ThermalPrintService();

  /// Sends [bytes] to the configured network printer.
  /// If [ip] or [port] are not provided, use defaults or provided settings.
  Future<void> sendBytesToNetwork({
    required Uint8List bytes,
    required String ip,
    int port = 9100,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final socket = await Socket.connect(ip, port, timeout: timeout);
    try {
      socket.add(bytes);
      await socket.flush();
    } finally {
      await socket.close();
    }
  }
}


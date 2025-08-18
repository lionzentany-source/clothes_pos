import 'dart:async';
import 'package:clothes_pos/core/hardware/uhf/uhf_reader.dart';
import 'package:clothes_pos/core/hardware/uhf/models.dart';

/// قارئ UHF وهمي يسمح للتطبيق بالعمل بدون جهاز فعلي.
class NoopUHFReader implements UHFReader {
  final _controller = StreamController<TagRead>.broadcast();
  UHFStatus _status = UHFStatus.idle; // نعتبره في وضع جاهز بدون جهاز

  @override
  UHFStatus get status => _status;

  @override
  Stream<TagRead> get stream => _controller.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Future<void> open() async {
    _status = UHFStatus.idle;
  }

  @override
  Future<void> close() async {
    _status = UHFStatus.idle;
  }

  @override
  Future<void> configure({int? rfPower, int? region}) async {}

  @override
  Future<void> startInventory() async {
    _status = UHFStatus.scanning; // شكلي فقط
  }

  @override
  Future<void> stopInventory() async {
    _status = UHFStatus.idle;
  }
}

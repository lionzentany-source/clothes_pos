import 'dart:async';
import 'models.dart';
import 'uhf_reader.dart';

/// (Deprecated) كان قارئًا وهميًا للمطور؛ لم يعد يستخدم الآن.
class UHFReaderMock implements UHFReader {
  UHFStatus _status = UHFStatus.unavailable;
  final _controller = StreamController<TagRead>.broadcast();

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
  Future<void> startInventory() async {}

  @override
  Future<void> stopInventory() async {}
}

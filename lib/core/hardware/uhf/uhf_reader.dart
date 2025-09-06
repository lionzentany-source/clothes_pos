import 'dart:async';
import 'models.dart';

abstract class UHFReader {
  UHFStatus get status;
  Stream<TagRead> get stream;

  Future<void> initialize();
  Future<void> dispose();

  Future<void> open();
  Future<void> close();

  /// Optionally configure RF params before starting inventory
  Future<void> configure({int? rfPower, int? region});

  Future<void> startInventory();
  Future<void> stopInventory();
}

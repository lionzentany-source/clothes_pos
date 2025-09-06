import 'package:equatable/equatable.dart';

class TagRead extends Equatable {
  final String epc;
  final DateTime timestamp;

  const TagRead({required this.epc, required this.timestamp});

  @override
  List<Object?> get props => [epc, timestamp];
}

enum UHFStatus { unavailable, idle, scanning }


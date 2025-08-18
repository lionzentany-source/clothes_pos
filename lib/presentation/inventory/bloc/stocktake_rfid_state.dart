part of 'stocktake_rfid_cubit.dart';

class StocktakeRfidState extends Equatable {
  final bool reading;
  final Set<String> seenEpCs;
  final int? lastVariantId; // variant that matched the last EPC

  const StocktakeRfidState({
    this.reading = false,
    this.seenEpCs = const {},
    this.lastVariantId,
  });

  StocktakeRfidState copyWith({
    bool? reading,
    Set<String>? seenEpCs,
    int? lastVariantId,
  }) => StocktakeRfidState(
    reading: reading ?? this.reading,
    seenEpCs: seenEpCs ?? this.seenEpCs,
    lastVariantId: lastVariantId ?? this.lastVariantId,
  );

  @override
  List<Object?> get props => [reading, seenEpCs, lastVariantId];
}


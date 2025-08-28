part of 'stocktake_rfid_cubit.dart';

class StocktakeRfidState extends Equatable {
  final bool reading;
  final Set<String> seenEpCs;
  final int? lastVariantId; // variant that matched the last EPC
  final Object? error; // last error, if any

  const StocktakeRfidState({
    this.reading = false,
    this.seenEpCs = const {},
    this.lastVariantId,
    this.error,
  });

  StocktakeRfidState copyWith({
    bool? reading,
    Set<String>? seenEpCs,
    int? lastVariantId,
    Object? error,
  }) => StocktakeRfidState(
    reading: reading ?? this.reading,
    seenEpCs: seenEpCs ?? this.seenEpCs,
    lastVariantId: lastVariantId ?? this.lastVariantId,
    error: error,
  );

  @override
  List<Object?> get props => [reading, seenEpCs, lastVariantId, error];
}


import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/core/hardware/uhf/uhf_reader.dart';
import 'package:clothes_pos/core/hardware/uhf/models.dart';

import 'package:clothes_pos/data/repositories/product_repository.dart';

part 'stocktake_rfid_state.dart';

class StocktakeRfidCubit extends Cubit<StocktakeRfidState> {
  final UHFReader _reader = sl<UHFReader>();
  final ProductRepository _repo = sl<ProductRepository>();
  StreamSubscription? _sub;

  StocktakeRfidCubit() : super(const StocktakeRfidState());

  Future<void> start() async {
    if (state.reading) return;
    await _reader.initialize();
    await _reader.open();
    _sub = _reader.stream.listen(_onTag);
    await _reader.startInventory();
    emit(state.copyWith(reading: true));
  }

  Future<void> stop() async {
    if (!state.reading) return;
    await _reader.stopInventory();
    await _reader.close();
    await _sub?.cancel();
    _sub = null;
    emit(state.copyWith(reading: false));
  }

  Future<void> _onTag(TagRead tag) async {
    final epc = tag.epc.trim();
    if (epc.isEmpty) return;
    if (state.seenEpCs.contains(epc)) return;
    final newSeen = Set<String>.from(state.seenEpCs)..add(epc);
    // resolve epc -> variant
    final rows = await _repo.searchVariantRowMaps(rfidTag: epc, limit: 1);
    if (rows.isNotEmpty) {
      final variantId = rows.first['id'] as int;
      emit(state.copyWith(seenEpCs: newSeen, lastVariantId: variantId));
    } else {
      emit(state.copyWith(seenEpCs: newSeen));
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clothes_pos/data/models/inventory_item_row.dart';
import 'package:clothes_pos/data/repositories/product_repository.dart';
import 'package:clothes_pos/core/di/locator.dart';

part 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final ProductRepository _repo = sl<ProductRepository>();
  InventoryCubit() : super(const InventoryState());

  Future<void> load({String query = '', int? brandId}) async {
    emit(state.copyWith(loading: true, query: query, brandId: brandId));
    final rows = await _repo.searchInventoryRows(
      name: query.isEmpty ? null : query,
      brandId: brandId,
      limit: 100,
    );
    emit(state.copyWith(loading: false, items: rows));
  }
}

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clothes_pos/data/models/sale.dart';
import 'package:clothes_pos/data/repositories/sales_repository.dart';
import 'package:clothes_pos/data/repositories/returns_repository.dart';
import 'package:clothes_pos/data/datasources/returns_dao.dart';

part 'returns_state.dart';

class ReturnsCubit extends Cubit<ReturnsState> {
  final SalesRepository _salesRepository;
  final ReturnsRepository _returnsRepository;

  ReturnsCubit(this._salesRepository, this._returnsRepository) : super(const ReturnsState());

  Future<void> fetchSales() async {
    if (state.hasReachedMax) return;

    emit(state.copyWith(status: ReturnsStatus.loading));

    try {
      final sales = await _salesRepository.listSales(offset: state.sales.length);
      if (sales.isEmpty) {
        emit(state.copyWith(hasReachedMax: true));
      } else {
        emit(state.copyWith(
          status: ReturnsStatus.success,
          sales: List.of(state.sales)..addAll(sales),
          hasReachedMax: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(status: ReturnsStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> searchSales(String query) async {
    emit(state.copyWith(status: ReturnsStatus.loading, searchQuery: query, sales: [], hasReachedMax: false));
    fetchSales();
  }

  Future<void> selectSale(int saleId) async {
    emit(state.copyWith(status: ReturnsStatus.loading));
    try {
      final sale = await _salesRepository.getSale(saleId);
      final items = await _salesRepository.dao.itemRowsForSale(saleId);
      emit(state.copyWith(
        status: ReturnsStatus.success,
        selectedSale: sale,
        selectedSaleItems: items,
        returnQuantities: { for (var item in items) (item['id'] as int) : 0 },
      ));
    } catch (e) {
      emit(state.copyWith(status: ReturnsStatus.failure, errorMessage: e.toString()));
    }
  }

  void updateReturnQuantity(int saleItemId, int quantity) {
    final currentQuantities = Map<int, int>.from(state.returnQuantities);
    currentQuantities[saleItemId] = quantity;
    emit(state.copyWith(returnQuantities: currentQuantities));
  }

  Future<void> createReturn({required String reason, required int userId}) async {
    if (state.selectedSale == null) return;

    emit(state.copyWith(status: ReturnsStatus.loading));

    try {
      final itemsToReturn = <ReturnLineInput>[];
      for (final entry in state.returnQuantities.entries) {
        if (entry.value > 0) {
          final saleItem = state.selectedSaleItems.firstWhere((item) => item['id'] == entry.key);
          itemsToReturn.add(ReturnLineInput(
            saleItemId: saleItem['id'] as int,
            variantId: saleItem['variant_id'] as int,
            quantity: entry.value,
            refundAmount: (saleItem['price_per_unit'] as num).toDouble() * entry.value,
          ));
        }
      }

      if (itemsToReturn.isNotEmpty) {
        await _returnsRepository.createReturn(
          saleId: state.selectedSale!.id!,
          userId: userId,
          reason: reason,
          items: itemsToReturn,
        );
      }
      emit(state.copyWith(status: ReturnsStatus.success));
    } catch (e) {
      emit(state.copyWith(status: ReturnsStatus.failure, errorMessage: e.toString()));
    }
  }
}

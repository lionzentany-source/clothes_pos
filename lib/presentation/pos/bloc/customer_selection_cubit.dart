import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:clothes_pos/data/models/customer.dart';

/// State for customer selection in POS
class CustomerSelectionState extends Equatable {
  final Customer? selectedCustomer;
  final bool isLoading;
  final String? error;

  const CustomerSelectionState({
    this.selectedCustomer,
    this.isLoading = false,
    this.error,
  });

  CustomerSelectionState copyWith({
    Customer? selectedCustomer,
    bool? isLoading,
    String? error,
    bool clearCustomer = false,
    bool clearError = false,
  }) {
    return CustomerSelectionState(
      selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [selectedCustomer, isLoading, error];
}

/// Cubit for managing customer selection in POS
class CustomerSelectionCubit extends Cubit<CustomerSelectionState> {
  CustomerSelectionCubit() : super(const CustomerSelectionState());

  /// Select a customer for the current sale
  void selectCustomer(Customer customer) {
    emit(state.copyWith(
      selectedCustomer: customer,
      clearError: true,
    ));
  }

  /// Clear the selected customer
  void clearCustomer() {
    emit(state.copyWith(clearCustomer: true, clearError: true));
  }

  /// Set loading state
  void setLoading(bool loading) {
    emit(state.copyWith(isLoading: loading));
  }

  /// Set error state
  void setError(String error) {
    emit(state.copyWith(error: error, isLoading: false));
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}

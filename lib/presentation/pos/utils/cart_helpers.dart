import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/pos/bloc/cart_cubit.dart';
import 'package:clothes_pos/presentation/pos/bloc/pos_cubit.dart';

/// Safely add an item to the UI-provided `CartCubit` when available,
/// and fall back to the legacy `PosCubit.addToCart` when not.
Future<void> safeAddToCart(
  BuildContext ctx,
  int variantId,
  double price,
) async {
  try {
    ctx.read<CartCubit>().addItem(variantId, price);
  } catch (e) {
    // Fallback to PosCubit for older flows or when CartCubit isn't provided.
    await ctx.read<PosCubit>().addToCart(variantId, price);
  }
}

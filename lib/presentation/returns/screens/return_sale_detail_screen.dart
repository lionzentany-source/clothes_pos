import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/returns/bloc/returns_cubit.dart';

import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/presentation/common/widgets/variant_attributes_display.dart';

class ReturnSaleDetailScreen extends StatelessWidget {
  final int saleId;

  const ReturnSaleDetailScreen({super.key, required this.saleId});

  @override
  Widget build(BuildContext context) {
    context.read<ReturnsCubit>().selectSale(saleId);
    final userId = context.read<AuthCubit>().state.user!.id;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('إرجاع الفاتورة #$saleId'),
      ),
      child: BlocBuilder<ReturnsCubit, ReturnsState>(
        builder: (context, state) {
          if (state.status == ReturnsStatus.loading ||
              state.selectedSale == null) {
            return const Center(child: CupertinoActivityIndicator());
          }
          if (state.status == ReturnsStatus.failure) {
            return Center(
              child: Text(
                'Failed to fetch sale details: ${state.errorMessage}',
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: state.selectedSaleItems.length,
                  itemBuilder: (context, index) {
                    final item = state.selectedSaleItems[index];
                    final productName =
                        item['parent_name'] ?? item['sku'] ?? 'N/A';
                    return CupertinoListTile(
                      title: Text(productName as String),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الكمية: ${item['quantity']} | السعر: ${item['price_per_unit']}',
                          ),
                          VariantAttributesDisplay(
                            attributes: (item['attributes'] as List?)?.cast(),
                          ),
                        ],
                      ),
                      trailing: SizedBox(
                        width: 150,
                        child: Row(
                          children: [
                            const Text('إرجاع: '),
                            Expanded(
                              child: CupertinoTextField(
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final quantity = int.tryParse(value) ?? 0;
                                  context
                                      .read<ReturnsCubit>()
                                      .updateReturnQuantity(
                                        item['id'] as int,
                                        quantity,
                                      );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CupertinoButton.filled(
                  child: const Text('إتمام الإرجاع'),
                  onPressed: () {
                    context.read<ReturnsCubit>().createReturn(
                      reason: 'User requested return',
                      userId: userId,
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

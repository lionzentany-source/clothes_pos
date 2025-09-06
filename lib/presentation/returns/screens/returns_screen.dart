import 'package:clothes_pos/presentation/returns/screens/return_sale_detail_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/pos/screens/advanced_product_search_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/returns/bloc/returns_cubit.dart';
import 'package:clothes_pos/data/repositories/sales_repository.dart';
import 'package:clothes_pos/data/repositories/returns_repository.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:intl/intl.dart';

class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ReturnsCubit(sl<SalesRepository>(), sl<ReturnsRepository>())
            ..fetchSales(),
      child: const ReturnsView(),
    );
  }
}

class ReturnsView extends StatefulWidget {
  const ReturnsView({super.key});

  @override
  State<ReturnsView> createState() => _ReturnsViewState();
}

class _ReturnsViewState extends State<ReturnsView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('المرتجعات')),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CupertinoSearchTextField(
              onChanged: (value) {
                context.read<ReturnsCubit>().searchSales(value);
              },
              prefixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => AdvancedProductSearchScreen.open(context),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(CupertinoIcons.slider_horizontal_3, size: 18),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(CupertinoIcons.search, size: 18),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ReturnsCubit, ReturnsState>(
              builder: (context, state) {
                if (state.status == ReturnsStatus.initial ||
                    state.status == ReturnsStatus.loading &&
                        state.sales.isEmpty) {
                  return const Center(child: Text('لا توجد مرتجعات أو مبيعات'));
                }
                if (state.status == ReturnsStatus.failure) {
                  return Center(
                    child: Text('Failed to fetch sales: ${state.errorMessage}'),
                  );
                }
                if (state.sales.isEmpty) {
                  return const Center(child: Text('لا توجد مرتجعات أو مبيعات'));
                }
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: state.hasReachedMax
                      ? state.sales.length
                      : state.sales.length + 1,
                  itemBuilder: (BuildContext context, int index) {
                    if (index >= state.sales.length) {
                      return const SizedBox.shrink();
                    }
                    final sale = state.sales[index];
                    final saleDate = DateTime.parse(
                      sale['sale_date'] as String,
                    );
                    final formattedDate = DateFormat(
                      'yyyy-MM-dd HH:mm',
                    ).format(saleDate);
                    return CupertinoListTile(
                      title: Text('فاتورة رقم #${sale['id']}'),
                      subtitle: Text(
                        'الموظف: ${sale['user_name'] ?? 'N/A'} - التاريخ: $formattedDate',
                      ),
                      trailing: Text('${sale['total_amount']} د.ل'),
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<ReturnsCubit>(),
                              child: ReturnSaleDetailScreen(
                                saleId: sale['id'] as int,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) context.read<ReturnsCubit>().fetchSales();
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }
}

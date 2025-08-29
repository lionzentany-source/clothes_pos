import 'dart:async';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';

import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/inventory/bloc/stocktake_rfid_cubit.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/inventory/bloc/stocktake_cubit.dart';
import 'package:clothes_pos/presentation/common/money.dart';
import 'package:clothes_pos/data/models/inventory_item_row.dart';
import 'package:clothes_pos/presentation/common/widgets/action_button.dart';
import 'package:clothes_pos/presentation/common/widgets/variant_attributes_display.dart';

import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/product_repository.dart';

class StocktakeScreen extends StatefulWidget {
  const StocktakeScreen({super.key});

  @override
  State<StocktakeScreen> createState() => _StocktakeScreenState();
}

class _StocktakeScreenState extends State<StocktakeScreen> {
  final _controller = TextEditingController();
  StreamSubscription? _rfidSub;

  @override
  void initState() {
    super.initState();
    context.read<StocktakeCubit>().load();
    // Listen to RFID stream cubit to mark counted per unit
    _rfidSub = context.read<StocktakeRfidCubit>().stream.listen((s) {
      if (!mounted) return;
      final id = s.lastVariantId;
      if (id != null) {
        context.read<StocktakeCubit>().markCountedByVariant(id, units: 1);
      }
    });
  }

  @override
  void dispose() {
    _rfidSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppLocalizations.of(context).stocktakeTitle),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: CupertinoSearchTextField(
                controller: _controller,
                onChanged: (v) => context.read<StocktakeCubit>().load(query: v),
                placeholder: AppLocalizations.of(
                  context,
                ).searchProductPlaceholder,
              ),
            ),
            BlocBuilder<StocktakeCubit, StocktakeState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _Chip(
                              label: AppLocalizations.of(
                                context,
                              ).countedUnitsLabel,
                              value: state.countedUnits.toString(),
                            ),
                            const SizedBox(width: 8),
                            _Chip(
                              label: AppLocalizations.of(
                                context,
                              ).uncountedUnitsLabel,
                              value: state.uncountedUnits.toString(),
                            ),
                            const SizedBox(width: 8),
                            _Chip(
                              label: AppLocalizations.of(
                                context,
                              ).countedCostLabel,
                              value: money(context, state.totalCostCounted),
                            ),
                            const SizedBox(width: 8),
                            _Chip(
                              label: AppLocalizations.of(
                                context,
                              ).countedProfitLabel,
                              value: money(context, state.totalProfitCounted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    BlocListener<StocktakeRfidCubit, StocktakeRfidState>(
                      listenWhen: (prev, curr) =>
                          prev.error != curr.error && curr.error != null,
                      listener: (context, state) {
                        final errorText =
                            state.error?.toString() ?? 'حدث خطأ أثناء المسح';
                        if (!mounted) return;
                        showCupertinoDialog(
                          context: context,
                          builder: (_) => CupertinoAlertDialog(
                            title: const Text(
                              'تنبيه أثناء عملية المسح',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SingleChildScrollView(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight:
                                          MediaQuery.of(context).size.height *
                                          0.6,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          errorText,
                                          style: const TextStyle(
                                            color: Color(0xFFD32F2F),
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (errorText.contains('باركود'))
                                          const Text(
                                            'لم يتم العثور على منتج لهذا الباركود. يرجى التأكد من صحة الباركود أو إعادة المحاولة.',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        if (errorText.contains('الاتصال'))
                                          const Text(
                                            'تأكد من الاتصال بالجهاز أو القارئ قبل المسح.',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        if (errorText.contains('كمية'))
                                          const Text(
                                            'يرجى إدخال كمية موجبة فقط عند الجرد.',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('موافق'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const SizedBox.shrink(),
                    ),
                  ],
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionButton(
                      onPressed: () {
                        context.read<StocktakeRfidCubit>().start();
                      },
                      label: AppLocalizations.of(context).startRfid,
                    ),
                    const SizedBox(width: 8),
                    ActionButton(
                      onPressed: () {
                        context.read<StocktakeRfidCubit>().stop();
                      },
                      label: AppLocalizations.of(context).stopReading,
                    ),
                    const SizedBox(width: 8),
                    CupertinoSegmentedControl<int>(
                      padding: const EdgeInsets.all(2),
                      groupValue: context.select<StocktakeCubit, int>(
                        (c) => c.state.barcodeUnitsPerScan,
                      ),
                      children: {
                        1: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('x1'),
                        ),
                        5: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('x5'),
                        ),
                        10: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('x10'),
                        ),
                      },
                      onValueChanged: (v) => context
                          .read<StocktakeCubit>()
                          .setBarcodeUnitsPerScan(v),
                    ),
                    const SizedBox(width: 8),
                    ActionButton(
                      label: AppLocalizations.of(context).addByBarcode,
                      onPressed: () async {
                        try {
                          final code = await FlutterBarcodeScanner.scanBarcode(
                            '#ff6666',
                            'إلغاء',
                            true,
                            ScanMode.BARCODE,
                          );
                          if (!mounted || !context.mounted) return;
                          if (code == '-1') return;
                          // ابحث عن المتغير بالباركود وأضف وحدات حسب خيار المستخدم
                          final repo = sl<ProductRepository>();
                          final vs = await repo.searchVariants(
                            barcode: code,
                            limit: 1,
                          );
                          if (!mounted || !context.mounted) return;
                          if (vs.isEmpty) {
                            await showCupertinoDialog(
                              context: context,
                              builder: (dctx) => CupertinoAlertDialog(
                                title: Text(AppLocalizations.of(dctx).notFound),
                                content: Text(
                                  AppLocalizations.of(dctx).noProductForBarcode,
                                ),
                              ),
                            );
                            return;
                          }
                          final v = vs.first;
                          if (!mounted || !context.mounted) return;
                          final units = context
                              .read<StocktakeCubit>()
                              .state
                              .barcodeUnitsPerScan;
                          context.read<StocktakeCubit>().markCountedByVariant(
                            v.id!,
                            units: units,
                          );
                        } catch (e) {
                          if (!mounted || !context.mounted) return;
                          await showCupertinoDialog(
                            context: context,
                            builder: (_) => CupertinoAlertDialog(
                              title: const Text('خطأ المسح'),
                              content: Text(e.toString()),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<StocktakeCubit, StocktakeState>(
                builder: (context, state) {
                  if (state.loading) {
                    return const Center(child: CupertinoActivityIndicator());
                  }
                  final countedSet = state.countedUnitsByVariant.keys.toSet();
                  // ترتيب: غير مجرود أولاً ثم مجرود
                  final sorted = [...state.items];
                  sorted.sort((a, b) {
                    final aCounted = countedSet.contains(a.variant.id);
                    final bCounted = countedSet.contains(b.variant.id);
                    if (aCounted == bCounted) return 0;
                    return aCounted ? 1 : -1;
                  });
                  return ListView.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 1),
                    itemBuilder: (context, i) => _RowItem(
                      row: sorted[i],
                      counted: countedSet.contains(sorted[i].variant.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final InventoryItemRow row;
  final bool counted;
  const _RowItem({required this.row, required this.counted});

  @override
  Widget build(BuildContext context) {
    final v = row.variant;
    final subtitle = [
      if ((v.size ?? '').isNotEmpty)
        '${AppLocalizations.of(context).sizeLabel} ${v.size}',
      if ((v.color ?? '').isNotEmpty)
        '${AppLocalizations.of(context).colorLabel} ${v.color}',
      '${AppLocalizations.of(context).skuLabel} ${v.sku}',
      if ((v.barcode ?? '').isNotEmpty)
        '${AppLocalizations.of(context).barcodeLabel} ${v.barcode}',
    ].join('  •  ');

    return CupertinoListTile(
      leading: Icon(
        counted
            ? CupertinoIcons.check_mark_circled_solid
            : CupertinoIcons.clear_circled_solid,
        color: counted
            ? CupertinoColors.activeGreen
            : CupertinoColors.systemRed,
      ),
      title: Text(row.parentName, textDirection: TextDirection.rtl),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, textDirection: TextDirection.rtl),
          VariantAttributesDisplay(attributes: v.attributes),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${AppLocalizations.of(context).countedUnitsLabel}: '
            '${context.select<StocktakeCubit, int>((c) => c.state.countedUnitsByVariant[v.id] ?? 0)}  •  '
            '${AppLocalizations.of(context).quantityLabel} ${v.quantity}',
          ),
          const SizedBox(height: 4),
          Text(
            '${AppLocalizations.of(context).priceLabel} ${money(context, v.salePrice)}',
          ),
        ],
      ),
      onTap: () {
        // Toggle manual mark as counted/un-counted (per unit by 1)
        final cubit = context.read<StocktakeCubit>();
        final id = v.id!;
        if (counted) {
          cubit.unmarkVariant(id);
        } else {
          cubit.markCountedByVariant(id, units: 1);
        }
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  const _Chip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(label),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

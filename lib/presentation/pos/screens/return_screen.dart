import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/datasources/returns_dao.dart';
import 'package:clothes_pos/data/repositories/returns_repository.dart';
import 'package:clothes_pos/data/repositories/sales_repository.dart';
import 'package:clothes_pos/presentation/common/money.dart';
import 'package:clothes_pos/presentation/common/sql_error_helper.dart';
import 'package:clothes_pos/presentation/common/widgets/app_buttons.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';
import 'package:clothes_pos/presentation/design/system/app_typography.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/cupertino.dart';

enum ReturnType { product, fullInvoice }

class ReturnScreen extends StatefulWidget {
  const ReturnScreen({super.key});

  @override
  State<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends State<ReturnScreen> {
  // Repositories
  ReturnsRepository get _repo => sl<ReturnsRepository>();
  SalesRepository get _salesRepo => sl<SalesRepository>();

  // Controllers
  final _reasonCtrl = TextEditingController();
  final _searchController = TextEditingController();

  // State for sales list (right panel)
  List<Map<String, Object?>> _salesList = [];
  bool _loadingSales = false;
  Map<String, Object?>? _selectedSale;

  // State for return details (left panel)
  List<_ReturnLineModel> _lines = [];
  bool _loading = false;
  ReturnType _selectedReturnType = ReturnType.product;
  Map<String, dynamic>? _saleInfo;

  @override
  void initState() {
    super.initState();
    _loadSalesList();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSalesList() async {
    setState(() => _loadingSales = true);

    try {
      final sales = await _salesRepo.listSales(
        limit: 50,
        offset: 0,
        searchQuery: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );

      setState(() => _salesList = sales);
    } catch (e) {
      // Handle error silently or show toast
    } finally {
      setState(() => _loadingSales = false);
    }
  }

  Future<void> _selectSale(Map<String, Object?> sale) async {
    setState(() {
      _selectedSale = sale;
      _loading = true;
    });

    try {
      final saleId = sale['id'] as int;

      // Load sale basic info
      final saleInfo = await _salesRepo.getSaleInfo(saleId);
      if (saleInfo != null) {
        setState(() => _saleInfo = saleInfo);
      }

      // Load returnable items
      final rows = await _repo.getReturnableItems(saleId);
      _lines = rows
          .map(
            (r) => _ReturnLineModel(
              saleItemId: r['sale_item_id'] as int,
              variantId: r['variant_id'] as int,
              productName: r['product_name']?.toString() ?? 'منتج',
              remaining: r['remaining_qty'] as int,
              unitPrice: (r['price_per_unit'] as num).toDouble(),
              originalQty:
                  r['original_qty'] as int? ?? r['remaining_qty'] as int,
            ),
          )
          .toList();

      if (_selectedReturnType == ReturnType.fullInvoice) {
        // Auto-select all items for full invoice return
        for (final line in _lines) {
          line.qty = line.remaining;
        }
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        _showErrorDialog(l.error, e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _processReturn() async {
    final l = AppLocalizations.of(context);
    if (_selectedSale == null) return;

    final saleId = _selectedSale!['id'] as int;
    final items = <ReturnLineInput>[];
    double totalRefund = 0.0;

    for (final m in _lines) {
      if (m.qty > 0) {
        final refundAmount = m.qty * m.unitPrice;
        items.add(
          ReturnLineInput(
            saleItemId: m.saleItemId,
            variantId: m.variantId,
            quantity: m.qty,
            refundAmount: refundAmount,
          ),
        );
        totalRefund += refundAmount;
      }
    }

    if (items.isEmpty) {
      _showErrorDialog(l.error, l.noReturnableItems);
      return;
    }

    // Show confirmation dialog with total refund amount
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l.confirm),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${l.returnType}: ${_selectedReturnType == ReturnType.product ? l.returnProduct : l.returnFullInvoice}',
            ),
            const SizedBox(height: 8),
            Text('${l.totalRefund}: ${money(context, totalRefund)}'),
            if (_reasonCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${l.returnReason}: ${_reasonCtrl.text.trim()}'),
            ],
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.processReturn),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _loading = true);
      await _repo.createReturn(
        saleId: saleId,
        userId: 1,
        reason: _reasonCtrl.text.trim().isEmpty
            ? null
            : _reasonCtrl.text.trim(),
        items: items,
      );

      if (!mounted) return;
      await showCupertinoDialog(
        context: context,
        builder: (dialogCtx) => CupertinoAlertDialog(
          title: Text(l.returnSuccessTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.returnSuccessMessage),
              const SizedBox(height: 8),
              Text('${l.totalRefund}: ${money(context, totalRefund)}'),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                // Clear form after successful return
                _clearForm();
                // Refresh sales list
                _loadSalesList();
              },
              child: Text(l.ok),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final friendly = SqlErrorHelper.toArabicMessage(e);
      _showErrorDialog(l.error, friendly);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearForm() {
    setState(() {
      _reasonCtrl.clear();
      _lines.clear();
      _saleInfo = null;
      _selectedSale = null;
      _selectedReturnType = ReturnType.product;
    });
  }

  void _showErrorDialog(String title, String message) {
    if (!context.mounted) return; // safety
    showCupertinoDialog(
      context: context,
      builder: (dialogCtx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(AppLocalizations.of(context).ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(l.returnService)),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 700;

            Widget salesListBuilder() {
              return Column(
                children: [
                  // Search Bar
                  Container(
                    margin: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'بحث في الفواتير',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: CupertinoTextField(
                                controller: _searchController,
                                placeholder: 'رقم الفاتورة...',
                                keyboardType: TextInputType.number,
                                textDirection: TextDirection.ltr,
                                decoration: BoxDecoration(
                                  color: CupertinoColors.tertiarySystemFill,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppIconButton(
                              onPressed: _loadSalesList,
                              icon: const Icon(CupertinoIcons.search),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Sales List
                  Expanded(
                    child: _loadingSales
                        ? const Center(child: CupertinoActivityIndicator())
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _salesList.length,
                            itemBuilder: (context, index) {
                              final sale = _salesList[index];
                              final isSelected =
                                  _selectedSale?['id'] == sale['id'];

                              return Column(
                                children: [
                                  _SaleListItem(
                                    sale: sale,
                                    selected: isSelected,
                                    onPressed: () => _selectSale(sale),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              );
            }

            Widget buildReturnDetails() {
              if (_selectedSale == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.arrow_turn_up_left,
                        size: 64,
                        color: context.colors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'اختر فاتورة من القائمة الجانبية للإرجاع',
                        style: TextStyle(
                          fontSize: 18,
                          color: context.colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Selected Sale Info
                    if (_saleInfo != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'فاتورة رقم ${_selectedSale!['id']}',
                              style: AppTypography.bodyStrong.copyWith(
                                color: context.colors.textPrimary,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'التاريخ: ${_saleInfo!['created_at']?.toString().split(' ')[0] ?? 'غير محدد'}',
                              style: AppTypography.body.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                            Text(
                              'المبلغ الإجمالي: ${money(context, (_saleInfo!['total'] as num?)?.toDouble() ?? 0.0)}',
                              style: AppTypography.body.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Return Type Selection
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.returnType,
                            style: AppTypography.bodyStrong.copyWith(
                              color: context.colors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          CupertinoSlidingSegmentedControl<ReturnType>(
                            groupValue: _selectedReturnType,
                            children: {
                              ReturnType.product: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Text(
                                  l.returnProduct,
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              ReturnType.fullInvoice: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Text(
                                  l.returnFullInvoice,
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            },
                            onValueChanged: (value) {
                              setState(() {
                                _selectedReturnType = value!;
                                // Clear selection when changing type
                                for (final line in _lines) {
                                  line.qty =
                                      _selectedReturnType ==
                                          ReturnType.fullInvoice
                                      ? line.remaining
                                      : 0;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Return Reason
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.returnReasonOptional,
                            style: AppTypography.bodyStrong.copyWith(
                              color: context.colors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          CupertinoTextField(
                            controller: _reasonCtrl,
                            placeholder: l.returnReasonOptional,
                            textDirection: TextDirection.rtl,
                            maxLines: 3,
                            decoration: BoxDecoration(
                              color: CupertinoColors.tertiarySystemFill,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(12),
                          ),
                        ],
                      ),
                    ),

                    // Return Items
                    if (_lines.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.returnItemsTitle,
                              style: AppTypography.bodyStrong.copyWith(
                                color: context.colors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...(_lines.map(
                              (line) => _ReturnLineEditor(
                                model: line,
                                returnType: _selectedReturnType,
                                onChanged: () => setState(() {}),
                              ),
                            )),

                            // Total Refund Summary
                            if (_lines.any((line) => line.qty > 0)) ...[
                              Container(
                                margin: const EdgeInsets.only(
                                  top: AppSpacing.sm,
                                ),
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemGreen.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: CupertinoColors.systemGreen,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      l.totalRefund,
                                      style: AppTypography.bodyStrong.copyWith(
                                        color: CupertinoColors.systemGreen,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      money(
                                        context,
                                        _lines.fold<double>(
                                          0.0,
                                          (sum, line) =>
                                              sum + (line.qty * line.unitPrice),
                                        ),
                                      ),
                                      style: AppTypography.bodyStrong.copyWith(
                                        color: CupertinoColors.systemGreen,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Process Return Button
                              const SizedBox(height: AppSpacing.md),
                              AppPrimaryButton(
                                onPressed: _loading ? null : _processReturn,
                                child: _loading
                                    ? const CupertinoActivityIndicator(
                                        color: CupertinoColors.white,
                                      )
                                    : Text(l.processReturn),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            if (isWide) {
              return Row(
                textDirection: TextDirection.ltr,
                children: [
                  Expanded(child: buildReturnDetails()),
                  Container(
                    width: 360,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: context.colors.border),
                      ),
                      color: context.colors.surfaceAlt,
                    ),
                    child: salesListBuilder(),
                  ),
                ],
              );
            }

            return salesListBuilder();
          },
        ),
      ),
    );
  }
}

/// عنصر فاتورة في القائمة الجانبية
class _SaleListItem extends StatelessWidget {
  final Map<String, Object?> sale;
  final bool selected;
  final VoidCallback onPressed;

  const _SaleListItem({
    required this.sale,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected ? context.colors.surface : Colors.transparent;
    final textColor = context.colors.textPrimary;
    final iconColor = selected
        ? context.colors.primary
        : context.colors.textSecondary;

    final saleId = sale['id'] as int;
    final totalAmount = (sale['total_amount'] as num?)?.toDouble() ?? 0.0;
    final saleDate = sale['sale_date'] as String?;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: context.colors.border.withValues(alpha: 0.3))
              : null,
        ),
        child: AppTextButton(
          onPressed: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.doc_text,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'فاتورة #$saleId',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        money(context, totalAmount),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.systemGreen,
                        ),
                      ),
                      if (saleDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          saleDate.split(' ')[0],
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 18,
                  color: context.colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReturnLineModel {
  final int saleItemId;
  final int variantId;
  final String productName;
  final int remaining;
  final double unitPrice;
  final int originalQty;
  int qty = 0;

  _ReturnLineModel({
    required this.saleItemId,
    required this.variantId,
    required this.productName,
    required this.remaining,
    required this.unitPrice,
    required this.originalQty,
  });
}

class _ReturnLineEditor extends StatefulWidget {
  final _ReturnLineModel model;
  final ReturnType returnType;
  final VoidCallback onChanged;

  const _ReturnLineEditor({
    required this.model,
    required this.returnType,
    required this.onChanged,
  });

  @override
  State<_ReturnLineEditor> createState() => _ReturnLineEditorState();
}

class _ReturnLineEditorState extends State<_ReturnLineEditor> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = context.colors;
    final m = widget.model;
    final isFullInvoice = widget.returnType == ReturnType.fullInvoice;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.productName,
                      style: AppTypography.bodyStrong.copyWith(
                        color: colors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l.quantityLabel} ${m.originalQty} - المتبقي: ${m.remaining}',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    Text(
                      '${l.unitPrice}: ${money(context, m.unitPrice)}',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isFullInvoice) ...[
                const SizedBox(width: AppSpacing.sm),
                Row(
                  children: [
                    AppIconButton(
                      onPressed: m.qty > 0
                          ? () {
                              setState(() => m.qty--);
                              widget.onChanged();
                            }
                          : null,
                      icon: const Icon(
                        CupertinoIcons.minus_circle,
                        size: 32,
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                    Container(
                      width: 60,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        '${m.qty}',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyStrong.copyWith(
                          color: colors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    AppIconButton(
                      onPressed: m.qty < m.remaining
                          ? () {
                              setState(() => m.qty++);
                              widget.onChanged();
                            }
                          : null,
                      icon: const Icon(
                        CupertinoIcons.add_circled,
                        size: 32,
                        color: CupertinoColors.systemGreen,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // For full invoice return, show qty but disabled
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: CupertinoColors.systemGreen),
                  ),
                  child: Text(
                    '${l.returnQty}: ${m.qty}',
                    style: AppTypography.bodyStrong.copyWith(
                      color: CupertinoColors.systemGreen,
                    ),
                  ),
                ),
              ],
            ],
          ),

          if (m.qty > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${l.totalRefund}: ${money(context, m.qty * m.unitPrice)}',
                style: AppTypography.caption.copyWith(
                  color: CupertinoColors.systemBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

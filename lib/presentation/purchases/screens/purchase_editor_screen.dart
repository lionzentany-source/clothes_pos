import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/models/purchase_invoice.dart';
import 'package:clothes_pos/data/models/purchase_invoice_item.dart';
import 'package:clothes_pos/data/models/supplier.dart';
import 'package:clothes_pos/data/repositories/purchase_repository.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:clothes_pos/data/repositories/product_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/common/widgets/app_labeled_field.dart';
import 'package:clothes_pos/presentation/common/widgets/floating_modal.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/core/auth/permissions.dart';
import 'package:clothes_pos/presentation/common/view_only_banner.dart';

import 'package:clothes_pos/presentation/common/sql_error_helper.dart';

import 'package:clothes_pos/presentation/common/widgets/action_button.dart';
import 'package:clothes_pos/presentation/common/widgets/variant_attributes_display.dart';
import 'package:clothes_pos/presentation/common/overlay/app_toast.dart';

import 'supplier_search_page.dart';
import 'parent_search_page.dart';

class PurchaseEditorScreen extends StatefulWidget {
  const PurchaseEditorScreen({super.key});

  @override
  State<PurchaseEditorScreen> createState() => _PurchaseEditorScreenState();
}

class _PurchaseEditorScreenState extends State<PurchaseEditorScreen> {
  final _supplierIdCtrl = TextEditingController();
  int? _supplierId;
  final _referenceCtrl = TextEditingController();
  final _items = <_ItemEditModel>[_ItemEditModel.empty()];
  bool _saving = false;
  DateTime _receivedDate = DateTime.now();
  String? _supplierName;

  Future<void> _pickVariant(int index) async {
    final selected = await FloatingModal.showWithSize<ProductVariant>(
      context: context,
      title: AppLocalizations.of(context).selectVariant,
      size: ModalSize.large,
      scrollable: false,
      child: const ParentSearchPage(),
    );
    if (selected != null && mounted) {
      setState(() {
        final model = _items[index];
        model.selectedVariant = selected;
        // Fetch parent name and display it with the variant details
        try {
          final parent = sl<ProductRepository>().getParentById(
            selected.parentProductId,
          );
          parent.then((p) {
            if (!mounted) return;
            setState(() {
              final parentName = p?.name ?? '';
              final details = getFullVariantName(selected);
              model.variantId.text = parentName.isNotEmpty
                  ? '$parentName${details.isNotEmpty ? ' • $details' : ''}'
                  : (details.isNotEmpty ? details : 'Variant');
            });
          });
        } catch (_) {
          model.variantId.text = getFullVariantName(selected);
        }
        if (model.cost.text.trim() == '0') {
          model.cost.text = (selected.costPrice).toString();
          model.baseCost = selected.costPrice;
        }
        if (model.salePrice.text.trim() == '0') {
          model.salePrice.text = (selected.salePrice).toString();
        }
        model.baseCost ??= double.tryParse(model.cost.text.trim());
      });
    }
  }

  PurchaseRepository get _repo => sl<PurchaseRepository>();

  @override
  void dispose() {
    _supplierIdCtrl.dispose();
    _referenceCtrl.dispose();
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  void _addItem() => setState(() => _items.add(_ItemEditModel.empty()));
  void _removeItem(int i) => setState(() => _items.removeAt(i));

  Future<void> _save() async {
    final supplierId = _supplierId ?? int.tryParse(_supplierIdCtrl.text.trim());
    if (supplierId == null) {
      _showError(AppLocalizations.of(context).supplierIdRequired);
      return;
    }
    final items = <PurchaseInvoiceItem>[];
    final salePriceUpdates = <Map<String, dynamic>>[];
    if (_items.isEmpty) {
      _showError(AppLocalizations.of(context).addAtLeastOne);
      return;
    }
    for (final m in _items) {
      try {
        // Prefer selectedVariant.id (keeps UI free of numeric IDs)
        final variantId =
            m.selectedVariant?.id ?? int.tryParse(m.variantId.text.trim());
        final qty = int.tryParse(m.quantity.text.trim());
        final cost = double.tryParse(m.cost.text.trim());
        final salePrice = double.tryParse(m.salePrice.text.trim());
        if (variantId == null) {
          _showError(AppLocalizations.of(context).pickVariant);
          return;
        }
        if (qty == null || qty <= 0) {
          _showError(AppLocalizations.of(context).qtyMustBePositive);
          return;
        }
        if (cost == null || cost < 0) {
          _showError(AppLocalizations.of(context).costMustBePositive);
          return;
        }
        if (salePrice == null || salePrice < 0) {
          _showError(AppLocalizations.of(context).enterValidNumber);
          return;
        }
        // Validate RFID count not exceeding quantity (optional warning)
        try {
          if (m.rfids.length > qty) {
            _showError(
              AppLocalizations.of(
                context,
              ).rfidExceedsQty(m.rfids.length.toString(), qty.toString()),
            );
            return;
          }
        } catch (e) {
          _showError('خطأ أثناء التحقق من RFID: ${e.toString()}');
          return;
        }
        items.add(
          PurchaseInvoiceItem(
            purchaseInvoiceId: 0,
            variantId: variantId,
            quantity: qty,
            costPrice: cost,
          ),
        );
        salePriceUpdates.add({'id': variantId, 'salePrice': salePrice});
      } catch (e) {
        _showError('خطأ في معالجة بيانات الجهاز: ${e.toString()}');
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final invoice = PurchaseInvoice(
        supplierId: supplierId,
        reference: _referenceCtrl.text.trim().isEmpty
            ? null
            : _referenceCtrl.text.trim(),
        receivedDate: _receivedDate,
      );
      final rfidsByItem = _items
          .map((e) => List<String>.from(e.rfids))
          .toList();
      await _repo.createInvoiceWithRfids(invoice, items, rfidsByItem);

      // Update sale prices for affected variants
      final prodRepo = sl<ProductRepository>();
      for (final u in salePriceUpdates) {
        await prodRepo.updateVariantSalePrice(
          variantId: u['id'] as int,
          salePrice: u['salePrice'] as double,
        );
      }

      if (!mounted) return;
      // Reset form after successful save so the user knows it's saved.
      _resetFormAfterSave();
      // Show a lightweight success toast (non-blocking)
      AppToast.show(
        context,
        message: AppLocalizations.of(context).infoSaved,
        type: ToastType.success,
      );
    } catch (e) {
      final friendly = SqlErrorHelper.toArabicMessage(e);
      _showError(friendly);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _resetFormAfterSave() {
    setState(() {
      _supplierId = null;
      _supplierName = null;
      _supplierIdCtrl.clear();
      _referenceCtrl.clear();
      // Reset items to a single empty row
      for (final i in _items) {
        i.dispose();
      }
      _items
        ..clear()
        ..add(_ItemEditModel.empty());
      _receivedDate = DateTime.now();
      _saving = false;
    });
  }

  void _showError(String msg) {
    if (!context.mounted) return; // safety
    showCupertinoDialog(
      context: context,
      builder: (dialogCtx) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context).error),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(AppLocalizations.of(context).ok),
            onPressed: () => Navigator.of(dialogCtx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPurchase =
        context.watch<AuthCubit>().state.user?.permissions.contains(
          AppPermissions.performPurchases,
        ) ??
        false;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppLocalizations.of(context).purchaseInvoiceTitle),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: (_saving || !canPurchase) ? null : _save,
          child: _saving
              ? const CupertinoActivityIndicator()
              : Text(AppLocalizations.of(context).save),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          children: [
            if (!canPurchase)
              const ViewOnlyBanner(
                message: 'عرض فقط: لا تملك صلاحية إنشاء/تعديل فواتير المشتريات',
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              ),
            // Supplier field (RTL aligned)
            SizedBox(
              width: 180,
              child: AppLabeledField(
                label: AppLocalizations.of(context).supplier,
                controller: _supplierIdCtrl,
                readOnly: true,
                placeholder: AppLocalizations.of(context).supplier,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppInlineIconButton(
                      icon: CupertinoIcons.search,
                      onTap: !canPurchase
                          ? () {}
                          : () async {
                              final selected =
                                  await FloatingModal.showWithSize<Supplier>(
                                    context: context,
                                    title: AppLocalizations.of(
                                      context,
                                    ).supplier,
                                    size: ModalSize.medium,
                                    scrollable: false,
                                    child: const SupplierSearchPage(),
                                  );
                              if (selected != null) {
                                setState(() {
                                  // Keep the numeric id internally, but show only the name
                                  _supplierId = selected.id;
                                  _supplierIdCtrl.text = selected.name;
                                  _supplierName = selected.name;
                                });
                              }
                            },
                    ),
                    if (_supplierName != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'المورد: $_supplierName',
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ),
                    if (_supplierIdCtrl.text.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 6),
                        child: AppInlineIconButton(
                          icon: CupertinoIcons.xmark_circle_fill,
                          color: CupertinoColors.systemRed,
                          onTap: !canPurchase
                              ? () {}
                              : () => setState(() {
                                  _supplierIdCtrl.text = '';
                                  _supplierName = null;
                                  _supplierId = null;
                                }),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Received date row (moved up)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 0),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: !canPurchase
                        ? null
                        : () async {
                            final picked =
                                await showCupertinoModalPopup<DateTime>(
                                  context: context,
                                  builder: (ctx) {
                                    DateTime tmp = _receivedDate;
                                    return Container(
                                      height: 260,
                                      color: CupertinoColors.systemBackground,
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            height: 200,
                                            child: CupertinoDatePicker(
                                              initialDateTime: _receivedDate,
                                              mode:
                                                  CupertinoDatePickerMode.date,
                                              onDateTimeChanged: (d) => tmp = d,
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              CupertinoButton(
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(),
                                                child: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  ).cancel,
                                                ),
                                              ),
                                              CupertinoButton(
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(tmp),
                                                child: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  ).done,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                            if (picked != null && mounted) {
                              setState(() => _receivedDate = picked);
                            }
                          },
                    child: Text(AppLocalizations.of(context).change),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_receivedDate.year}-${_receivedDate.month.toString().padLeft(2, '0')}-${_receivedDate.day.toString().padLeft(2, '0')}',
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).receivedDate,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            // Reference field (moved below date)
            SizedBox(
              width: 180,
              child: AppLabeledField(
                label: AppLocalizations.of(context).referenceOptional,
                controller: _referenceCtrl,
                trailing: const Icon(
                  CupertinoIcons.tag,
                  size: 16,
                  color: CupertinoColors.inactiveGray,
                ),
              ),
            ),
            // Items section title
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  AppLocalizations.of(context).items,
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
            for (int i = 0; i < _items.length; i++)
              _ItemEditor(
                model: _items[i],
                onRemove: canPurchase ? () => _removeItem(i) : null,
                onPickVariant: canPurchase ? () => _pickVariant(i) : null,
                canEdit: canPurchase,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ActionButton(
                label: AppLocalizations.of(context).addItem,
                onPressed: canPurchase ? _addItem : null,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ItemEditModel {
  final TextEditingController variantId;
  final TextEditingController quantity;
  final TextEditingController cost;
  final List<String> rfids;
  ProductVariant? selectedVariant;
  double? baseCost;
  final TextEditingController salePrice;
  _ItemEditModel({
    required this.variantId,
    required this.quantity,
    required this.cost,
    required this.salePrice,
    List<String>? rfids,
  }) : rfids = rfids ?? [];
  factory _ItemEditModel.empty() => _ItemEditModel(
    variantId: TextEditingController(),
    quantity: TextEditingController(text: '0'),
    cost: TextEditingController(text: '0'),
    salePrice: TextEditingController(text: '0'),
  );
  void dispose() {
    variantId.dispose();
    quantity.dispose();
    cost.dispose();
    salePrice.dispose();
    rfids.clear();
  }
}

class _ItemEditor extends StatelessWidget {
  final _ItemEditModel model;
  final VoidCallback? onRemove;
  final VoidCallback? onPickVariant;
  final bool canEdit;

  const _ItemEditor({
    required this.model,
    this.onRemove,
    this.onPickVariant,
    this.canEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CupertinoColors.systemGrey4, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppLabeledField(
                              label: l.selectVariant,
                              controller: model.variantId,
                              readOnly: true,
                              placeholder: l.selectVariant,
                              trailing: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: canEdit ? onPickVariant : null,
                                child: Icon(
                                  CupertinoIcons.search,
                                  color: CupertinoColors.activeBlue,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 110,
                            child: AppLabeledField(
                              label: l.quantity,
                              controller: model.quantity,
                              placeholder: l.quantity,
                              readOnly: !canEdit,
                            ),
                          ),
                        ],
                      ),
                      if (model.selectedVariant != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, right: 2),
                          child: Text(
                            getFullVariantName(model.selectedVariant!),
                            style: const TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.label,
                              fontWeight: FontWeight.w500,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      if (model.selectedVariant != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, right: 2),
                          child: VariantAttributesDisplay(
                            attributes: model.selectedVariant!.attributes,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: AppLabeledField(
                              label: l.cost,
                              controller: model.cost,
                              placeholder: l.cost,
                              readOnly: !canEdit,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppLabeledField(
                              label: l.priceLabel,
                              controller: model.salePrice,
                              placeholder: l.priceLabel,
                              readOnly: !canEdit,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (onRemove != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: canEdit ? onRemove : null,
                    child: Icon(
                      CupertinoIcons.delete,
                      color: CupertinoColors.destructiveRed,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String getFullVariantName(ProductVariant variant) {
  final sku = variant.sku ?? '';
  final size = variant.size ?? '';
  final color = variant.color ?? '';
  List<String> parts = [];
  if (sku.isNotEmpty) parts.add('[$sku]');
  if (color.isNotEmpty) parts.add(color);
  if (size.isNotEmpty) parts.add(size);
  return parts.join(' ');
}

import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';
import 'package:clothes_pos/data/models/purchase_invoice.dart';
import 'package:clothes_pos/data/models/purchase_invoice_item.dart';
import 'package:clothes_pos/data/repositories/purchase_repository.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/common/widgets/app_labeled_field.dart';
import 'package:clothes_pos/l10n/app_localizations.dart';
import 'package:clothes_pos/presentation/common/widgets/rfid_scan_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/core/auth/permissions.dart';
import 'package:clothes_pos/presentation/common/view_only_banner.dart';

import 'variant_search_page.dart';
import 'supplier_search_page.dart';

class PurchaseEditorScreen extends StatefulWidget {
  const PurchaseEditorScreen({super.key});

  @override
  State<PurchaseEditorScreen> createState() => _PurchaseEditorScreenState();
}

class _PurchaseEditorScreenState extends State<PurchaseEditorScreen> {
  final _supplierIdCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _items = <_ItemEditModel>[_ItemEditModel.empty()];
  bool _saving = false;
  DateTime _receivedDate = DateTime.now();

  Future<void> _pickVariant(int index) async {
    final selected = await Navigator.of(context).push<ProductVariant>(
      CupertinoPageRoute(builder: (_) => const VariantSearchPage()),
    );
    if (selected != null && mounted) {
      setState(() {
        _items[index].selectedVariant = selected;
        _items[index].variantId.text = selected.id?.toString() ?? '';
        if (_items[index].cost.text.trim() == '0') {
          _items[index].cost.text = (selected.costPrice).toString();
        }
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
    final supplierId = int.tryParse(_supplierIdCtrl.text.trim());
    if (supplierId == null) {
      _showError(AppLocalizations.of(context)!.supplierIdRequired);
      return;
    }
    final items = <PurchaseInvoiceItem>[];
    if (_items.isEmpty) {
      _showError(AppLocalizations.of(context)!.addAtLeastOne);
      return;
    }
    for (final m in _items) {
      final variantId = int.tryParse(m.variantId.text.trim());
      final qty = int.tryParse(m.quantity.text.trim());
      final cost = double.tryParse(m.cost.text.trim());
      if (variantId == null) {
        _showError(AppLocalizations.of(context)!.pickVariant);
        return;
      }
      if (qty == null || qty <= 0) {
        _showError(AppLocalizations.of(context)!.qtyMustBePositive);
        return;
      }
      if (cost == null || cost < 0) {
        _showError(AppLocalizations.of(context)!.costMustBePositive);
        return;
      }
      // Validate RFID count not exceeding quantity (optional warning)
      if (m.rfids.length > qty) {
        _showError(
          AppLocalizations.of(
            context,
          )!.rfidExceedsQty(m.rfids.length.toString(), qty.toString()),
        );
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
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _showError(AppLocalizations.of(context)!.invoiceSaveFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (dialogCtx) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context)!.error),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(AppLocalizations.of(context)!.ok),
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
        middle: Text(AppLocalizations.of(context)!.purchaseInvoiceTitle),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: (_saving || !canPurchase) ? null : _save,
          child: _saving
              ? const CupertinoActivityIndicator()
              : Text(AppLocalizations.of(context)!.save),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (!canPurchase)
              ViewOnlyBanner(
                message: AppLocalizations.of(
                  context,
                )!.purchaseEditorViewOnlyWarning,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              ),
            AppLabeledField(
              label: AppLocalizations.of(context)!.supplier,
              controller: _supplierIdCtrl,
              readOnly: true,
              placeholder: AppLocalizations.of(context)!.supplier,
              trailing: AppInlineIconButton(
                icon: CupertinoIcons.search,
                onTap: !canPurchase
                    ? () {}
                    : () async {
                        final selected = await Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => const SupplierSearchPage(),
                          ),
                        );
                        if (selected != null) {
                          setState(() {
                            _supplierIdCtrl.text =
                                selected.id?.toString() ?? '';
                          });
                        }
                      },
              ),
            ),
            AppLabeledField(
              label: AppLocalizations.of(context)!.referenceOptional,
              controller: _referenceCtrl,
              trailing: const Icon(
                CupertinoIcons.tag,
                size: 16,
                color: CupertinoColors.inactiveGray,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                AppLocalizations.of(context)!.receivedDate,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_receivedDate.year}-${_receivedDate.month.toString().padLeft(2, '0')}-${_receivedDate.day.toString().padLeft(2, '0')}',
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text(AppLocalizations.of(context)!.change),
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
                                                child: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.cancel,
                                                ),
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(),
                                              ),
                                              CupertinoButton(
                                                child: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!.done,
                                                ),
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(tmp),
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
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                AppLocalizations.of(context)!.items,
                textDirection: TextDirection.rtl,
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
              child: CupertinoButton(
                onPressed: canPurchase ? _addItem : null,
                color: CupertinoColors.activeBlue,
                child: Text(AppLocalizations.of(context)!.addItem),
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
  _ItemEditModel({
    required this.variantId,
    required this.quantity,
    required this.cost,
    List<String>? rfids,
  }) : rfids = rfids ?? [];
  factory _ItemEditModel.empty() => _ItemEditModel(
    variantId: TextEditingController(),
    quantity: TextEditingController(text: '0'),
    cost: TextEditingController(text: '0'),
  );
  void dispose() {
    variantId.dispose();
    quantity.dispose();
    cost.dispose();
    rfids.clear();
  }
}

class _ItemEditor extends StatefulWidget {
  final _ItemEditModel model;
  final VoidCallback? onRemove;
  final VoidCallback? onPickVariant;
  final bool canEdit;
  const _ItemEditor({
    required this.model,
    required this.onRemove,
    required this.onPickVariant,
    required this.canEdit,
  });

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  Widget _scanRfidButton(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(AppLocalizations.of(context)!.scanRfid),
      onPressed: () async {
        try {
          final settings = sl<SettingsRepository>();
          final enabled = await settings.get('rfid_enabled');
          if (!mounted) return; // ensure widget still in tree
          final enabledBool =
              enabled == '1' || (enabled?.toLowerCase() == 'true');
          if (!enabledBool) {
            final l = AppLocalizations.of(context)!;
            await showCupertinoDialog(
              context: context,
              builder: (dialogCtx) => CupertinoAlertDialog(
                title: Text(l.notEnabled),
                content: Text(l.enableRfidFirst),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: Text(l.ok),
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                  ),
                ],
              ),
            );
            if (!mounted) return;
            return;
          }
          final loc = AppLocalizations.of(context)!;
          final seen = await showRfidScanDialog(context) ?? <String>[];
          if (!mounted) return;
          final qty = int.tryParse(widget.model.quantity.text.trim()) ?? 0;
          int added = 0;
          int ignored = 0;
          for (final epc in seen) {
            if (qty > 0 && widget.model.rfids.length >= qty) {
              ignored++;
              continue;
            }
            if (!widget.model.rfids.contains(epc)) {
              widget.model.rfids.add(epc);
              added++;
            }
          }
          if (added > 0) setState(() {});
          if (ignored > 0 && mounted) {
            await showCupertinoDialog(
              context: context,
              builder: (_) => CupertinoAlertDialog(
                title: Text(loc.warning),
                content: Text(
                  loc.addedIgnored(added.toString(), ignored.toString()),
                ),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: Text(loc.ok),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          }
        } catch (e) {
          if (!mounted) return;
          final l = AppLocalizations.of(context)!;
          await showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: Text(l.scanError),
              content: Text(e.toString()),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text(l.ok),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final selected = widget.model.selectedVariant;
    final variantLabel = selected == null
        ? loc.selectVariant
        : '${selected.sku} — ${selected.size ?? ''} ${selected.color ?? ''}'
              .trim();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGroupedBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.item, textDirection: TextDirection.rtl),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: widget.canEdit ? widget.onRemove : null,
                child: Text(loc.delete),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: widget.canEdit ? widget.onPickVariant : null,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(variantLabel, textDirection: TextDirection.rtl),
                  ),
                ),
              ),
              Expanded(
                child: AppLabeledField(
                  label: loc.quantity,
                  controller: widget.model.quantity,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: AppLabeledField(
                  label: loc.cost,
                  controller: widget.model.cost,
                  keyboardType: TextInputType.number,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          // RFID tags list and adder
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              loc.rfidCardsOptional,
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final epc in widget.model.rfids)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(epc, textDirection: TextDirection.ltr),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () =>
                            setState(() => widget.model.rfids.remove(epc)),
                        child: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          size: 18,
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.canEdit) _scanRfidButton(context),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(AppLocalizations.of(context)!.addRfidCard),
                onPressed: !widget.canEdit
                    ? null
                    : () async {
                        final epc = await showCupertinoDialog<String>(
                          context: context,
                          builder: (ctx) {
                            final ctrl = TextEditingController();
                            return CupertinoAlertDialog(
                              title: Text(
                                AppLocalizations.of(context)!.addRfidTitle,
                              ),
                              content: Column(
                                children: [
                                  const SizedBox(height: 8),
                                  CupertinoTextField(
                                    controller: ctrl,
                                    placeholder: AppLocalizations.of(
                                      context,
                                    )!.epcPlaceholder,
                                    textDirection: TextDirection.ltr,
                                  ),
                                ],
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  child: Text(
                                    AppLocalizations.of(context)!.cancel,
                                  ),
                                  onPressed: () => Navigator.of(ctx).pop(),
                                ),
                                CupertinoDialogAction(
                                  isDefaultAction: true,
                                  child: Text(
                                    AppLocalizations.of(context)!.addAction,
                                  ),
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(ctrl.text.trim()),
                                ),
                              ],
                            );
                          },
                        );
                        if (epc != null && epc.isNotEmpty) {
                          final qty =
                              int.tryParse(widget.model.quantity.text.trim()) ??
                              0;
                          if (qty > 0 && widget.model.rfids.length >= qty) {
                            showCupertinoDialog(
                              context: context,
                              builder: (_) => CupertinoAlertDialog(
                                title: Text(
                                  AppLocalizations.of(context)!.warning,
                                ),
                                content: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.rfiCardsLimitReached,
                                ),
                              ),
                            );
                            return;
                          }
                          if (!widget.model.rfids.contains(epc)) {
                            setState(() => widget.model.rfids.add(epc));
                          }
                        }
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RfidScanDialog extends StatefulWidget {
  final VoidCallback onStop;
  final List<String> seen;
  final List<Object> errors;
  const _RfidScanDialog({
    required this.onStop,
    required this.seen,
    required this.errors,
  });
  @override
  State<_RfidScanDialog> createState() => _RfidScanDialogState();
}

class _RfidScanDialogState extends State<_RfidScanDialog> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return CupertinoAlertDialog(
      title: Text(l.scanning),
      content: SizedBox(
        height: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(l.pressStop),
            const SizedBox(height: 8),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: ListView.builder(
                      itemCount: widget.seen.length,
                      itemBuilder: (c, i) => Text(
                        widget.seen[i],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.errors.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                widget.errors.first.toString(),
                style: const TextStyle(
                  color: CupertinoColors.systemRed,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          child: Text(l.stop),
          onPressed: widget.onStop,
        ),
      ],
    );
  }
}

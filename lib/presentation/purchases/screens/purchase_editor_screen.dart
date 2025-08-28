import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';
import 'package:clothes_pos/data/models/purchase_invoice.dart';
import 'package:clothes_pos/data/models/purchase_invoice_item.dart';
import 'package:clothes_pos/data/repositories/purchase_repository.dart';
import 'package:clothes_pos/data/models/product_variant.dart';
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/common/widgets/app_labeled_field.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';
import 'package:clothes_pos/presentation/common/widgets/rfid_scan_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/presentation/auth/bloc/auth_cubit.dart';
import 'package:clothes_pos/core/auth/permissions.dart';
import 'package:clothes_pos/presentation/common/view_only_banner.dart';

import 'package:clothes_pos/presentation/common/sql_error_helper.dart';

import 'package:clothes_pos/presentation/common/widgets/action_button.dart';

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
  String? _supplierName;

  Future<void> _pickVariant(int index) async {
    final selected = await Navigator.of(context).push<ProductVariant>(
      CupertinoPageRoute(builder: (_) => const VariantSearchPage()),
    );
    if (selected != null && mounted) {
      setState(() {
        final model = _items[index];
        model.selectedVariant = selected;
        model.variantId.text = selected.id?.toString() ?? '';
        if (model.cost.text.trim() == '0') {
          model.cost.text = (selected.costPrice).toString();
          model.baseCost = selected.costPrice;
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
    final supplierId = int.tryParse(_supplierIdCtrl.text.trim());
    if (supplierId == null) {
      _showError(AppLocalizations.of(context).supplierIdRequired);
      return;
    }
    final items = <PurchaseInvoiceItem>[];
    if (_items.isEmpty) {
      _showError(AppLocalizations.of(context).addAtLeastOne);
      return;
    }
    for (final m in _items) {
      final variantId = int.tryParse(m.variantId.text.trim());
      final qty = int.tryParse(m.quantity.text.trim());
      final cost = double.tryParse(m.cost.text.trim());
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
      // Validate RFID count not exceeding quantity (optional warning)
      if (m.rfids.length > qty) {
        _showError(
          AppLocalizations.of(
            context,
          ).rfidExceedsQty(m.rfids.length.toString(), qty.toString()),
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
      final friendly = SqlErrorHelper.toArabicMessage(e);
      _showError(friendly);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
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
            AppLabeledField(
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
                            final selected = await Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (_) => const SupplierSearchPage(),
                              ),
                            );
                            if (selected != null) {
                              setState(() {
                                _supplierIdCtrl.text =
                                    (selected.id?.toString() ?? '');
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
                              }),
                      ),
                    ),
                ],
              ),
            ),
            // Reference field
            AppLabeledField(
              label: AppLocalizations.of(context).referenceOptional,
              controller: _referenceCtrl,
              trailing: const Icon(
                CupertinoIcons.tag,
                size: 16,
                color: CupertinoColors.inactiveGray,
              ),
            ),
            // Received date row
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
  double? baseCost; // original cost snapshot for quick reset
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
    final l = AppLocalizations.of(context);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(l.scanRfid),
      onPressed: () async {
        try {
          // Capture localization early to avoid context after awaits
          final settings = sl<SettingsRepository>();
          final enabled = await settings.get('rfid_enabled');
          if (!mounted) return; // ensure widget still in tree
          final enabledBool =
              enabled == '1' || (enabled?.toLowerCase() == 'true');
          if (!enabledBool) {
            if (!mounted) return;
            if (!context.mounted) return;
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
          // Use already captured localization
          if (!context.mounted) return;
          final seen = await showRfidScanDialog(context) ?? <String>[];
          if (!mounted || !context.mounted) return;
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
            if (!context.mounted) return;
            await showCupertinoDialog(
              context: context,
              builder: (dialogCtx) => CupertinoAlertDialog(
                title: Text(l.warning),
                content: Text(
                  l.addedIgnored(added.toString(), ignored.toString()),
                ),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: Text(l.ok),
                  ),
                ],
              ),
            );
          }
        } catch (e) {
          if (!mounted) return;
          if (!context.mounted) return;
          await showCupertinoDialog(
            context: context,
            builder: (dialogCtx) => CupertinoAlertDialog(
              title: Text(l.scanError),
              content: Text(e.toString()),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(l.ok),
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
    final loc = AppLocalizations.of(context);
    final selected = widget.model.selectedVariant;
    final variantLabel = selected == null
        ? loc.selectVariant
        : '${selected.sku ?? ''} — ${selected.size ?? ''} ${selected.color ?? ''}'
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
          const SizedBox(height: 6),
          // Quick actions: -10%, -5%, Reset, +5%, +10%, VAT 15%
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final entry in [
                {'label': '-10%', 'factor': 0.90},
                {'label': '-5%', 'factor': 0.95},
                {'label': 'إعادة', 'factor': null},
                {'label': '+5%', 'factor': 1.05},
                {'label': '+10%', 'factor': 1.10},
                {'label': 'VAT 15%', 'factor': 1.15},
              ])
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  onPressed: widget.canEdit
                      ? () {
                          final base =
                              widget.model.baseCost ??
                              double.tryParse(widget.model.cost.text.trim()) ??
                              0;
                          if (entry['factor'] == null) {
                            // Reset
                            widget.model.cost.text = base.toStringAsFixed(2);
                          } else {
                            final f = entry['factor'] as double;
                            final v = (base * f);
                            widget.model.cost.text = v.toStringAsFixed(2);
                          }
                          setState(() {
                            widget.model.baseCost =
                                base; // ensure baseline saved
                          });
                        }
                      : null,
                  child: Text(entry['label'] as String),
                ),
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
                onPressed: !widget.canEdit
                    ? null
                    : () async {
                        final epc = await showCupertinoDialog<String>(
                          context: context,
                          builder: (ctx) {
                            final ctrl = TextEditingController();
                            return CupertinoAlertDialog(
                              title: Text(
                                AppLocalizations.of(ctx).addRfidTitle,
                              ),
                              content: Column(
                                children: [
                                  const SizedBox(height: 8),
                                  CupertinoTextField(
                                    controller: ctrl,
                                    placeholder: AppLocalizations.of(
                                      ctx,
                                    ).epcPlaceholder,
                                    textDirection: TextDirection.ltr,
                                  ),
                                ],
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: Text(AppLocalizations.of(ctx).cancel),
                                ),
                                CupertinoDialogAction(
                                  isDefaultAction: true,
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(ctrl.text.trim()),
                                  child: Text(
                                    AppLocalizations.of(ctx).addAction,
                                  ),
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
                            if (!context.mounted) return;
                            await showCupertinoDialog(
                              context: context,
                              builder: (dialogCtx) => CupertinoAlertDialog(
                                title: Text(
                                  AppLocalizations.of(dialogCtx).warning,
                                ),
                                content: Text(
                                  AppLocalizations.of(
                                    dialogCtx,
                                  ).rfiCardsLimitReached,
                                ),
                                actions: [
                                  CupertinoDialogAction(
                                    isDefaultAction: true,
                                    onPressed: () =>
                                        Navigator.of(dialogCtx).pop(),
                                    child: Text(
                                      AppLocalizations.of(dialogCtx).ok,
                                    ),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }
                          if (!widget.model.rfids.contains(epc)) {
                            setState(() => widget.model.rfids.add(epc));
                          }
                        }
                      },
                child: Text(AppLocalizations.of(context).addRfidCard),
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
    final l = AppLocalizations.of(context);
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
          onPressed: widget.onStop,
          child: Text(l.stop),
        ),
      ],
    );
  }
}

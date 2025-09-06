import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clothes_pos/presentation/design/system/app_spacing.dart';
import 'package:clothes_pos/presentation/design/system/app_theme.dart';
import 'package:clothes_pos/presentation/design/system/app_colors.dart';
import 'package:clothes_pos/presentation/design/system/app_input_field.dart';
import 'numeric_keypad.dart';

PaymentPart? _focusedPart;

enum PaymentMethodKind { cash, card, mobile }

class PaymentPart {
  PaymentMethodKind method;
  double amount;
  PaymentPart({required this.method, this.amount = 0});
}

enum _PaymentStep { methods, summary }

class PaymentModal extends StatefulWidget {
  final double total;
  final void Function(double cash, double card, double mobile) onConfirm;
  const PaymentModal({super.key, required this.total, required this.onConfirm});

  static Future<void> open(
    BuildContext context, {
    required double total,
    required void Function(double cash, double card, double mobile) onConfirm,
  }) async {
    if (!context.mounted) return; // safety
    await showCupertinoDialog(
      context: context,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480, minWidth: 340),
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: PaymentModal(total: total, onConfirm: onConfirm),
          ),
        ),
      ),
    );
  }

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  final List<PaymentPart> _parts = [
    PaymentPart(method: PaymentMethodKind.cash),
  ];
  final Map<PaymentPart, TextEditingController> _controllers = {};
  _PaymentStep _step = _PaymentStep.methods;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controllers[_parts.first] = TextEditingController();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _sumFor(PaymentMethodKind k) => _parts
      .where((p) => p.method == k)
      .fold<double>(0, (s, p) => s + p.amount);
  double get _cash => _sumFor(PaymentMethodKind.cash);
  double get _card => _sumFor(PaymentMethodKind.card);
  double get _mobile => _sumFor(PaymentMethodKind.mobile);
  double get _paid => _cash + _card + _mobile;
  double get _remaining => (widget.total - _paid).clamp(0, widget.total);
  double get _change => _paid > widget.total ? _paid - widget.total : 0;
  bool get _canProceed =>
      _paid >= widget.total && _parts.every((p) => p.amount >= 0);

  void _recalc() {
    setState(() {
      for (final p in _parts) {
        final t = _controllers[p]?.text.trim() ?? '';
        p.amount = double.tryParse(t.replaceAll(',', '.')) ?? 0;
      }
    });
  }

  void _addPart() {
    setState(() {
      final nextMethod = PaymentMethodKind
          .values[(_parts.length) % PaymentMethodKind.values.length];
      final part = PaymentPart(method: nextMethod);
      _parts.add(part);
      _controllers[part] = TextEditingController();
    });
  }

  void _removePart(PaymentPart part) {
    if (_parts.length == 1) return; // keep at least one
    setState(() {
      _controllers.remove(part)?.dispose();
      _parts.remove(part);
    });
    _recalc();
  }

  void _applyQuick(double amount) {
    // Apply to first cash part (create if missing)
    final cashPart = _parts.firstWhere(
      (p) => p.method == PaymentMethodKind.cash,
      orElse: () {
        final np = PaymentPart(method: PaymentMethodKind.cash);
        _parts.insert(0, np);
        _controllers[np] = TextEditingController();
        return np;
      },
    );
    setState(() {
      final ctrl = _controllers[cashPart]!;
      ctrl.text = amount.toStringAsFixed(2);
      cashPart.amount = amount;
    });
    _recalc();
  }

  Future<void> _confirm() async {
    if (!_canProceed || _submitting) return;
    setState(() => _submitting = true);
    try {
      // Call onConfirm first, then close modal
      widget.onConfirm(_cash, _card, _mobile);
      // Add small delay to ensure callback completion
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget body;
    if (_step == _PaymentStep.methods) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              'الدفع',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final part in _parts) _paymentPartRow(part, c),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoButton(
                      onPressed: _addPart,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: const Icon(CupertinoIcons.add),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    for (final inc in [5, 10, 20, 50])
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        onPressed: () => _applyQuick(inc.toDouble()),
                        child: Text('+$inc'),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _indicatorRow('المتبقي', _remaining, c),
                _indicatorRow('الصرف', _change, c, isChange: true),
                const SizedBox(height: 12),
                NumericKeypad(
                  onKey: (val) {
                    if (_focusedPart != null) {
                      final ctrl = _controllers[_focusedPart]!;
                      ctrl.text += val;
                      _recalc();
                    }
                  },
                  onBackspace: () {
                    if (_focusedPart != null) {
                      final ctrl = _controllers[_focusedPart]!;
                      if (ctrl.text.isNotEmpty) {
                        ctrl.text = ctrl.text.substring(
                          0,
                          ctrl.text.length - 1,
                        );
                        _recalc();
                      }
                    }
                  },
                  onClear: () {
                    if (_focusedPart != null) {
                      final ctrl = _controllers[_focusedPart]!;
                      ctrl.clear();
                      _recalc();
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: CupertinoButton.filled(
              onPressed: _canProceed
                  ? () => setState(() => _step = _PaymentStep.summary)
                  : null,
              child: const Text('التالي'),
            ),
          ),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              'مراجعة الدفعات',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final p in _parts) _summaryRow(p, c),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  color: c.border.withValues(alpha: 0.4),
                ),
                _indicatorRow('الإجمالي المدفوع', _paid, c),
                _indicatorRow('المتبقي', _remaining, c),
                if (_change > 0)
                  _indicatorRow('الصرف', _change, c, isChange: true),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _step = _PaymentStep.methods),
                    child: const Text('رجوع'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CupertinoButton.filled(
                    onPressed: _canProceed && !_submitting ? _confirm : null,
                    child: _submitting
                        ? const CupertinoActivityIndicator()
                        : const Text('تأكيد'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CupertinoButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('خروج'),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Stack(
        children: [
          body,
          Positioned(
            top: 0,
            right: 0,
            child: CupertinoButton(
              padding: const EdgeInsets.all(0),
              minimumSize: const Size(32, 32),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              child: const Icon(
                CupertinoIcons.xmark_circle,
                size: 28,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _indicatorRow(
    String label,
    double value,
    SemanticColorRoles c, {
    bool isChange = false,
  }) {
    final color = value == 0 ? c.success : (isChange ? c.accent : c.warning);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _paymentPartRow(PaymentPart part, SemanticColorRoles c) {
    final ctrl = _controllers[part] ??= TextEditingController();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: CupertinoSegmentedControl<PaymentMethodKind>(
              groupValue: part.method,
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: const {
                PaymentMethodKind.cash: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('نقد'),
                ),
                PaymentMethodKind.card: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('بطاقة'),
                ),
                PaymentMethodKind.mobile: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('هاتف'),
                ),
              },
              onValueChanged: (v) => setState(() => part.method = v),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            flex: 3,
            child: Focus(
              onFocusChange: (hasFocus) {
                if (hasFocus) {
                  setState(() {
                    _focusedPart = part;
                  });
                }
              },
              child: AppInputField(
                controller: ctrl,
                label: 'المبلغ',
                placeholder: '0.00',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                onChanged: (_) => _recalc(),
                error: part.amount < 0 ? 'قيمة غير صالحة' : null,
              ),
            ),
          ),
          const SizedBox(width: 4),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            onPressed: _parts.length == 1 ? null : () => _removePart(part),
            child: Icon(
              CupertinoIcons.minus_circle,
              color: _parts.length == 1 ? c.textSecondary : c.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(PaymentPart part, SemanticColorRoles c) {
    String name;
    switch (part.method) {
      case PaymentMethodKind.cash:
        name = 'نقد';
        break;
      case PaymentMethodKind.card:
        name = 'بطاقة';
        break;
      case PaymentMethodKind.mobile:
        name = 'هاتف';
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            part.amount.toStringAsFixed(2),
            style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

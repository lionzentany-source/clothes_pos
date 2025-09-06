// Clean re-write of StoreInfoScreen after corruption cleanup (removed duplicated localization blocks).
import 'dart:convert';
import 'package:clothes_pos/data/repositories/settings_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:file_selector/file_selector.dart';
import 'package:clothes_pos/core/printing/receipt_pdf_service.dart';
import 'package:printing/printing.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';
import 'package:clothes_pos/presentation/design/system/app_typography.dart';

class StoreInfoScreen extends StatefulWidget {
  const StoreInfoScreen({super.key});
  @override
  State<StoreInfoScreen> createState() => _StoreInfoScreenState();
}

class _StoreInfoScreenState extends State<StoreInfoScreen> {
  final _nameCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController(text: 'LYD');
  final _sloganCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  final _thanksCtrl = TextEditingController();
  bool _loading = true;
  bool _showPreview = false;
  String? _logoBase64;
  bool _showLogo = true;
  bool _showSlogan = true;
  bool _showTaxId = true;
  bool _showAddress = true;
  bool _showPhone = true;

  SettingsRepository get _settings => sl<SettingsRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _nameCtrl.text = await _settings.get('store_name') ?? '';
      _addrCtrl.text = await _settings.get('store_address') ?? '';
      _phoneCtrl.text = await _settings.get('store_phone') ?? '';
      _currencyCtrl.text = await _settings.get('currency') ?? 'LYD';
      _sloganCtrl.text = await _settings.get('store_slogan') ?? '';
      _taxIdCtrl.text = await _settings.get('tax_id') ?? '';
      _thanksCtrl.text = await _settings.get('receipt_thanks') ?? '';
      _logoBase64 = await _settings.get('store_logo_base64');
      Future<bool> parseBool(String key, bool def) async {
        final v = await _settings.get(key);
        if (v == null) return def;
        final low = v.toLowerCase();
        return !(low == 'false' || low == '0');
      }

      _showLogo = await parseBool('show_logo', true);
      _showSlogan = await parseBool('show_slogan', true);
      _showTaxId = await parseBool('show_tax_id', true);
      _showAddress = await parseBool('show_address', true);
      _showPhone = await parseBool('show_phone', true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await _settings.set('store_name', _nameCtrl.text.trim());
      await _settings.set('store_address', _addrCtrl.text.trim());
      await _settings.set('store_phone', _phoneCtrl.text.trim());
      await _settings.set(
        'currency',
        _currencyCtrl.text.trim().isEmpty ? 'LYD' : _currencyCtrl.text.trim(),
      );
      await _settings.set('store_slogan', _sloganCtrl.text.trim());
      await _settings.set('tax_id', _taxIdCtrl.text.trim());
      await _settings.set('receipt_thanks', _thanksCtrl.text.trim());
      await _settings.set('store_logo_base64', _logoBase64);
      await _settings.set('show_logo', _showLogo.toString());
      await _settings.set('show_slogan', _showSlogan.toString());
      await _settings.set('show_tax_id', _showTaxId.toString());
      await _settings.set('show_address', _showAddress.toString());
      await _settings.set('show_phone', _showPhone.toString());
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      await showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(l.done),
          content: Text(l.infoSaved),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.ok),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l.storeInfo),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading) const CupertinoActivityIndicator(),
            if (!_loading)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _showPreview = !_showPreview),
                child: Icon(
                  _showPreview ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CupertinoTextField(
              controller: _nameCtrl,
              placeholder: l.storeNamePlaceholder,
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _addrCtrl,
              placeholder: l.addressPlaceholder,
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _phoneCtrl,
              placeholder: l.phoneLabel,
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _currencyCtrl,
              placeholder: l.currencyPlaceholderLyd,
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _sloganCtrl,
              placeholder: 'شعار مختصر',
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _taxIdCtrl,
              placeholder: 'الرقم الضريبي (اختياري)',
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _thanksCtrl,
              placeholder: 'رسالة الشكر في أسفل الفاتورة',
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    onPressed: _loading
                        ? null
                        : () async {
                            final typeGroup = XTypeGroup(
                              label: 'images',
                              extensions: ['png', 'jpg', 'jpeg'],
                            );
                            final file = await openFile(
                              acceptedTypeGroups: [typeGroup],
                            );
                            if (file == null) return;
                            final bytes = await file.readAsBytes();
                            if (bytes.lengthInBytes > 150 * 1024) {
                              if (!mounted || !context.mounted) return;
                              await showCupertinoDialog(
                                context: context,
                                builder: (ctx) => const CupertinoAlertDialog(
                                  title: Text('حجم كبير'),
                                  content: Text(
                                    'يرجى اختيار صورة أقل من 150KB للحصول على طباعة أسرع.',
                                  ),
                                ),
                              );
                              // Ensure the user can dismiss (older dialog had no actions)
                              if (context.mounted) {
                                Navigator.of(context).maybePop();
                              }
                              return;
                            }
                            setState(() => _logoBase64 = base64Encode(bytes));
                          },
                    child: Text(
                      _logoBase64 == null ? 'اختيار شعار' : 'تغيير الشعار',
                    ),
                  ),
                ),
                if (_logoBase64 != null)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onPressed: () => setState(() => _logoBase64 = null),
                    child: const Icon(CupertinoIcons.delete),
                  ),
              ],
            ),
            if (_logoBase64 != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Image.memory(
                  base64Decode(_logoBase64!),
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 12),
            const Text('عناصر تظهر في رأس الفاتورة:'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _toggleChip(
                  'الشعار',
                  _showLogo,
                  (v) => setState(() => _showLogo = v),
                ),
                _toggleChip(
                  'الشعار المختصر',
                  _showSlogan,
                  (v) => setState(() => _showSlogan = v),
                ),
                _toggleChip(
                  'الرقم الضريبي',
                  _showTaxId,
                  (v) => setState(() => _showTaxId = v),
                ),
                _toggleChip(
                  'العنوان',
                  _showAddress,
                  (v) => setState(() => _showAddress = v),
                ),
                _toggleChip(
                  'الهاتف',
                  _showPhone,
                  (v) => setState(() => _showPhone = v),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              onPressed: _loading ? null : _save,
              child: Text(l.save),
            ),
            if (_showPreview) ...[
              const SizedBox(height: 24),
              Container(height: 1, color: CupertinoColors.separator),
              const SizedBox(height: 12),
              const Text(
                'معاينة الفاتورة (تجريبية)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_nameCtrl.text, style: const TextStyle(fontSize: 16)),
                    if (_sloganCtrl.text.trim().isNotEmpty)
                      Text(
                        _sloganCtrl.text.trim(),
                        style: AppTypography.small.copyWith(
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    if (_addrCtrl.text.trim().isNotEmpty)
                      Text(
                        _addrCtrl.text.trim(),
                        style: AppTypography.small.copyWith(
                          color: CupertinoColors.label,
                        ),
                      ),
                    if (_phoneCtrl.text.trim().isNotEmpty)
                      Text(
                        'هاتف: ${_phoneCtrl.text.trim()}',
                        style: AppTypography.small.copyWith(
                          color: CupertinoColors.label,
                        ),
                      ),
                    if (_taxIdCtrl.text.trim().isNotEmpty)
                      Text(
                        'الرقم الضريبي: ${_taxIdCtrl.text.trim()}',
                        style: AppTypography.small.copyWith(
                          color: CupertinoColors.label,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(height: 1, color: CupertinoColors.separator),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'إجمالي تجريبي',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('123.45'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_thanksCtrl.text.trim().isNotEmpty)
                      Center(
                        child: Text(
                          _thanksCtrl.text.trim(),
                          style: AppTypography.small,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      onPressed: _loading
                          ? null
                          : () async {
                              await _save();
                              final pdf = await ReceiptPdfService()
                                  .generateTest(locale: l.localeName);
                              await Printing.sharePdf(
                                bytes: await pdf.readAsBytes(),
                                filename: 'receipt_test.pdf',
                              );
                            },
                      child: const Text('حفظ + معاينة PDF'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _toggleChip(String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: value
              ? CupertinoColors.activeBlue
              : CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              size: 16,
              color: value ? CupertinoColors.white : CupertinoColors.systemGrey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: value ? CupertinoColors.white : CupertinoColors.label,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

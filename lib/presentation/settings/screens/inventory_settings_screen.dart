import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';

class InventorySettingsScreen extends StatefulWidget {
  const InventorySettingsScreen({super.key});
  @override
  State<InventorySettingsScreen> createState() =>
      _InventorySettingsScreenState();
}

class _InventorySettingsScreenState extends State<InventorySettingsScreen> {
  final _thresholdCtrl = TextEditingController();
  bool _loading = true;
  SettingsRepository get _settings => sl<SettingsRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _thresholdCtrl.text = await _settings.get('stock_low_threshold') ?? '0';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final t = _thresholdCtrl.text.trim();
      await _settings.set('stock_low_threshold', t.isEmpty ? '0' : t);
      if (!mounted) return;
      await showCupertinoDialog(
        context: context,
        builder: (_) {
          final l = AppLocalizations.of(context);
          return CupertinoAlertDialog(
            title: Text(l.done),
            content: Text(l.settingsSaved),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.ok),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(l.inventorySettings)),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(l.lowStockWarningThreshold),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _thresholdCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: false,
                      decimal: false,
                    ),
                    placeholder: l.example5Placeholder,
                  ),
                  const SizedBox(height: 20),
                  CupertinoButton.filled(
                    onPressed: _loading ? null : _save,
                    child: Text(l.save),
                  ),
                ],
              ),
      ),
    );
  }
}

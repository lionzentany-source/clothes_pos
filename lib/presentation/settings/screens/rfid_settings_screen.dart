import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';

class RfidSettingsScreen extends StatefulWidget {
  const RfidSettingsScreen({super.key});

  @override
  State<RfidSettingsScreen> createState() => _RfidSettingsScreenState();
}

class _RfidSettingsScreenState extends State<RfidSettingsScreen> {
  final _repo = sl<SettingsRepository>();
  bool _enabled = false;
  final _debounceCtrl = TextEditingController(text: '800');
  final _powerCtrl = TextEditingController(text: '20');
  final _regionCtrl = TextEditingController(text: '0');
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final en = await _repo.get('rfid_enabled');
      final db = await _repo.get('rfid_debounce_ms');
      final pw = await _repo.get('rfid_rf_power');
      final rg = await _repo.get('rfid_region');
      if (!mounted) return;
      setState(() {
        _enabled = (en == '1' || en == 'true');
        if (db != null && db.isNotEmpty) _debounceCtrl.text = db;
        if (pw != null && pw.isNotEmpty) _powerCtrl.text = pw;
        if (rg != null && rg.isNotEmpty) _regionCtrl.text = rg;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    final debounce = int.tryParse(_debounceCtrl.text.trim()) ?? 800;
    final power = int.tryParse(_powerCtrl.text.trim()) ?? 20;
    final region = int.tryParse(_regionCtrl.text.trim()) ?? 0;
    await _repo.set('rfid_enabled', _enabled ? '1' : '0');
    await _repo.set('rfid_debounce_ms', debounce.toString());
    await _repo.set('rfid_rf_power', power.toString());
    await _repo.set('rfid_region', region.toString());
    if (!mounted) return;
    await showCupertinoDialog(
      context: context,
      builder: (dialogCtx) {
        final l = AppLocalizations.of(dialogCtx);
        return CupertinoAlertDialog(
          title: Text(l.done),
          content: Text(l.rfidSettingsSaved),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(l.ok),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _debounceCtrl.dispose();
    _powerCtrl.dispose();
    _regionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(l.rfidSettings)),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                children: [
                  _SectionTitle(l.generalSection),
                  CupertinoListTile(
                    title: Text(l.enableRfidReader),
                    trailing: CupertinoSwitch(
                      value: _enabled,
                      onChanged: (v) => setState(() => _enabled = v),
                    ),
                  ),
                  CupertinoListTile(
                    title: Text(l.debounceWindowMs),
                    subtitle: Text(l.ignoreSameTagWithinDuration),
                    trailing: SizedBox(
                      width: 100,
                      child: CupertinoTextField(
                        controller: _debounceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ),
                  _SectionTitle(l.rfParamsMayRequireRestart),
                  CupertinoListTile(
                    title: Text(l.transmitPower),
                    subtitle: Text(l.numericValuePerReader),
                    trailing: SizedBox(
                      width: 100,
                      child: CupertinoTextField(
                        controller: _powerCtrl,
                        keyboardType: const TextInputType.numberWithOptions(),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ),
                  CupertinoListTile(
                    title: Text(l.regionLabel),
                    subtitle: Text(l.numericValuePerReader),
                    trailing: SizedBox(
                      width: 100,
                      child: CupertinoTextField(
                        controller: _regionCtrl,
                        keyboardType: const TextInputType.numberWithOptions(),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CupertinoButton.filled(
                      onPressed: _save,
                      child: Text(l.save),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

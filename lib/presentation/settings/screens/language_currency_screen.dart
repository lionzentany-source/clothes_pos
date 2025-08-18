import 'package:clothes_pos/presentation/settings/bloc/settings_cubit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clothes_pos/l10n/app_localizations.dart';

class LanguageCurrencyScreen extends StatefulWidget {
  const LanguageCurrencyScreen({super.key});
  @override
  State<LanguageCurrencyScreen> createState() => _LanguageCurrencyScreenState();
}

class _LanguageCurrencyScreenState extends State<LanguageCurrencyScreen> {
  late String _locale;
  late String _currency;
  final _currencyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsCubit>().state;
    _locale = s.localeCode;
    _currency = s.currency;
    _currencyCtrl.text = _currency;
  }

  void _save() {
    context.read<SettingsCubit>().setLocale(_locale);
    context.read<SettingsCubit>().setCurrency(
      _currencyCtrl.text.trim().isEmpty ? 'LYD' : _currencyCtrl.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l.languageCurrency),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _save,
          child: Text(l.save),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l.languageCurrency,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CupertinoListTile(
              title: const Text('English'),
              trailing: _locale == 'en'
                  ? const Icon(CupertinoIcons.check_mark)
                  : null,
              onTap: () => setState(() => _locale = 'en'),
            ),
            CupertinoListTile(
              title: const Text('العربية'),
              trailing: _locale == 'ar'
                  ? const Icon(CupertinoIcons.check_mark)
                  : null,
              onTap: () => setState(() => _locale = 'ar'),
            ),
            const SizedBox(height: 24),
            Text(
              l.languageCurrency.split('&').last.trim(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(controller: _currencyCtrl, placeholder: 'LYD'),
          ],
        ),
      ),
    );
  }
}

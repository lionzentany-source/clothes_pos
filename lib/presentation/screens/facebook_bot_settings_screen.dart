import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FacebookBotSettingsScreen extends StatefulWidget {
  const FacebookBotSettingsScreen({super.key});

  @override
  State<FacebookBotSettingsScreen> createState() =>
      _FacebookBotSettingsScreenState();
}

class _FacebookBotSettingsScreenState extends State<FacebookBotSettingsScreen> {
  final _tokenController = TextEditingController();
  final _pageIdController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    _tokenController.text = prefs.getString('fb_page_token') ?? '';
    _pageIdController.text = prefs.getString('fb_page_id') ?? '';
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveSettings() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fb_page_token', _tokenController.text.trim());
    await prefs.setString('fb_page_id', _pageIdController.text.trim());
    if (mounted) setState(() => _loading = false);
    final c = context;
    if (!c.mounted) return;
    showCupertinoDialog(
      context: c,
      builder: (_) => CupertinoAlertDialog(
        content: const Text('تم حفظ إعدادات البوت بنجاح'),
        actions: [
          CupertinoDialogAction(
            child: const Text('موافق'),
            onPressed: () {
              if (!c.mounted) return;
              Navigator.of(c).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('إعدادات بوت فيسبوك'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Page Access Token',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              CupertinoTextField(
                controller: _tokenController,
                placeholder: 'أدخل توكن الصفحة',
                enabled: !_loading,
              ),
              const SizedBox(height: 16),
              const Text(
                'Page ID',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              CupertinoTextField(
                controller: _pageIdController,
                placeholder: 'أدخل معرف الصفحة',
                enabled: !_loading,
              ),
              const SizedBox(height: 32),
              CupertinoButton.filled(
                onPressed: _loading ? null : _saveSettings,
                child: _loading
                    ? const CupertinoActivityIndicator()
                    : const Text('حفظ الإعدادات'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

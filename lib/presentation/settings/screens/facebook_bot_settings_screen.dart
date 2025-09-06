import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings_cubit.dart';

class FacebookBotSettingsScreen extends StatefulWidget {
  const FacebookBotSettingsScreen({super.key});

  @override
  State<FacebookBotSettingsScreen> createState() =>
      _FacebookBotSettingsScreenState();
}

class _FacebookBotSettingsScreenState extends State<FacebookBotSettingsScreen> {
  late final TextEditingController _accessTokenController;
  late final TextEditingController _verifyTokenController;
  late final TextEditingController _pageIdController;

  @override
  void initState() {
    super.initState();
    final settingsState = context.read<SettingsCubit>().state;
    _accessTokenController = TextEditingController(
      text: settingsState.facebookPageAccessToken,
    );
    _verifyTokenController = TextEditingController(
      text: settingsState.facebookVerifyToken,
    );
    _pageIdController = TextEditingController(
      text: settingsState.facebookPageId,
    );
  }

  @override
  void dispose() {
    _accessTokenController.dispose();
    _verifyTokenController.dispose();
    _pageIdController.dispose();
    super.dispose();
  }

  void _save() {
    final cubit = context.read<SettingsCubit>();
    cubit.setFacebookPageAccessToken(_accessTokenController.text.trim());
    cubit.setFacebookVerifyToken(_verifyTokenController.text.trim());
    cubit.setFacebookPageId(_pageIdController.text.trim());

    // Show a confirmation dialog
    if (!context.mounted) return; // safety
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('تم الحفظ'),
        content: const Text('تم حفظ إعدادات بوت فيسبوك بنجاح.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('موافق'),
            onPressed: () => Navigator.of(ctx).pop(),
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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            CupertinoTextField(
              controller: _accessTokenController,
              placeholder: 'Page Access Token',
              clearButtonMode: OverlayVisibilityMode.editing,
              textAlign: TextAlign.left,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: _verifyTokenController,
              placeholder: 'Verify Token',
              clearButtonMode: OverlayVisibilityMode.editing,
              textAlign: TextAlign.left,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: _pageIdController,
              placeholder: 'Page ID',
              clearButtonMode: OverlayVisibilityMode.editing,
              textAlign: TextAlign.left,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 32),
            CupertinoButton.filled(
              onPressed: _save,
              child: const Text('حفظ الإعدادات'),
            ),
          ],
        ),
      ),
    );
  }
}

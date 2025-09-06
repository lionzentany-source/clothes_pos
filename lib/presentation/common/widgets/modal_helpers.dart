import 'package:flutter/cupertino.dart';
import 'package:clothes_pos/presentation/common/widgets/floating_modal.dart';
import 'package:clothes_pos/l10n_clean/app_localizations.dart';

/// Helper methods للنوافذ الشائعة
class ModalHelpers {
  /// عرض نافذة تأكيد بسيطة
  static Future<bool> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
  }) async {
    final l = AppLocalizations.of(context);
    
    return await FloatingModal.showWithSize<bool>(
      context: context,
      title: title,
      size: ModalSize.small,
      showCloseButton: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  child: Text(cancelText ?? l.cancel),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton.filled(
                  child: Text(confirmText ?? l.ok),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    ) ?? false;
  }

  /// عرض نافذة إدخال نص
  static Future<String?> showTextInput({
    required BuildContext context,
    required String title,
    String? placeholder,
    String? initialValue,
    String? confirmText,
    String? cancelText,
    bool isRequired = false,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');
    final l = AppLocalizations.of(context);
    
    return await FloatingModal.showWithSize<String?>(
      context: context,
      title: title,
      size: ModalSize.small,
      showCloseButton: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            autofocus: true,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  child: Text(cancelText ?? l.cancel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton.filled(
                  child: Text(confirmText ?? l.ok),
                  onPressed: () {
                    final value = controller.text.trim();
                    if (isRequired && value.isEmpty) {
                      // يمكن إضافة تنبيه هنا
                      return;
                    }
                    Navigator.of(context).pop(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// عرض نافذة معلومات بسيطة
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
  }) async {
    final l = AppLocalizations.of(context);
    
    await FloatingModal.showWithSize<void>(
      context: context,
      title: title,
      size: ModalSize.small,
      showCloseButton: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            child: Text(buttonText ?? l.ok),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// عرض نافذة خطأ
  static Future<void> showError({
    required BuildContext context,
    required String message,
    String? title,
  }) async {
    final l = AppLocalizations.of(context);
    
    await showInfo(
      context: context,
      title: title ?? l.error,
      message: message,
    );
  }

  /// عرض نافذة نجاح
  static Future<void> showSuccess({
    required BuildContext context,
    required String message,
    String? title,
  }) async {
    await showInfo(
      context: context,
      title: title ?? 'تم بنجاح',
      message: message,
    );
  }
}

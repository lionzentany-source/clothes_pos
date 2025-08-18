import 'ai_models.dart';
import 'ai_client.dart';

class AiService {
  final IAiClient client;
  final Future<AiSettings> Function() loadSettings;
  AiService({required this.client, required this.loadSettings});

  // System prompt (Arabic) constraining the model strictly to our domain
  static const String _systemPrompt =
      'أنت مساعد لنظام نقاط بيع الملابس. يُمنع تماماً الخروج عن نطاق المنظومة.'
      ' يجب أن يكون الرد حصراً JSON صالح وبدون أي نص آخر. المخطط المسموح:\n'
      '{"action": "open_screen", "tab": "pos|inventory|reports|settings", "screen": "اختياري"}\n'
      '{"action": "answer_faq", "text": "رد موجز داخل نطاق المنظومة"}\n'
      '{"action": "query_metric", "metric": "sales|returns|expenses|profit", "range": "today|yesterday|week|month"}\n'
      '{"action":"unknown"} في حال كان الطلب خارج النطاق.'
      ' إن لم يحدد المستخدم المدة الزمنية فاعتبرها today. لا تُرجِع أي شرح أو نص خارج JSON إطلاقاً.';

  Future<AiResult> ask(String userText) async {
    final settings = await loadSettings();
    if (!settings.enabled) {
      return const AiResult(
        action: UnknownAction(),
        rawModelText: 'AI disabled',
      );
    }
    final msgs = [
      {'role': 'system', 'content': _systemPrompt},
      {'role': 'user', 'content': userText},
    ];
    final content = await client.chat(
      settings: settings,
      messages: msgs,
      stream: false,
    );
    final action = parseConstrainedAction(content);
    return AiResult(action: action, rawModelText: content);
  }
}

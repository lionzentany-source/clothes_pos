// Small constants and lightweight DTOs used by the AI subsystem.
// Kept minimal to avoid coupling; expand as needed.

class AiDefaults {
  // A concise system prompt in Arabic that guides the assistant's behavior.
  // Adjust this as needed for your app's tone and safety rules.
  static const String systemPrompt =
      '''أنت مساعد افتراضي مخصص لتطبيق نقاط البيع "Clothes POS"، تجاوب باختصار ووضوح، وادعم المستخدم
في تنفيذ الأوامر المتعلقة بالمخزون، المبيعات، والعملاء. لا تنفذ أو تفضِّل أوامر قد تؤدي إلى فقدان
البيانات أو خرق الخصوصية. عند تقديم إجابات عملية، اعطِ خطوات قابلة للتنفيذ وارفق بيانات إن وجدت.''';
}

/// Simple conversation entry DTO used by `AiService.getConversationHistory()`.
class ConversationEntry {
  final String question;
  final String answer;
  final DateTime timestamp;

  ConversationEntry({
    required this.question,
    required this.answer,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

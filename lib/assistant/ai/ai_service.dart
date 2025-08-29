import 'dart:async';
import 'package:flutter/foundation.dart';

import 'ai_client.dart';
import 'ai_models.dart';
import 'constants.dart';

/// This class is the main entry point for AI functionality in the app.
/// It orchestrates the client, settings, and conversation history.
class AiService {
  final IAiClient _client;
  final Future<AiSettings> Function() _loadSettings;
  final List<Map<String, String>> _history = [];

  AiService({
    required IAiClient client,
    required Future<AiSettings> Function() loadSettings,
  }) : _client = client,
       _loadSettings = loadSettings;

  /// Backwards-compatibility helper for legacy call sites that have concrete settings.
  /// New code should prefer the named-parameter constructor.
  static AiService fromSettings(IAiClient client, AiSettings settings) {
    return AiService(client: client, loadSettings: () async => settings);
  }

  /// Returns conversation history as a list of ConversationEntry for UI use.
  List<ConversationEntry> getConversationHistory() {
    final entries = <ConversationEntry>[];
    for (int i = 0; i < _history.length; i += 2) {
      final user = _history[i]['content'] ?? '';
      final assistant = (i + 1 < _history.length)
          ? _history[i + 1]['content'] ?? ''
          : '';
      entries.add(
        ConversationEntry(
          question: user,
          answer: assistant,
          timestamp: DateTime.now(),
        ),
      );
    }
    return entries;
  }

  /// Returns simple smart suggestions; can be enhanced later.
  List<String> getSmartSuggestions({String? context}) {
    // Basic suggestions; a real implementation would use context and AI suggestions.
    return [
      'كيف أزيد المبيعات هذا الأسبوع؟',
      'ماهي المنتجات الراكدة؟',
      'اعطني تقرير سريع عن الأرباح',
    ];
  }

  Future<void> clearConversationHistory() async => clearHistory();

  Future<String?> exportConversationHistory() async {
    // Placeholder: implement file export if needed.
    return null;
  }

  Map<String, dynamic> getUsageStatistics() {
    return {
      'total_requests': _history.length ~/ 2,
      'successful_requests': _history.length ~/ 2,
      'success_rate': 100,
      'average_response_time_ms': 0,
      'conversation_entries': _history.length ~/ 2,
    };
  }

  /// The primary method to ask the AI a question.
  Future<AiResult> ask(String question) async {
    final settings = await _loadSettings();
    if (!settings.isValid) {
      debugPrint('AI settings are not valid. Cannot process request.');
      return AiResult(
        action: const AnswerFaqAction(
          'إعدادات الذكاء الاصطناعي غير مكتملة. يرجى مراجعة شاشة الإعدادات.',
        ),
      );
    }

    // Construct the message list including the system prompt and conversation history.
    final messages = [
      {'role': 'system', 'content': AiDefaults.systemPrompt},
      ..._history,
      {'role': 'user', 'content': question},
    ];

    try {
      final responseText = await _client.chat(
        settings: settings,
        messages: messages,
      );

      // Add both question and AI's raw response to history for context.
      _updateHistory(question, responseText);

      // Parse the model's response to determine the executable action.
      final action = ActionParser.parseConstrainedAction(responseText);

      // If the action is a simple answer, use its text. Otherwise, keep the raw text for logging.
      final displayText = (action is AnswerFaqAction) ? action.text : null;

      return AiResult(
        action: action,
        rawModelText: displayText ?? responseText,
      );
    } on AiConnectionException catch (e) {
      debugPrint('AI Connection Exception: ${e.message}');
      return AiResult(
        action: AnswerFaqAction('حدث خطأ في الاتصال: ${e.message}'),
      );
    } on AiRateLimitException catch (e) {
      debugPrint('AI Rate Limit Exception: ${e.message}');
      return AiResult(
        action: const AnswerFaqAction(
          'تم تجاوز حد الطلبات. يرجى المحاولة لاحقاً.',
        ),
      );
    } catch (e) {
      debugPrint('An unexpected AI error occurred: $e');
      return AiResult(action: const AnswerFaqAction('حدث خطأ غير متوقع.'));
    }
  }

  /// Manages the conversation history to provide context to the AI.
  void _updateHistory(String question, String answer) {
    _history.add({'role': 'user', 'content': question});
    _history.add({'role': 'assistant', 'content': answer});

    // To prevent the context from growing indefinitely, we keep the last 10 exchanges (20 messages).
    if (_history.length > 20) {
      _history.removeRange(0, _history.length - 20);
    }
  }

  void clearHistory() {
    _history.clear();
  }
}

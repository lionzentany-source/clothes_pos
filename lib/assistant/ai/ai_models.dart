import 'dart:convert';

// Settings for AI provider (OpenAI-compatible)
class AiSettings {
  final bool enabled;
  final Uri? baseUrl; // e.g., https://api.openai.com
  final String model;
  final String? apiKey;
  final double temperature;
  const AiSettings({
    required this.enabled,
    required this.baseUrl,
    required this.model,
    required this.apiKey,
    required this.temperature,
  });
}

// App-level action schema the model must return
abstract class AiAction {
  const AiAction();
}

class OpenScreenAction extends AiAction {
  final String tab; // pos | inventory | reports | settings
  final String? screen; // optional settings sub-screen id
  const OpenScreenAction({required this.tab, this.screen});
}

class AnswerFaqAction extends AiAction {
  final String text;
  const AnswerFaqAction(this.text);
}

class UnknownAction extends AiAction {
  const UnknownAction();
}

class QueryMetricAction extends AiAction {
  final String metric; // sales | returns | expenses | profit
  final String range; // today | yesterday | week | month
  const QueryMetricAction({required this.metric, required this.range});
}

class AiResult {
  final AiAction action;
  final String? rawModelText; // for debugging/UX if needed
  const AiResult({required this.action, this.rawModelText});
}

// Helper to parse the constrained JSON the model returns
AiAction parseConstrainedAction(String text) {
  try {
    final m = jsonDecode(text);
    if (m is Map<String, dynamic>) {
      final action = (m['action'] ?? '').toString();
      if (action == 'open_screen') {
        final tab = (m['tab'] ?? '').toString();
        final screen = m['screen']?.toString();
        if (tab.isNotEmpty) {
          return OpenScreenAction(tab: tab, screen: screen);
        }
      } else if (action == 'answer_faq') {
        final t = (m['text'] ?? '').toString();
        if (t.isNotEmpty) return AnswerFaqAction(t);
      } else if (action == 'query_metric') {
        final metric = (m['metric'] ?? '').toString();
        final range = (m['range'] ?? '').toString();
        if (metric.isNotEmpty && range.isNotEmpty) {
          return QueryMetricAction(metric: metric, range: range);
        }
      }
    }
    return const UnknownAction();
  } catch (_) {
    return const UnknownAction();
  }
}

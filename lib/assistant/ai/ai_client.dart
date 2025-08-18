import 'dart:convert';
import 'dart:io';
import 'ai_models.dart';

abstract class IAiClient {
  Future<String> chat({
    required AiSettings settings,
    required List<Map<String, String>> messages,
    bool stream = false,
  });
}

class OpenAiCompatibleClient implements IAiClient {
  final HttpClient _http = HttpClient();

  Uri _buildChatUrl(Uri base) {
    // DeepSeek recommends base https://api.deepseek.com and endpoint /chat/completions.
    // If a user provides base ending with /v1 (OpenAI-compatible), we still append /chat/completions to that base.
    final basePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    final path = '$basePath/chat/completions';
    return base.replace(path: path.isEmpty ? '/chat/completions' : path);
  }

  @override
  Future<String> chat({
    required AiSettings settings,
    required List<Map<String, String>> messages,
    bool stream = false,
  }) async {
    if (settings.baseUrl == null) {
      throw StateError('AI base URL is not set');
    }
    final url = _buildChatUrl(settings.baseUrl!);
    final req = await _http.postUrl(url);
    if (settings.apiKey != null && settings.apiKey!.isNotEmpty) {
      req.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${settings.apiKey}',
      );
    }
    req.headers.contentType = ContentType.json;

    final body = {
      'model': settings.model,
      'messages': messages,
      'temperature': settings.temperature,
      'stream': false, // non-stream MVP
    };
    req.add(utf8.encode(jsonEncode(body)));

    final resp = await req.close();
    final text = await utf8.decodeStream(resp);
    if (resp.statusCode >= 400) {
      throw HttpException('AI error ${resp.statusCode}: $text');
    }
    final json = jsonDecode(text) as Map<String, dynamic>;
    // Try OpenAI format
    final choices = json['choices'] as List<dynamic>?;
    if (choices != null && choices.isNotEmpty) {
      final msg = choices.first['message'] as Map<String, dynamic>;
      final content = (msg['content'] ?? '').toString();
      return content;
    }
    // Fallback to generic
    return (json['content'] ?? text).toString();
  }
}

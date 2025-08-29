import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'ai_models.dart';

// تحسين: واجهة عميل الذكاء الاصطناعي مع دعم أفضل
abstract class IAiClient {
  Future<String> chat({
    required AiSettings settings,
    required List<Map<String, String>> messages,
    bool stream = false,
    String? requestId,
  });

  Future<bool> testConnection(AiSettings settings);

  // جديد: دعم streaming
  Stream<String> chatStream({
    required AiSettings settings,
    required List<Map<String, String>> messages,
    String? requestId,
  });

  // جديد: إحصائيات الاستخدام
  Future<Map<String, dynamic>> getUsageStats(AiSettings settings);

  // جديد: قائمة النماذج المتاحة
  Future<List<String>> getAvailableModels(AiSettings settings);
}

// تحسين: عميل متوافق مع OpenAI مع ميزات متقدمة
class OpenAiCompatibleClient implements IAiClient {
  final HttpClient _httpClient;
  final Map<String, Timer> _rateLimitTimers = {};
  final Map<String, int> _requestCounts = {};
  final Duration _rateLimitWindow = const Duration(minutes: 1);

  // إعدادات cache للطلبات المتكررة
  final Map<String, _CachedResponse> _responseCache = {};
  final int _maxCacheSize = 100;

  OpenAiCompatibleClient({HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient() {
    // إعداد timeout افتراضي
    _httpClient.connectionTimeout = const Duration(seconds: 10);
    _httpClient.idleTimeout = const Duration(seconds: 30);
  }

  @override
  Future<bool> testConnection(AiSettings settings) async {
    try {
      if (!settings.isValid) {
        debugPrint('إعدادات الذكاء الاصطناعي غير صحيحة');
        return false;
      }

      final url = _buildModelsUrl(settings.baseUrl!);
      final request = await _httpClient.getUrl(url);

      _addHeaders(request, settings);

      final response = await request.close().timeout(
        settings.requestTimeout,
        onTimeout: () => throw TimeoutException(
          'انتهت مهلة الاتصال',
          settings.requestTimeout,
        ),
      );

      await response.drain<void>();

      final isSuccessful =
          response.statusCode >= 200 && response.statusCode < 300;

      if (!isSuccessful) {
        debugPrint('فشل اختبار الاتصال: ${response.statusCode}');
      }

      return isSuccessful;
    } on SocketException catch (e) {
      debugPrint('خطأ في الشبكة: $e');
      return false;
    } on TimeoutException catch (e) {
      debugPrint('انتهت مهلة الاتصال: $e');
      return false;
    } catch (e) {
      debugPrint('خطأ في اختبار الاتصال: $e');
      return false;
    }
  }

  @override
  Future<String> chat({
    required AiSettings settings,
    required List<Map<String, String>> messages,
    bool stream = false,
    String? requestId,
  }) async {
    if (!settings.isValid) {
      throw AiException('إعدادات الذكاء الاصطناعي غير صحيحة');
    }

    // فحص rate limiting
    await _checkRateLimit(settings);

    // فحص cache
    final cacheKey = _generateCacheKey(messages, settings);
    final cachedResponse = _responseCache[cacheKey];
    if (cachedResponse != null && !cachedResponse.isExpired) {
      debugPrint('استخدام الاستجابة المحفوظة مؤقتاً');
      return cachedResponse.content;
    }

    int retryCount = 0;
    final maxRetries = settings.maxRetries;

    while (retryCount <= maxRetries) {
      try {
        final startTime = DateTime.now();
        final response = await _makeRequest(
          settings,
          messages,
          stream,
          requestId,
        );
        final endTime = DateTime.now();

        // حفظ في cache
        _cacheResponse(cacheKey, response);

        debugPrint(
          'تم الطلب في ${endTime.difference(startTime).inMilliseconds}ms',
        );
        return response;
      } on AiRateLimitException catch (e) {
        if (retryCount == maxRetries) rethrow;
        debugPrint(
          'تم تجاوز الحد الأقصى، الانتظار: ${e.retryAfter.inSeconds}s',
        );
        await Future.delayed(e.retryAfter);
        retryCount++;
      } on SocketException catch (e) {
        if (retryCount == maxRetries) {
          throw AiConnectionException('خطأ في الشبكة: ${e.message}');
        }
        await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
        retryCount++;
      } on TimeoutException catch (e) {
        if (retryCount == maxRetries) {
          throw AiConnectionException('انتهت مهلة الاتصال: ${e.message}');
        }
        await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
        retryCount++;
      } catch (e) {
        if (retryCount == maxRetries) rethrow;
        await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
        retryCount++;
      }
    }

    throw AiException('فشل الطلب بعد $maxRetries محاولات');
  }

  @override
  Stream<String> chatStream({
    required AiSettings settings,
    required List<Map<String, String>> messages,
    String? requestId,
  }) async*
{
    if (!settings.isValid) {
      throw AiException('إعدادات الذكاء الاصطناعي غير صحيحة');
    }

    await _checkRateLimit(settings);

    final url = _buildChatUrl(settings.baseUrl!);
    final request = await _httpClient.postUrl(url);

    _addHeaders(request, settings);

    final body = _buildRequestBody(messages, settings, stream: true);
    request.add(utf8.encode(jsonEncode(body)));

    final response = await request.close().timeout(settings.requestTimeout);

    if (response.statusCode >= 400) {
      final errorText = await utf8.decodeStream(response);
      throw _handleErrorResponse(response.statusCode, errorText);
    }

    await for (final chunk in response.transform(utf8.decoder)) {
      final lines = chunk.split('\n');
      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') break;

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List<dynamic>?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices.first['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              if (content != null) {
                yield content;
              }
            }
          } catch (e) {
            debugPrint('خطأ في تحليل streaming data: $e');
          }
        }
      }
    }
  }

  @override
  Future<Map<String, dynamic>> getUsageStats(AiSettings settings) async {
    try {
      // بعض المزودين لا يدعمون إحصائيات الاستخدام
      // نرجع بيانات أساسية
      return {
        'requests_today': _requestCounts[_getTodayKey()] ?? 0,
        'cached_responses': _responseCache.length,
        'last_request_time': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  @override
  Future<List<String>> getAvailableModels(AiSettings settings) async {
    try {
      final url = _buildModelsUrl(settings.baseUrl!);
      final request = await _httpClient.getUrl(url);
      _addHeaders(request, settings);

      final response = await request.close().timeout(settings.requestTimeout);
      final responseText = await utf8.decodeStream(response);

      if (response.statusCode >= 400) {
        throw _handleErrorResponse(response.statusCode, responseText);
      }

      final json = jsonDecode(responseText) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>?;

      if (data != null) {
        return data
            .where((model) => model is Map<String, dynamic>)
            .map((model) => model['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('خطأ في جلب قائمة النماذج: $e');
      return [];
    }
  }

  // الطرق الخاصة
  Future<String> _makeRequest(
    AiSettings settings,
    List<Map<String, String>> messages,
    bool stream,
    String? requestId,
  ) async {
    final url = _buildChatUrl(settings.baseUrl!);
    final request = await _httpClient.postUrl(url);

    _addHeaders(request, settings, requestId: requestId);

    final body = _buildRequestBody(messages, settings, stream: stream);
    request.add(utf8.encode(jsonEncode(body)));

    final response = await request.close().timeout(settings.requestTimeout);
    final responseText = await utf8.decodeStream(response);

    if (response.statusCode >= 400) {
      throw _handleErrorResponse(response.statusCode, responseText);
    }

    return _parseResponse(responseText);
  }

  String _parseResponse(String responseText) {
    try {
      final json = jsonDecode(responseText) as Map<String, dynamic>;

      // محاولة تحليل تنسيق OpenAI
      final choices = json['choices'] as List<dynamic>?;
      if (choices != null && choices.isNotEmpty) {
        final choice = choices.first as Map<String, dynamic>;
        final message = choice['message'] as Map<String, dynamic>?;
        if (message != null) {
          final content = message['content']?.toString() ?? '';
          return content;
        }
      }

      // تنسيقات أخرى محتملة
      final content = json['content']?.toString();
      if (content != null) return content;

      final text = json['text']?.toString();
      if (text != null) return text;

      // إرجاع النص الخام إذا فشل التحليل
      return responseText;
    } catch (e) {
      debugPrint('خطأ في تحليل الاستجابة: $e');
      return responseText;
    }
  }

  Exception _handleErrorResponse(int statusCode, String responseText) {
    switch (statusCode) {
      case 401:
        return AiConnectionException(
          'مفتاح API غير صحيح',
          code: 'INVALID_API_KEY',
        );
      case 429:
        // محاولة استخراج وقت الانتظار من headers
        final retryAfter = Duration(seconds: 60); // افتراضي
        return AiRateLimitException(
          'تم تجاوز حد الطلبات',
          retryAfter,
          code: 'RATE_LIMIT',
        );
      case 400:
        return AiException('طلب غير صحيح: $responseText', code: 'BAD_REQUEST');
      case 500:
      case 502:
      case 503:
        return AiConnectionException('خطأ في الخادم', code: 'SERVER_ERROR');
      default:
        return AiException(
          'خطأ HTTP $statusCode: $responseText',
          code: 'HTTP_ERROR',
        );
    }
  }

  Uri _buildChatUrl(Uri base) {
    final basePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    final path = '$basePath/chat/completions';
    return base.replace(path: path.isEmpty ? '/chat/completions' : path);
  }

  Uri _buildModelsUrl(Uri base) {
    final basePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    final path = '$basePath/models';
    return base.replace(path: path.isEmpty ? '/models' : path);
  }

  void _addHeaders(
    HttpClientRequest request,
    AiSettings settings,
    {
    String? requestId,
  }) {
    if (settings.apiKey != null && settings.apiKey!.isNotEmpty) {
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${settings.apiKey}',
      );
    }

    request.headers.contentType = ContentType.json;
    request.headers.set('User-Agent', 'ClothesPos/1.0');

    if (requestId != null) {
      request.headers.set('X-Request-ID', requestId);
    }
  }

  Map<String, dynamic> _buildRequestBody(
    List<Map<String, String>> messages,
    AiSettings settings,
    {
    bool stream = false,
  }) {
    return {
      'model': settings.model,
      'messages': messages,
      'temperature': settings.temperature,
      'stream': stream,
      'max_tokens': 1000,
      // إعدادات إضافية للحصول على استجابات أفضل
      'top_p': 0.9,
      'frequency_penalty': 0.1,
      'presence_penalty': 0.1,
    };
  }

  Future<void> _checkRateLimit(AiSettings settings) async {
    final key = settings.baseUrl.toString();
    final todayKey = _getTodayKey();

    // تحديث عداد الطلبات
    _requestCounts[todayKey] = (_requestCounts[todayKey] ?? 0) + 1;

    // فحص بسيط للحد من الطلبات المتتالية
    final existingTimer = _rateLimitTimers[key];
    if (existingTimer != null && existingTimer.isActive) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _rateLimitTimers[key] = Timer(_rateLimitWindow, () {
      _rateLimitTimers.remove(key);
    });
  }

  String _generateCacheKey(
    List<Map<String, String>> messages,
    AiSettings settings,
  ) {
    final messageText = messages.map((m) => m['content'] ?? '').join('|');
    final keyData = '$messageText|${settings.model}|${settings.temperature}';
    final bytes = utf8.encode(keyData);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _cacheResponse(String key, String response) {
    // تنظيف cache إذا امتلأ
    if (_responseCache.length >= _maxCacheSize) {
      final oldestKey = _responseCache.keys.first;
      _responseCache.remove(oldestKey);
    }

    _responseCache[key] = _CachedResponse(
      content: response,
      timestamp: DateTime.now(),
      expiry: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  void dispose() {
    _httpClient.close();
    for (final timer in _rateLimitTimers.values) {
      timer.cancel();
    }
    _rateLimitTimers.clear();
    _responseCache.clear();
  }
}

// فئة مساعدة للاستجابات المحفوظة مؤقتاً
class _CachedResponse {
  final String content;
  final DateTime timestamp;
  final DateTime expiry;

  _CachedResponse({
    required this.content,
    required this.timestamp,
    required this.expiry,
  });

  bool get isExpired => DateTime.now().isAfter(expiry);
}
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../data/models/facebook_message.dart';
import '../../presentation/settings/bloc/settings_cubit.dart';
import '../config/constants.dart';

/// Facebook API helper service.
/// Merged polling helpers (from new_facebook) into the canonical service.
class FacebookApiService {
  final SettingsCubit _settingsCubit;
  final http.Client _client;
  Timer? _pollingTimer;
  DateTime _lastChecked = DateTime.now();
  Function(List<FacebookMessage>)? _onNewMessages;

  FacebookApiService(this._settingsCubit, {http.Client? client})
    : _client = client ?? http.Client();

  String get _pageAccessToken =>
      _settingsCubit.state.facebookPageAccessToken ?? '';
  String get _pageId => _settingsCubit.state.facebookPageId ?? '';
  int get _pollingInterval {
    try {
      final dynamic s = _settingsCubit.state;
      final val = s.pollingInterval;
      if (val is int) return val;
    } catch (_) {}
    return 30;
  }

  /// Fetch messages newer than `since`.
  Future<List<FacebookMessage>> fetchNewMessages(DateTime since) async {
    if (_pageAccessToken.isEmpty || _pageId.isEmpty) {
      if (kDebugMode) {
        print('Facebook credentials not configured');
      }
      return [];
    }

    if (kDebugMode) {
      final preview = _pageAccessToken.length > 10
          ? _pageAccessToken.substring(0, 10) + '...'
          : _pageAccessToken;
      print(
        'Fetching messages with Page ID: $_pageId and Access Token: $preview',
      );
    }

    final url =
        'https://graph.facebook.com/${ApiConstants.facebookApiVersion}/$_pageId/conversations?fields=messages{from,message,created_time,id}&access_token=$_pageAccessToken';

    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch conversations: ${response.body}');
    }
    final data = jsonDecode(response.body);
    final List<FacebookMessage> messages = [];
    if (data['data'] != null) {
      for (final conv in data['data']) {
        final convId = conv['id'] ?? '';
        final msgs = conv['messages']?['data'] ?? [];
        for (final msg in msgs) {
          try {
            final created = DateTime.parse(msg['created_time'] ?? '');
            if (created.isAfter(since)) {
              messages.add(FacebookMessage.fromJson(msg, convId));
            }
          } catch (_) {}
        }
      }
    }
    return messages;
  }

  /// Backwards-compatible convenience: fetch messages since last check.
  Future<List<FacebookMessage>> fetchNewMessagesSinceLastCheck() async {
    final msgs = await fetchNewMessages(_lastChecked);
    _lastChecked = DateTime.now();
    return msgs;
  }

  /// Start a periodic poll; onNewMessages will be called with any new messages.
  void startPolling(Function(List<FacebookMessage>) onNewMessages) {
    _onNewMessages = onNewMessages;
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(Duration(seconds: _pollingInterval), (
      timer,
    ) async {
      final messages = await fetchNewMessagesSinceLastCheck();
      if (messages.isNotEmpty && _onNewMessages != null) {
        _onNewMessages!(messages);
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void updatePollingInterval(int interval) {
    if (_pollingTimer != null) {
      stopPolling();
      startPolling(_onNewMessages!);
    }
  }

  Future<void> sendReply(String conversationId, String replyText) async {
    final url =
        'https://graph.facebook.com/${ApiConstants.facebookApiVersion}/$conversationId/messages?access_token=$_pageAccessToken';
    final response = await _client.post(
      Uri.parse(url),
      body: jsonEncode({
        'message': {'text': replyText},
      }),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send reply: ${response.body}');
    }
  }
}

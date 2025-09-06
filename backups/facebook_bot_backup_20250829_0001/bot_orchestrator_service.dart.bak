import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'facebook_api_service.dart';
import 'action_executor.dart';
import '../../assistant/ai/ai_service.dart';
import 'polling_service.dart';

class BotOrchestratorService {
  final FacebookApiService facebookApiService;
  final ActionExecutor actionExecutor;
  final AiService aiService;
  final Function(Object)? onError;
  Timer? _timer;
  bool _isRunning = false;

  BotOrchestratorService({
    required this.facebookApiService,
    required this.actionExecutor,
    required this.aiService,
    this.onError,
    this.pollingService,
  });

  final PollingService? pollingService;

  Future<DateTime> _getLastTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('bot_last_timestamp') ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  Future<void> _setLastTimestamp(DateTime ts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bot_last_timestamp', ts.millisecondsSinceEpoch);
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    if (pollingService != null) {
      // Use polling service's callback mechanism
      pollingService!.start(
        onNewMessages: (msgs) async {
          for (final msg in msgs) {
            try {
              final aiResult = await aiService.ask(msg.messageText);
              final reply = await actionExecutor.execute(aiResult.action);
              await facebookApiService.sendReply(msg.conversationId, reply);
              await _setLastTimestamp(msg.createdTime);
            } catch (e) {
              if (kDebugMode) print('Error handling polled message: $e');
              onError?.call(e);
            }
          }
        },
      );
    } else {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
    }
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
  }

  Future<void> _poll() async {
    try {
      final lastTs = await _getLastTimestamp();
      final messages = await facebookApiService.fetchNewMessages(lastTs);
      for (final msg in messages) {
        final aiResult = await aiService.ask(msg.messageText);
        final reply = await actionExecutor.execute(aiResult.action);
        await facebookApiService.sendReply(msg.conversationId, reply);
        await _setLastTimestamp(msg.createdTime);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in bot polling: $e');
      }
      onError?.call(e);
    }
  }

  bool get isRunning => _isRunning;
}

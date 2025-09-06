import 'dart:async';
import 'package:clothes_pos/core/logging/app_logger.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-Speech service for speaking text aloud
class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  Future<bool> initialize() async {
    try {
      await _flutterTts.setLanguage('ar-SA');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _isInitialized = true;
      AppLogger.i('TextToSpeechService initialized successfully');
      return true;
    } catch (e, st) {
      AppLogger.e('TextToSpeechService initialization failed', error: e, stackTrace: st);
      return false;
    }
  }

  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;

  Future<void> speak(String text, {String language = 'ar-SA'}) async {
    if (!_isInitialized) {
      throw Exception('TextToSpeechService not initialized. Call initialize() first.');
    }
    try {
      _isSpeaking = true;
      await _flutterTts.speak(text);
      _isSpeaking = false;
    } catch (e, st) {
      _isSpeaking = false;
      AppLogger.e('Failed to speak text', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> stop() async {
    if (!_isSpeaking) {
      return;
    }
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e, st) {
      AppLogger.e('Failed to stop speaking', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<List<dynamic>> getAvailableLanguages() async {
    return await _flutterTts.getLanguages;
  }

  void dispose() {
    _flutterTts.stop();
  }
}

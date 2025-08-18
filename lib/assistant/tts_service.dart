import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _inited = false;

  Future<void> init({String language = 'ar-SA'}) async {
    if (_inited) return;
    // حاول اختيار صوت عربي واضح إن وجد
    final voices = await _tts.getVoices;
    String? targetVoice;
    for (final v in voices ?? []) {
      final name = (v['name'] ?? '').toString().toLowerCase();
      final locale = (v['locale'] ?? '').toString().toLowerCase();
      if (locale.startsWith('ar') &&
          (name.contains('hoda') ||
              name.contains('naayf') ||
              name.contains('arabic'))) {
        targetVoice = v['name'] as String?;
        break;
      }
    }
    await _tts.setLanguage(language);
    if (targetVoice != null) {
      await _tts.setVoice({'name': targetVoice, 'locale': language});
    }
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.38);
    _inited = true;
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();

  void dispose() {
    _tts.stop();
  }
}

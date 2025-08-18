// Minimal speech service interface to decouple UI from actual implementation.
// Initially a stub that simulates recognition to avoid adding platform deps.
// Later, you can implement with `speech_to_text` and proper permissions.

import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

enum SpeechState { idle, listening, processing }

class SpeechResult {
  final String recognizedText;
  final bool isFinal;
  SpeechResult({required this.recognizedText, required this.isFinal});
}

abstract class ISpeechService {
  SpeechState get state;
  Stream<SpeechResult> get results;
  Stream<double> get soundLevel; // 0.0..1.0 convenience level
  Future<bool> initialize({String? localeId});
  Future<void> startListening({String? localeId});
  Future<void> stop();
  Future<void> cancel();
  void dispose();
}

// A fake implementation for development without platform changes.
class FakeSpeechService implements ISpeechService {
  final _controller = StreamController<SpeechResult>.broadcast();
  SpeechState _state = SpeechState.idle;
  final _levelCtrl = StreamController<double>.broadcast();

  Timer? _timer;

  @override
  SpeechState get state => _state;
  @override
  Stream<double> get soundLevel => _levelCtrl.stream;

  @override
  Stream<SpeechResult> get results => _controller.stream;

  @override
  Future<void> cancel() async {
    _timer?.cancel();
    _timer = null;
    _setState(SpeechState.idle);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
    _levelCtrl.close();
  }

  @override
  Future<bool> initialize({String? localeId}) async {
    // Simulate permission/availability OK
    return true;
  }

  @override
  Future<void> startListening({String? localeId}) async {
    if (_state != SpeechState.idle) return;
    _setState(SpeechState.listening);
    // Simulate streaming partials then final + mic level
    int step = 0;
    double level = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      step++;
      // Fake mic level oscillation 0..1
      level = (level + 0.2) % 1.2;
      _levelCtrl.add(level > 1.0 ? 2.0 - level : level);
      if (step == 1) {
        _controller.add(SpeechResult(recognizedText: 'كيف', isFinal: false));
      } else if (step == 2) {
        _controller.add(
          SpeechResult(recognizedText: 'كيف ادخل', isFinal: false),
        );
      } else if (step == 3) {
        _controller.add(
          SpeechResult(recognizedText: 'كيف ادخل مصروف', isFinal: true),
        );
        _setState(SpeechState.processing);
      } else {
        t.cancel();
        _setState(SpeechState.idle);
      }
    });
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _setState(SpeechState.processing);
    // Simulate brief processing then go idle
    await Future.delayed(const Duration(milliseconds: 300));
    _setState(SpeechState.idle);
  }

  void _setState(SpeechState s) {
    _state = s;
  }
}

// Real implementation using speech_to_text.
class STTSpeechService implements ISpeechService {
  final _stt = stt.SpeechToText();
  final _controller = StreamController<SpeechResult>.broadcast();
  final _levelCtrl = StreamController<double>.broadcast();

  SpeechState _state = SpeechState.idle;
  String? _bestLocaleId;

  @override
  Stream<double> get soundLevel => _levelCtrl.stream;

  @override
  SpeechState get state => _state;

  @override
  Stream<SpeechResult> get results => _controller.stream;

  @override
  Future<bool> initialize({String? localeId}) async {
    final available = await _stt.initialize(
      onStatus: (status) {
        // no-op
      },
      onError: (error) {
        // no-op
      },
    );
    if (!available) return false;
    try {
      final locales = await _stt.locales();
      // Prefer Arabic locales explicitly
      final ids = locales.map((l) => l.localeId.toLowerCase()).toList();
      String? chosen;
      for (final pref in ['ar-ly', 'ar-sa', 'ar-eg', 'ar']) {
        chosen = ids.firstWhere((id) => id.startsWith(pref), orElse: () => '');
        if (chosen.isNotEmpty) break;
      }
      if (chosen == null || chosen.isEmpty) {
        final sys = await _stt.systemLocale();
        chosen = sys?.localeId;
      }
      _bestLocaleId = chosen;
    } catch (_) {
      try {
        final sys = await _stt.systemLocale();
        _bestLocaleId = sys?.localeId;
      } catch (_) {}
    }
    return true;
  }

  @override
  Future<void> startListening({String? localeId}) async {
    if (_state != SpeechState.idle) return;
    _state = SpeechState.listening;
    final useLocale = localeId ?? _bestLocaleId;
    await _stt.listen(
      localeId: useLocale,
      onResult: (res) {
        final txt = res.recognizedWords;
        final isFinal = res.finalResult;
        if (txt != null && isFinal != null) {
          _controller.add(SpeechResult(recognizedText: txt, isFinal: isFinal));
          if (isFinal) {
            _state = SpeechState.processing;
          }
        } else {
          // Handle the case where recognizedWords or finalResult is null
          // This might indicate an issue with the speech recognition result
          // or an unexpected state from the plugin.
          // Log a warning or handle it gracefully based on application needs.
          print('Warning: recognizedWords or finalResult is null from speech_to_text plugin.');
        }
      },
      onSoundLevelChange: (level) {
        // Normalize/clamp mic level to ~0..1 (Windows may report larger ranges)
        double v = level;
        if (v.isNaN) v = 0.0;
        if (v < 0) v = 0.0;
        // normalize if > 1
        if (v > 1.0) v = 1.0;
        _levelCtrl.add(v);
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
        partialResults: true,
      ),
    );
  }

  @override
  Future<void> stop() async {
    await _stt.stop();
    _state = SpeechState.idle;
  }

  @override
  Future<void> cancel() async {
    await _stt.cancel();
    _state = SpeechState.idle;
  }

  @override
  void dispose() {
    _stt.stop();
    _controller.close();
    _levelCtrl.close();
  }
}

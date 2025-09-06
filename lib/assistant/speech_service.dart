// Minimal speech service interface to decouple UI from actual implementation.
// Initially a stub that simulates recognition to avoid adding platform deps.
// Later, you can implement with `speech_to_text` and proper permissions.

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

ISpeechService createSpeechService() {
  // Only Windows speech_to_text implementation remains
  return FakeSpeechService();
}
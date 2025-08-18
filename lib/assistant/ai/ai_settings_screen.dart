import 'package:flutter/cupertino.dart';
import '../../data/repositories/settings_repository.dart';
import '../../core/di/locator.dart';
import 'dart:async';
import '../speech_service.dart';
import 'ai_service.dart';
import 'ai_client.dart';
import 'ai_settings_loader.dart';
import 'ai_models.dart';
import '../tts_service.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final _repo = sl<SettingsRepository>();
  final _enabled = ValueNotifier<bool>(false);
  final _baseUrlCtrl = TextEditingController();
  final _modelCtrl = TextEditingController(text: 'llama-3.1-8b-instant');
  final _apiKeyCtrl = TextEditingController(
    text: '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',
  );
  final _tempCtrl = TextEditingController(text: '0.2');

  // AI Chat (moved from AiChatScreen)
  late ISpeechService _speech;
  late final AiService _ai;
  late final TtsService _tts;
  bool _listening = false;
  bool _processing = false;
  double _level = 0.0;
  String _heard = '';
  String _answer = '';
  final List<Map<String, String>> _history = [];
  final TextEditingController _textController = TextEditingController();
  bool _connected = true;
  StreamSubscription<double>? _levelSub;

  @override
  void initState() {
    super.initState();
    _speech = STTSpeechService();
    _ai = AiService(
      client: OpenAiCompatibleClient(),
      loadSettings: loadAiSettings,
    );
    _tts = TtsService();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSpeech());
  }

  Future<void> _load() async {
    _enabled.value = (await _repo.get('ai_enabled')) == '1';
    _baseUrlCtrl.text =
        (await _repo.get('ai_base_url')) ?? 'https://api.groq.com/openai/v1';
    _modelCtrl.text = (await _repo.get('ai_model')) ?? 'llama-3.1-8b-instant';
    _apiKeyCtrl.text = (await _repo.get('ai_api_key')) ?? '';
    _tempCtrl.text = (await _repo.get('ai_temperature')) ?? '0.2';
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    await _repo.set('ai_enabled', _enabled.value ? '1' : '0');
    await _repo.set(
      'ai_base_url',
      _baseUrlCtrl.text.trim().isEmpty ? null : _baseUrlCtrl.text.trim(),
    );
    await _repo.set(
      'ai_model',
      _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
    );
    await _repo.set(
      'ai_api_key',
      _apiKeyCtrl.text.trim().isEmpty ? null : _apiKeyCtrl.text.trim(),
    );
    await _repo.set(
      'ai_temperature',
      _tempCtrl.text.trim().isEmpty ? null : _tempCtrl.text.trim(),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _initSpeech() async {
    final ok = await _speech.initialize();
    if (!ok) {
      _speech.dispose();
      _speech = FakeSpeechService();
      await _speech.initialize();
    }
    _speech.results.listen((r) async {
      if (!mounted) return;
      setState(() => _heard = r.recognizedText);
      if (r.isFinal) {
        final text = r.recognizedText.trim();
        if (text.isEmpty) return;
        await _handle(text);
      }
    });
    _levelSub = _speech.soundLevel.listen((lvl) {
      if (mounted) setState(() => _level = lvl.clamp(0.0, 1.0));
    });
  }

  Future<void> _handle(String text) async {
    setState(() {
      _processing = true;
      _answer = '...';
      _heard = text;
    });
    try {
      final res = await _ai.ask(text);
      String say = '';
      if (res.action is AnswerFaqAction) {
        say = (res.action as AnswerFaqAction).text;
      }
      final fallback = res.rawModelText ?? '';
      final toSpeak = say.isEmpty ? fallback : say;
      setState(() {
        _answer = toSpeak;
        _history.add({'question': text, 'answer': toSpeak});
      });
      if (toSpeak.isNotEmpty) {
        await _tts.speak(toSpeak);
      }
      setState(() => _connected = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _answer = 'خطأ في الاتصال بالمزوّد.';
          _connected = false;
        });
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
    } else {
      setState(() {
        _heard = '';
        _answer = '';
      });
      await _speech.startListening(localeId: 'ar-SA');
      if (mounted) setState(() => _listening = true);
    }
  }

  @override
  void dispose() {
    _levelSub?.cancel();
    _speech.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('إعدادات الذكاء الاصطناعي'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: _enabled,
              builder: (_, v, __) => Row(
                children: [
                  const Expanded(child: Text('تفعيل الذكاء الاصطناعي')),
                  CupertinoSwitch(
                    value: v,
                    onChanged: (nv) => _enabled.value = nv,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Base URL (OpenAI-compatible)'),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _baseUrlCtrl,
              placeholder: 'https://api.deepseek.com',
            ),
            const SizedBox(height: 12),
            const Text('Model (e.g., deepseek-chat)'),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _modelCtrl,
              placeholder: 'gpt-4o-mini',
            ),
            const SizedBox(height: 12),
            const Text('API Key'),
            const SizedBox(height: 6),
            CupertinoTextField(controller: _apiKeyCtrl, placeholder: 'sk-...'),
            const SizedBox(height: 12),
            const Text('Temperature'),
            const SizedBox(height: 6),
            CupertinoTextField(controller: _tempCtrl, placeholder: '0.2'),

            const SizedBox(height: 16),
            // Divider replacement (Cupertino doesn't have Divider)
            Container(height: 1, color: CupertinoColors.systemGrey4),
            const SizedBox(height: 8),
            const Text('محادثة الذكاء الاصطناعي'),
            const SizedBox(height: 8),
            // Start of inline AI Chat UI
            Row(
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  onPressed: _toggle,
                  child: Icon(
                    _listening ? CupertinoIcons.mic_fill : CupertinoIcons.mic,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: _listening ? _level : 0.0,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: CupertinoColors.activeGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    controller: _textController,
                    placeholder: 'اكتب سؤالك هنا...',
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        _handle(val.trim());
                        _textController.clear();
                      }
                    },
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(CupertinoIcons.arrow_up_circle_fill),
                  onPressed: () {
                    final val = _textController.text.trim();
                    if (val.isNotEmpty) {
                      _handle(val);
                      _textController.clear();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _connected ? CupertinoIcons.cloud_fill : CupertinoIcons.cloud,
                  color: _connected
                      ? CupertinoColors.activeGreen
                      : CupertinoColors.systemRed,
                ),
                const SizedBox(width: 8),
                Text(_connected ? 'متصل بالمزود' : 'غير متصل'),
              ],
            ),
            const SizedBox(height: 12),
            if (_heard.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سؤال: $_heard',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('جواب: $_answer'),
                    if (_processing)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: CupertinoActivityIndicator(),
                      ),
                    const SizedBox(height: 12),
                    Container(height: 1, color: CupertinoColors.systemGrey4),
                  ],
                ),
              ),
            SizedBox(
              height: 220,
              child: ListView.builder(
                itemCount: _history.length,
                itemBuilder: (ctx, i) {
                  final h = _history.reversed.toList()[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سؤال: ${h['question']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('جواب: ${h['answer']}'),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        height: 1,
                        color: CupertinoColors.systemGrey4,
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(onPressed: _save, child: const Text('حفظ')),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import '../../data/repositories/settings_repository.dart';
import 'promo_share_sheet.dart';
import '../../data/models/parent_product.dart';
import '../../data/repositories/product_repository.dart';
import '../../core/di/locator.dart';
import 'dart:async';
import '../speech_service.dart';
import '../../speech/speech_service.dart' as tts;
import 'ai_service.dart';
import 'ai_client.dart';
import 'ai_settings_loader.dart';
import '../theme_provider.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'assistant_executor.dart';

// Animated waveform widget for sound level visualization
class AnimatedWaveform extends StatefulWidget {
  final double level;
  final bool isActive;

  const AnimatedWaveform({
    super.key,
    required this.level,
    required this.isActive,
  });

  @override
  State<AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<AnimatedWaveform>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant AnimatedWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update animation based on level
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 40),
      painter: WaveformPainter(
        level: widget.level,
        isActive: widget.isActive,
        animationValue: _animation.value,
        activeColor: CupertinoTheme.of(context).primaryColor,
        inactiveColor: CupertinoColors.systemGrey,
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double level;
  final bool isActive;
  final double animationValue;
  final Color activeColor;
  final Color inactiveColor;

  WaveformPainter({
    required this.level,
    required this.isActive,
    required this.animationValue,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isActive ? activeColor : inactiveColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final centerY = size.height / 2;
    final amplitude = isActive ? level * 15 : 5.0;

    path.moveTo(0, centerY);

    for (int i = 0; i <= size.width.toInt(); i++) {
      final x = i.toDouble();
      final normalizedX = x / size.width;
      final waveValue = math.sin(
        normalizedX * 10 + animationValue * 2 * math.pi,
      );
      final y = centerY + waveValue * amplitude * (isActive ? 1.0 : 0.3);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Animated processing indicator
class ProcessingIndicator extends StatefulWidget {
  final bool isProcessing;

  const ProcessingIndicator({super.key, required this.isProcessing});

  @override
  State<ProcessingIndicator> createState() => _ProcessingIndicatorState();
}

class _ProcessingIndicatorState extends State<ProcessingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value * 2 * math.pi,
          child: Icon(
            CupertinoIcons.sparkles,
            size: 24,
            color: CupertinoTheme.of(
              context,
            ).primaryColor.withValues(alpha: 0.7 + 0.3 * _animation.value),
          ),
        );
      },
    );
  }
}

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  void _openPromoShareSheet() async {
    // جلب المنتجات من المستودع
    final productRepo = sl<ProductRepository>();
    final products = await productRepo.searchParentsByName('', limit: 50);
    // دالة توليد النص التسويقي عبر الذكاء الاصطناعي
    Future<String> generatePromoText(ParentProduct product) async {
      // يمكنك هنا استخدام AiService أو أي خدمة مجانية
      final prompt =
          'اكتب منشور دعائي قصير وجذاب لمنتج باسم "${product.name}" ووصفه "${product.description ?? ''}". أضف في نهاية المنشور هاشتاق #منظومة_مرن.';
      final res = await _ai.ask(prompt);
      var text = res.rawModelText ?? '';
      if (!text.contains('#منظومة_مرن')) {
        text = text.trim() + '\n#منظومة_مرن';
      }
      return text;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => PromoShareSheet(
          products: products,
          generatePromoText: generatePromoText,
        ),
      ),
    );
  }

  final _repo = sl<SettingsRepository>();
  final _enabled = ValueNotifier<bool>(false);
  final _baseUrlCtrl = TextEditingController();
  final _modelCtrl = TextEditingController(text: 'llama-3.1-8b-instant');
  final _apiKeyCtrl = TextEditingController(
    text: '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',
  );
  final _tempCtrl = TextEditingController(text: '0.2');
  final _executor = AssistantExecutor();

  // AI Chat (moved from AiChatScreen)
  late final FakeSpeechService _speech;
  late final AiService _ai;
  late final tts.TextToSpeechService _tts;
  bool _listening = false;
  bool _processing = false;
  double _level = 0.0;
  String _heard = '';
  String _answer = '';
  final List<Map<String, String>> _history = [];
  final TextEditingController _textController = TextEditingController();
  bool _connected = true;
  StreamSubscription? _resultSub;
  StreamSubscription<double>? _levelSub;

  @override
  void initState() {
    super.initState();
    _speech = FakeSpeechService();
    // Correctly initialize AiService asynchronously
    _initializeAiService();
    _tts = tts.TextToSpeechService();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSpeech());
  }

  Future<void> _initializeAiService() async {
    final settings = await loadAiSettings();
    if (mounted) {
      setState(() {
        _ai = AiService.fromSettings(OpenAiCompatibleClient(), settings);
      });
    }
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
      // Handle initialization error
      return;
    }
    _resultSub = _speech.results.listen((r) async {
      if (!mounted) return;
      setState(() => _heard = r.recognizedText);
      if (r.isFinal) {
        final text = r.recognizedText.trim();
        if (text.isEmpty) return;
        await _handle(text);
      }
    });
    _levelSub = _speech.soundLevel.listen((lvl) {
      if (mounted) setState(() => _level = lvl);
    });
  }

  Future<void> _handle(String text) async {
    setState(() {
      _processing = true;
      _answer = '...';
      _heard = text;
      _textController.clear();
    });
    try {
      final res = await _ai.ask(text);
      // Use the executor to handle the action
      final executionResult = await _executor.execute(context, res.action);
      final toSpeak = executionResult ?? res.rawModelText ?? '';

      if (mounted) {
        setState(() {
          _answer = toSpeak;
          _history.add({'question': text, 'answer': toSpeak});
          _connected = true;
        });
      }

      if (toSpeak.isNotEmpty) {
        await _tts.speak(toSpeak);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _answer = 'خطأ في الاتصال بالمزوّد أو في تنفيذ الأمر.';
          _connected = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) {
        setState(() => _listening = false);
      }
    } else {
      setState(() {
        _heard = '';
        _answer = '';
      });
      await _speech.startListening(localeId: 'ar-SA');
      if (mounted) {
        setState(() => _listening = true);
      }
    }
  }

  @override
  void dispose() {
    _resultSub?.cancel();
    _levelSub?.cancel();
    _speech.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: const Text('إعدادات الذكاء الاصطناعي'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _openPromoShareSheet,
                  child: const Icon(CupertinoIcons.speaker_2_fill),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => themeProvider.toggleTheme(),
                  child: Icon(
                    themeProvider.isDarkMode
                        ? CupertinoIcons.light_max
                        : CupertinoIcons.moon,
                  ),
                ),
              ],
            ),
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
                CupertinoTextField(
                  controller: _apiKeyCtrl,
                  placeholder: 'sk-வுகளை',
                ),
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
                        _listening
                            ? CupertinoIcons.mic_fill
                            : CupertinoIcons.mic,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: AnimatedWaveform(
                          level: _level,
                          isActive: _listening,
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
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    const question =
                        'ماهي المهام التي يستطيع الذكاء الاصطناعي مساعدتي فيها';
                    _textController.text = question;
                    _handle(question);
                  },
                  child: const Text(
                    'ماهي المهام التي يستطيع الذكاء الاصطناعي مساعدتي فيها',
                    style: TextStyle(
                      color: CupertinoColors.activeBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      _connected
                          ? CupertinoIcons.cloud_fill
                          : CupertinoIcons.cloud,
                      color: _connected
                          ? CupertinoColors.activeGreen
                          : CupertinoColors.systemRed,
                    ),
                    const SizedBox(width: 8),
                    Text(_connected ? 'متصل بالمزود' : 'غير متصل'),
                    const Spacer(),
                    if (_processing)
                      const ProcessingIndicator(isProcessing: true),
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
                        Container(
                          height: 1,
                          color: CupertinoColors.systemGrey4,
                        ),
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
                CupertinoButton.filled(
                  onPressed: _save,
                  child: const Text('حفظ'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'faq_data.dart';
import 'speech_service.dart';
import 'tts_service.dart';
import 'checklist_data.dart';
import 'tutorial_overlay.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  late ISpeechService _speech; // allow fallback swap
  String _heard = '';
  String _answer = '';
  bool _listening = false;
  double _level = 0.0;
  // Training assistant runs offline only (FAQ + TTS). No AI here.
  late final TtsService _tts;
  final bool _voiceReplies = true;
  bool _processing = false;

  StreamSubscription<double>? _levelSub;
  Timer? _autoStop;
  Timer? _breath;
  bool _gotLevel = false;
  List<ChecklistItem> _checklist = [];

  void _startBreathing() {
    _breath?.cancel();
    _breath = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!_listening) return;
      if (!_gotLevel) {
        final t = DateTime.now().millisecondsSinceEpoch / 600.0;
        final v =
            0.15 + 0.85 * (0.5 + 0.5 * math.sin(t * 2 * 3.141592653589793));
        if (!mounted) return;
        setState(() => _level = v);
      } else {
        // استهلك آخر قيمة مستوى وصلت
        _gotLevel = false;
      }
    });
  }

  void _stopBreathing() {
    _breath?.cancel();
    _breath = null;
  }

  bool _isLikelyArabic(String s) {
    final ar = RegExp(r'[\u0621-\u064A]');
    return ar.hasMatch(s);
  }

  @override
  void initState() {
    super.initState();
    _checklist = checklistItems;
    _speech = STTSpeechService();
    _tts = TtsService();
    _init();
  }

  void _attachStreams() {
    _levelSub?.cancel();
    _speech.results.listen((r) async {
      if (!mounted) return;
      setState(() => _heard = r.recognizedText);
      if (r.isFinal) {
        final text = r.recognizedText.trim();
        setState(() => _listening = false);
        if (text.isEmpty || !_isLikelyArabic(text)) {
          await _showNotUnderstoodAlert();
          return;
        }
        await _handleText(text);
      }
    });
    _levelSub = _speech.soundLevel.listen((lvl) {
      if (!mounted) return;
      _gotLevel = true;
      setState(() => _level = lvl.clamp(0.0, 1.0));
    });
  }

  Future<void> _handleText(String text) async {
    setState(() {
      _processing = true;
      _answer = '... جارٍ المعالجة';
    });
    try {
      // Offline training assistant: FAQ only
      final m = matchFaq(text);
      final ans = m.entry?.answer ?? 'لم أفهم سؤالك بدقة. حاول بصيغة أبسط.';
      setState(() => _answer = ans);
      if (_voiceReplies) {
        await _tts.speak(ans);
      }
    } catch (e) {
      setState(() => _answer = 'تعذر المعالجة.');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _init() async {
    final ok = await _speech
        .initialize(); // let service pick best Arabic locale
    if (!ok) {
      _speech.dispose();
      _speech = FakeSpeechService();
      await _speech.initialize();
    }
    _attachStreams();
  }

  @override
  void dispose() {
    _levelSub?.cancel();
    _autoStop?.cancel();
    _speech.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_listening) {
      _autoStop?.cancel();
      _autoStop = null;
      await _speech.stop();
      if (_answer.isEmpty && _heard.isNotEmpty) {
        final res = matchFaq(_heard);
        if (mounted) {
          setState(() {
            _answer =
                res.entry?.answer ?? 'لم أفهم سؤالك بدقة. حاول بصيغة أبسط.';
          });
        }
      }
      if (mounted) setState(() => _listening = false);
      _stopBreathing();
    } else {
      setState(() {
        _heard = '';
        _answer = '';
      });
      await _speech.startListening(localeId: 'ar-SA');
      if (mounted) setState(() => _listening = true);
      _startBreathing();
      _autoStop?.cancel();
      _autoStop = Timer(const Duration(seconds: 8), () async {
        if (!mounted) return;
        if (_listening) {
          await _speech.stop();
          if (_answer.isEmpty && _heard.isNotEmpty) {
            final res = matchFaq(_heard);
            if (mounted) {
              setState(() {
                _answer =
                    res.entry?.answer ?? 'لم أفهم سؤالك بدقة. حاول بصيغة أبسط.';
              });
            }
          }
          if (mounted) setState(() => _listening = false);
        }
      });
    }
  }

  Future<void> _showNotUnderstoodAlert() async {
    if (!mounted) return;
    await showCupertinoDialog(
      context: context,
      builder: (_) => const CupertinoAlertDialog(
        title: Text('لم أفهم الصوت'),
        content: Text(
          'الصوت أو اللغة غير مفهومة. حاول التحدث بوضوح أو بالعربية.',
        ),
      ),
    );
  }

  Widget _buildChecklist() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          ListTile(
            title: const Text(
              'قائمة البداية السريعة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Text('شرح'),
              onPressed: () async {
                await showTutorial(context, [
                  const TutorialStep(
                    title: 'إضافة أول منتج',
                    description:
                        'من تبويب المخزون، افتح المنتجات ثم اضغط + لإضافة منتج وأدخل التفاصيل واحفظ.',
                  ),
                  const TutorialStep(
                    title: 'إجراء أول عملية بيع',
                    description:
                        'من تبويب المبيعات، أضف العناصر إلى السلة ثم اضغط إتمام البيع واختر وسيلة الدفع.',
                  ),
                  const TutorialStep(
                    title: 'فتح جلسة صندوق',
                    description:
                        'عند أول عملية بيع سيُطلب فتح الجلسة. أدخل الرصيد الافتتاحي وابدأ العمل.',
                  ),
                ]);
              },
            ),
          ),
          ..._checklist.map((item) {
            return CheckboxListTile(
              title: Text(item.title),
              subtitle: Text(item.description),
              value: item.isDone,
              onChanged: (bool? value) {
                setState(() {
                  item.isDone = value ?? false;
                });
              },
            );
          }),
        ],
      ),
    );
  }

  List<Widget> _buildCategorizedFaq(BuildContext context) {
    final faqs = allFaq();
    final categories = <String, List<FaqEntry>>{};
    for (final faq in faqs) {
      final cat = faq.category ?? 'متفرقات';
      categories.putIfAbsent(cat, () => []).add(faq);
    }

    return categories.entries.map((entry) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ExpansionTile(
          title: Text(entry.key),
          children: entry.value.map((faq) {
            return ListTile(
              title: Text(faq.question),
              subtitle: Text(faq.answer),
              onTap: () {
                setState(() {
                  _heard = faq.question;
                  _answer = faq.answer;
                });
                if (_voiceReplies) {
                  _tts.speak(faq.answer);
                }
              },
            );
          }).toList(),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('المساعد التدريبي'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const SizedBox(height: 12),
            const Text('اسألني صوتياً عن طريقة استخدام النظام'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'النص المسموع:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(_heard.isEmpty ? '—' : _heard),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الإجابة:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  if (_processing)
                    const CupertinoActivityIndicator()
                  else
                    Text(_answer.isEmpty ? '—' : _answer),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildChecklist(),
            const SizedBox(height: 24),
            const Text(
              'أو تصفح الأسئلة الشائعة:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._buildCategorizedFaq(context),
            // مؤشر مستوى الصوت
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: _listening ? _level : 0.0,
                  backgroundColor: CupertinoColors.systemGrey5,
                  color: CupertinoColors.activeBlue,
                ),
              ),
            ),
            CupertinoButton.filled(
              onPressed: _toggle,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _listening ? CupertinoIcons.mic_slash : CupertinoIcons.mic,
                  ),
                  const SizedBox(width: 8),
                  Text(_listening ? 'إيقاف الاستماع' : 'ابدأ الاستماع'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

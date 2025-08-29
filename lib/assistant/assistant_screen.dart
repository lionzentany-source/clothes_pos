import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'faq_data.dart';
import 'speech_service.dart';
import 'tts_service.dart';
import 'checklist_data.dart';
import 'tutorial_overlay.dart';
import '../data/repositories/settings_repository.dart';
import '../core/di/locator.dart';

// Checklist item with persistent storage
class PersistentChecklistItem extends ChecklistItem {
  final SettingsRepository _repo;

  PersistentChecklistItem({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    super.iconName,
    super.helpLink,
    super.difficulty = 1,
    super.isDone = false,
    required SettingsRepository repo,
  }) : _repo = repo;

  Future<void> setDone(bool done) async {
    isDone = done;
    await _repo.set('checklist_$id', done ? '1' : '0');
  }

  Future<bool> loadStatus() async {
    final status = await _repo.get('checklist_$id');
    isDone = status == '1';
    return isDone;
  }
}

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
  List<PersistentChecklistItem> _checklist = [];
  final _repo = sl<SettingsRepository>();

  @override
  void initState() {
    super.initState();
    _speech = FakeSpeechService();
    _tts = TtsService();
    _init();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    final List<PersistentChecklistItem> items = [];

    for (final item in checklistItems) {
      final persistentItem = PersistentChecklistItem(
        id: item.id,
        title: item.title,
        description: item.description,
        category: item.category,
        iconName: item.iconName,
        helpLink: item.helpLink,
        difficulty: item.difficulty,
        isDone: item.isDone,
        repo: _repo,
      );

      await persistentItem.loadStatus();
      items.add(persistentItem);
    }

    setState(() {
      _checklist = items;
    });
  }

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
    // تنظيم العناصر حسب الفئة
    final Map<String, List<PersistentChecklistItem>> categorizedItems = {};
    for (final item in _checklist) {
      if (!categorizedItems.containsKey(item.category)) {
        categorizedItems[item.category] = [];
      }
      categorizedItems[item.category]!.add(item);
    }

    // حساب نسبة الإكمال الإجمالية
    final completionPercentage = getTotalCompletionPercentage() * 100;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          ListTile(
            title: const Text(
              'قائمة البداية السريعة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'أكملت ${completionPercentage.toStringAsFixed(0)}% من المهام',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Text('شرح'),
              onPressed: () async {
                // إنشاء خطوات البرنامج التعليمي من العناصر المحددة
                final tutorialSteps = _checklist
                    .where((item) => !item.isDone)
                    .take(5)
                    .map(
                      (item) => TutorialStep(
                        title: item.title,
                        description: item.description,
                      ),
                    )
                    .toList();

                if (tutorialSteps.isNotEmpty) {
                  await showTutorial(context, tutorialSteps);
                } else {
                  // إذا تم إكمال جميع المهام، عرض رسالة تهنئة
                  await showCupertinoDialog(
                    context: context,
                    builder: (_) => CupertinoAlertDialog(
                      title: const Text('تهانينا!'),
                      content: const Text(
                        'لقد أكملت جميع المهام في قائمة البدء السريع.',
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('حسناً'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),

          // شريط التقدم الإجمالي
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: getTotalCompletionPercentage(),
                backgroundColor: CupertinoColors.systemGrey5,
                color: CupertinoColors.activeGreen,
              ),
            ),
          ),

          // عرض العناصر مصنفة
          ...categorizedItems.entries.map((entry) {
            final categoryName = entry.key;
            final items = entry.value;
            final categoryCompletion = getCategoryCompletionPercentage(
              categoryName,
            );

            return ExpansionTile(
              title: Row(
                children: [
                  Text(
                    categoryName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(categoryCompletion * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
              leading: Icon(_getCategoryIcon(categoryName)),
              children: items.map((item) {
                return CheckboxListTile(
                  title: Text(item.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.description),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(
                            item.difficulty,
                            (index) => const Icon(
                              CupertinoIcons.star_fill,
                              size: 14,
                              color: CupertinoColors.systemYellow,
                            ),
                          ),
                          ...List.generate(
                            3 - item.difficulty,
                            (index) => const Icon(
                              CupertinoIcons.star,
                              size: 14,
                              color: CupertinoColors.systemGrey3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  value: item.isDone,
                  onChanged: (bool? value) async {
                    final newValue = value ?? false;
                    await item.setDone(newValue);
                    setState(() {
                      // تحديث العنصر في القائمة
                      final index = _checklist.indexWhere(
                        (i) => i.id == item.id,
                      );
                      if (index != -1) {
                        _checklist[index] = item;
                      }
                    });
                  },
                  secondary: item.helpLink != null
                      ? IconButton(
                          icon: const Icon(CupertinoIcons.question_circle),
                          onPressed: () {
                            // عرض مساعدة إضافية
                            showCupertinoDialog(
                              context: context,
                              builder: (_) => CupertinoAlertDialog(
                                title: Text(item.title),
                                content: Text(item.description),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text('حسناً'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : null,
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  // الحصول على أيقونة مناسبة لكل فئة
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'أساسيات':
        return CupertinoIcons.house_fill;
      case 'المخزون':
        return CupertinoIcons.cube_box_fill;
      case 'المبيعات':
        return CupertinoIcons.cart_fill;
      case 'المالية':
        return CupertinoIcons.money_dollar_circle_fill;
      case 'التقارير':
        return CupertinoIcons.chart_bar_fill;
      case 'متقدم':
        return CupertinoIcons.gear_alt_fill;
      default:
        return CupertinoIcons.checkmark_circle_fill;
    }
  }

  // الحصول على أيقونة مناسبة لكل فئة من الأسئلة الشائعة
  IconData _getFaqCategoryIcon(String category) {
    switch (category) {
      case 'الفواتير والمبيعات':
        return CupertinoIcons.cart_fill;
      case 'المصروفات':
        return CupertinoIcons.money_dollar_circle_fill;
      case 'الإعدادات والبيانات':
        return CupertinoIcons.settings_solid;
      case 'المنتجات والمخزون':
        return CupertinoIcons.cube_box_fill;
      case 'التقارير':
        return CupertinoIcons.chart_bar_fill;
      case 'العملاء':
        return CupertinoIcons.person_2_fill;
      case 'الموردين':
        return CupertinoIcons.bus;
      case 'الذكاء الاصطناعي':
        return CupertinoIcons.wand_stars;
      default:
        return CupertinoIcons.question_circle_fill;
    }
  }

  // الحصول على أيقونة مناسبة للسؤال الشائع
  IconData _getFaqIcon(String iconName) {
    switch (iconName) {
      case 'receipt':
        return CupertinoIcons.doc_text;
      case 'print':
        return CupertinoIcons.printer;
      case 'point_of_sale':
        return CupertinoIcons.creditcard;
      case 'account_balance':
        return CupertinoIcons.money_dollar;
      case 'discount':
        return CupertinoIcons.tag;
      case 'cancel':
        return CupertinoIcons.xmark_circle;
      case 'search':
        return CupertinoIcons.search;
      case 'payments':
        return CupertinoIcons.money_dollar_circle;
      case 'category':
        return CupertinoIcons.square_grid_2x2;
      case 'bar_chart':
        return CupertinoIcons.chart_bar;
      case 'backup':
        return CupertinoIcons.cloud_upload;
      case 'restore':
        return CupertinoIcons.cloud_download;
      case 'settings':
        return CupertinoIcons.settings;
      case 'inventory':
        return CupertinoIcons.cube_box;
      case 'edit':
        return CupertinoIcons.pencil;
      case 'qr_code':
        return CupertinoIcons.qrcode;
      case 'checklist':
        return CupertinoIcons.list_bullet;
      case 'trending_up':
        return CupertinoIcons.graph_circle;
      case 'person_add':
        return CupertinoIcons.person_add;
      case 'local_shipping':
        return CupertinoIcons.car;
      case 'smart_toy':
        return CupertinoIcons.wand_stars;
      case 'mic':
        return CupertinoIcons.mic;
      default:
        return CupertinoIcons.info_circle;
    }
  }

  List<Widget> _buildCategorizedFaq(BuildContext context) {
    // استخدام الدالة الجديدة للحصول على جميع الفئات
    final categories = getAllFaqCategories();
    final popularFaqs = getPopularFaq();

    final List<Widget> widgets = [];

    // إضافة قسم الأسئلة الشائعة في الأعلى
    if (popularFaqs.isNotEmpty) {
      widgets.add(
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'الأسئلة الأكثر شيوعاً',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ...popularFaqs.map((faq) => _buildFaqTile(faq)),
            ],
          ),
        ),
      );
    }

    // إضافة الأسئلة حسب الفئات
    for (final category in categories) {
      final categoryFaqs = getFaqByCategory(category);
      if (categoryFaqs.isEmpty) continue;

      widgets.add(
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ExpansionTile(
            title: Text(category),
            leading: Icon(_getFaqCategoryIcon(category)),
            children: categoryFaqs.map((faq) => _buildFaqTile(faq)).toList(),
          ),
        ),
      );
    }

    return widgets;
  }

  // بناء عنصر واجهة للسؤال الشائع
  Widget _buildFaqTile(FaqEntry faq) {
    return ExpansionTile(
      title: Text(
        faq.question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      leading: faq.iconName != null ? Icon(_getFaqIcon(faq.iconName!)) : null,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // إضافة صورة توضيحية إذا كانت متوفرة
              if (faq.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      faq.imageUrl!,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'images/faq/product_placeholder.svg',
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Text(faq.answer),
              if (faq.relatedQuestions != null &&
                  faq.relatedQuestions!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'أسئلة ذات صلة:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...getRelatedFaq(faq.id).map(
                      (relatedFaq) => InkWell(
                        onTap: () {
                          setState(() {
                            _heard = relatedFaq.question;
                            _answer = relatedFaq.answer;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.arrow_right_circle,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  relatedFaq.question,
                                  style: const TextStyle(
                                    color: CupertinoColors.activeBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
      onExpansionChanged: (expanded) {
        if (expanded) {
          setState(() {
            _heard = faq.question;
            _answer = faq.answer;
          });

          if (_voiceReplies) {
            _tts.speak(faq.answer);
          }
        }
      },
    );
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
                  Text(_heard.isEmpty ? '-' : _heard),
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
                    Text(_answer.isEmpty ? '-' : _answer),
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

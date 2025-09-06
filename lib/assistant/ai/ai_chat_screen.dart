import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:provider/provider.dart';

import '../speech_service.dart';
import '../../speech/speech_service.dart' as tts;
import 'ai_service.dart';
import 'ai_models.dart';
import 'assistant_executor.dart';
import '../theme_provider.dart';
import 'ai_settings_loader.dart';
import 'ai_client.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // الخدمات الأساسية
  late final FakeSpeechService _speechService;
  AiService? _aiService; // Nullable until initialized
  late final tts.TextToSpeechService _ttsService;
  late final AssistantExecutor _executor;

  // حالة الواجهة
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isConnected = true;
  bool _isInitializing = true; // To show a loading indicator at start
  double _soundLevel = 0.0;
  String _currentQuestion = '';
  String _currentAnswer = '';

  // المحادثات والاقتراحات
  final List<ConversationMessage> _messages = [];
  final List<String> _suggestions = [];

  // تحكم في النص
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // اشتراكات في البيانات
  StreamSubscription<SpeechResult>? _speechSubscription;
  StreamSubscription<double>? _soundLevelSubscription;

  // الرسوم المتحركة
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  // إعدادات الواجهة
  bool _showSuggestions = true;
  bool _autoSpeak = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _initializeAnimations();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused && _isListening) {
      _stopListening();
    }
  }

  Future<void> _initializeServices() async {
    setState(() {
      _isInitializing = true;
    });
    final settings = await loadAiSettings();
    _speechService = FakeSpeechService();
    _aiService = AiService.fromSettings(OpenAiCompatibleClient(), settings);
    _ttsService = tts.TextToSpeechService();
    _executor = AssistantExecutor();
    await _loadInitialData();
    setState(() {
      _isInitializing = false;
    });
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadInitialData() async {
    await _initializeSpeechService();
    _loadConversationHistory();
    _loadSmartSuggestions();
  }

  Future<void> _initializeSpeechService() async {
    try {
      final initialized = await _speechService.initialize();
      if (!initialized) {
        debugPrint('فشل في تهيئة خدمة التعرف على الصوت');
        return;
      }
      _speechSubscription = _speechService.results.listen((result) {
        if (!mounted) {
          return;
        }
        setState(() {
          _currentQuestion = result.recognizedText;
        });
        if (result.isFinal && result.recognizedText.trim().isNotEmpty) {
          _handleUserInput(result.recognizedText.trim());
        }
      });
      _soundLevelSubscription = _speechService.soundLevel.listen((level) {
        if (mounted) {
          setState(() {
            _soundLevel = level;
          });
        }
      });
    } catch (e) {
      debugPrint('خطأ في تهيئة خدمة الصوت: $e');
    }
  }

  void _loadConversationHistory() {
    if (_aiService == null) {
      return;
    }
    final history = _aiService!.getConversationHistory();
    setState(() {
      _messages.clear();
      for (final entry in history) {
        _messages.add(
          ConversationMessage(
            text: entry.question,
            isUser: true,
            timestamp: entry.timestamp,
          ),
        );
        _messages.add(
          ConversationMessage(
            text: entry.answer,
            isUser: false,
            timestamp: entry.timestamp,
          ),
        );
      }
    });
  }

  void _loadSmartSuggestions() {
    if (_aiService == null) {
      return;
    }
    final suggestions = _aiService!.getSmartSuggestions();
    setState(() {
      _suggestions.clear();
      _suggestions.addAll(suggestions);
    });
  }

  Future<void> _handleUserInput(String input) async {
    if (input.trim().isEmpty || _aiService == null) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _currentAnswer = '';
      _textController.clear();
    });

    _addMessage(input, isUser: true);

    try {
      final result = await _aiService!.ask(input);
      if (!mounted) {
        return;
      }
      final response = await _executor.execute(context, result.action);
      if (!mounted) {
        return;
      }
      final displayText =
          response ?? result.rawModelText ?? 'لم أحصل على إجابة واضحة';

      _addMessage(displayText, isUser: false);

      if (_autoSpeak && displayText.isNotEmpty) {
        await _speakText(displayText);
        if (!mounted) {
          return;
        }
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _currentAnswer = displayText;
        _isConnected = true;
      });

      _updateContextualSuggestions(input);
    } catch (e) {
      final errorMessage = _getErrorMessage(e);
      _addMessage(errorMessage, isUser: false);
      setState(() {
        _currentAnswer = errorMessage;
        _isConnected = e is! AiConnectionException;
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is AiConnectionException) {
      return 'خطأ في الاتصال بالخدمة. يرجى التحقق من الإنترنت والمحاولة لاحقاً.';
    } else if (error is AiRateLimitException) {
      return 'تم تجاوز حد الطلبات. يرجى الانتظار قليلاً والمحاولة مرة أخرى.';
    } else if (error is AiException) {
      return 'حدث خطأ: ${error.message}';
    }
    return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
  }

  void _addMessage(String text, {required bool isUser}) {
    setState(() {
      _messages.add(
        ConversationMessage(
          text: text,
          isUser: isUser,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _updateContextualSuggestions(String userInput) {
    if (_aiService == null) {
      return;
    }
    final newSuggestions = _aiService!.getSmartSuggestions(context: userInput);
    setState(() {
      _suggestions.clear();
      _suggestions.addAll(newSuggestions);
    });
  }

  Future<void> _speakText(String text) async {
    try {
      await _ttsService.speak(text);
    } catch (e) {
      debugPrint('خطأ في تشغيل النطق: $e');
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    try {
      setState(() {
        _currentQuestion = '';
        _currentAnswer = '';
      });
      await _speechService.startListening(localeId: 'ar-SA');
      setState(() {
        _isListening = true;
      });
      _pulseController.repeat(reverse: true);
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('خطأ في بدء الاستماع: $e');
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speechService.stop();
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
      });
      _pulseController.stop();
      _pulseController.reset();
    } catch (e) {
      debugPrint('خطأ في إيقاف الاستماع: $e');
    }
  }

  void _sendTextMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _handleUserInput(text);
    }
  }

  Future<void> _clearConversation() async {
    if (_aiService == null) {
      return;
    }
    if (!context.mounted) {
      return; // safety: ensure context still mounted before dialog
    }
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('مسح المحادثة'),
        content: const Text(
          'هل تريد مسح جميع المحادثات؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('إلغاء'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('مسح'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (result == true) {
      await _aiService!.clearConversationHistory();
      setState(() {
        _messages.clear();
        _currentQuestion = '';
        _currentAnswer = '';
      });
    }
  }

  Future<void> _exportConversation() async {
    if (_aiService == null) {
      return;
    }
    try {
      final filePath = await _aiService!.exportConversationHistory();
      if (filePath != null && mounted) {
        if (!context.mounted) {
          return; // safety
        }
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('تم التصدير'),
            content: Text('تم حفظ المحادثات في:\n$filePath'),
            actions: [
              CupertinoDialogAction(
                child: const Text('موافق'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (!context.mounted) {
          return; // safety
        }
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('خطأ'),
            content: Text('فشل في تصدير المحادثات:\n${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('موافق'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showUsageStatistics() {
    final stats = _aiService?.getUsageStatistics() ?? {};
    if (!context.mounted) {
      return; // safety
    }
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('إحصائيات الاستخدام'),
        content: Column(
          children: [
            _buildStatRow('إجمالي الطلبات', '${stats['total_requests']}'),
            _buildStatRow('الطلبات الناجحة', '${stats['successful_requests']}'),
            _buildStatRow('معدل النجاح', '${stats['success_rate']}%'),
            _buildStatRow(
              'متوسط وقت الاستجابة',
              '${stats['average_response_time_ms']}ms',
            ),
            _buildStatRow('عدد المحادثات', '${stats['conversation_entries']}'),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('موافق'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator(radius: 20)),
      );
    }
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: const Text('المساعد الذكي'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _showSettingsBottomSheet,
                  child: const Icon(CupertinoIcons.settings),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _clearConversation,
                  child: const Icon(CupertinoIcons.clear),
                ),
              ],
            ),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).pop(),
              child: const Icon(CupertinoIcons.back),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildStatusBar(),
                Expanded(child: _buildMessagesArea()),
                if (_showSuggestions && _suggestions.isNotEmpty)
                  _buildSuggestionsArea(),
                _buildInputArea(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).barBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: CupertinoTheme.of(
              context,
            ).primaryContrastingColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isConnected ? CupertinoIcons.wifi : CupertinoIcons.wifi_slash,
            size: 16,
            color: _isConnected
                ? CupertinoColors.activeGreen
                : CupertinoColors.systemRed,
          ),
          const SizedBox(width: 8),
          Text(
            _isConnected ? 'متصل' : 'غير متصل',
            style: const TextStyle(fontSize: 14),
          ),
          const Spacer(),
          if (_isProcessing) ...[
            const CupertinoActivityIndicator(radius: 8),
            const SizedBox(width: 8),
            const Text('جاري المعالجة...', style: TextStyle(fontSize: 14)),
          ],
          if (!_isProcessing) ...[
            const Icon(CupertinoIcons.chat_bubble, size: 16),
            const SizedBox(width: 4),
            Text(
              '${_messages.where((m) => m.isUser).length}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessagesArea() {
    if (_messages.isEmpty && !_isProcessing && _currentQuestion.isEmpty) {
      return _buildWelcomeScreen();
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount:
          _messages.length +
          (_isProcessing || _currentQuestion.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _messages.length) {
          return _buildMessageBubble(_messages[index]);
        } else {
          return _buildCurrentConversation();
        }
      },
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return Transform.scale(
                scale:
                    1.0 + 0.1 * math.sin(_waveController.value * 2 * math.pi),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: CupertinoTheme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.sparkles,
                    size: 40,
                    color: CupertinoTheme.of(context).primaryColor,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'مرحباً! أنا مساعدك الذكي',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'يمكنني مساعدتك في إدارة متجرك والإجابة على استفساراتك',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'ابدأ بطرح سؤال أو اضغط على زر الميكروفون للتحدث',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.tertiaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ConversationMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: CupertinoTheme.of(context).primaryColor,
              child: const Icon(
                CupertinoIcons.sparkles,
                size: 16,
                color: CupertinoColors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? CupertinoTheme.of(context).primaryColor
                    : CupertinoTheme.of(context).barBackgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser
                          ? CupertinoColors.white
                          : CupertinoTheme.of(
                              context,
                            ).textTheme.textStyle.color,
                    ),
                  ),
                  if (message.timestamp != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.timestamp!),
                      style: TextStyle(
                        fontSize: 12,
                        color: message.isUser
                            ? CupertinoColors.white.withValues(alpha: 0.7)
                            : CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: CupertinoColors.systemGrey4,
              child: const Icon(CupertinoIcons.person_fill, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentConversation() {
    if (_currentQuestion.isEmpty && !_isProcessing) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        if (_currentQuestion.isNotEmpty)
          _buildMessageBubble(
            ConversationMessage(
              text: _currentQuestion,
              isUser: true,
              timestamp: DateTime.now(),
            ),
          ),
        if (_isProcessing || _currentAnswer.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: CupertinoTheme.of(context).primaryColor,
                  child: _isProcessing
                      ? const CupertinoActivityIndicator(
                          radius: 8,
                          color: CupertinoColors.white,
                        )
                      : const Icon(
                          CupertinoIcons.sparkles,
                          size: 16,
                          color: CupertinoColors.white,
                        ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoTheme.of(context).barBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isProcessing ? 'جاري التفكير...' : _currentAnswer,
                      style: TextStyle(
                        color: CupertinoTheme.of(
                          context,
                        ).textTheme.textStyle.color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionsArea() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: CupertinoTheme.of(context).barBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              onPressed: () => _handleUserInput(_suggestions[index]),
              child: Text(
                _suggestions[index],
                style: const TextStyle(fontSize: 14),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).barBackgroundColor,
        border: Border(
          top: BorderSide(
            color: CupertinoTheme.of(
              context,
            ).primaryContrastingColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          if (_isListening)
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 12),
              child: AnimatedWaveform(
                level: _soundLevel,
                isActive: _isListening,
              ),
            ),
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isListening ? _pulseAnimation.value : 1.0,
                    child: CupertinoButton(
                      padding: const EdgeInsets.all(12),
                      color: _isListening
                          ? CupertinoColors.systemRed
                          : CupertinoTheme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(25),
                      onPressed: _toggleListening,
                      child: Icon(
                        _isListening
                            ? CupertinoIcons.mic_fill
                            : CupertinoIcons.mic,
                        color: CupertinoColors.white,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoTextField(
                  controller: _textController,
                  focusNode: _textFocusNode,
                  placeholder: 'اكتب رسالتك هنا...',
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendTextMessage(),
                  decoration: BoxDecoration(
                    color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CupertinoButton(
                padding: const EdgeInsets.all(12),
                color: CupertinoTheme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(25),
                onPressed: _sendTextMessage,
                child: const Icon(
                  CupertinoIcons.arrow_up,
                  color: CupertinoColors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSettingsBottomSheet() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('إعدادات المحادثة'),
        actions: [
          CupertinoActionSheetAction(
            child: Text(
              _showSuggestions ? 'إخفاء الاقتراحات' : 'عرض الاقتراحات',
            ),
            onPressed: () {
              setState(() {
                _showSuggestions = !_showSuggestions;
              });
              Navigator.of(context).pop();
            },
          ),

          CupertinoActionSheetAction(
            child: Text(
              _autoSpeak ? 'إيقاف النطق التلقائي' : 'تفعيل النطق التلقائي',
            ),
            onPressed: () {
              setState(() {
                _autoSpeak = !_autoSpeak;
              });
              Navigator.of(context).pop();
            },
          ),

          CupertinoActionSheetAction(
            child: const Text('تصدير المحادثات'),
            onPressed: () {
              Navigator.of(context).pop();
              _exportConversation();
            },
          ),

          CupertinoActionSheetAction(
            child: const Text('إحصائيات الاستخدام'),
            onPressed: () {
              Navigator.of(context).pop();
              _showUsageStatistics();
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('إلغاء'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speechSubscription?.cancel();
    _soundLevelSubscription?.cancel();
    _speechService.dispose();
    _ttsService.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }
}

// نموذج رسالة المحادثة
class ConversationMessage {
  final String text;
  final bool isUser;
  final DateTime? timestamp;

  ConversationMessage({
    required this.text,
    required this.isUser,
    this.timestamp,
  });
}

// عنصر الموجة الصوتية المتحركة
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
    with SingleTickerProviderStateMixin {
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
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
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
      },
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

    final centerY = size.height / 2;
    final amplitude = isActive ? math.max(level * 15, 5.0) : 3.0;

    final path = Path();
    path.moveTo(0, centerY);

    for (double x = 0; x <= size.width; x += 2) {
      final normalizedX = x / size.width;
      final frequency = isActive ? 8.0 : 4.0;
      final phase = animationValue * 2 * math.pi;

      final waveValue = math.sin(normalizedX * frequency * math.pi + phase);
      final y = centerY + waveValue * amplitude * (isActive ? 1.0 : 0.3);

      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/cubit/bot_control_cubit.dart';
import '../../core/services/bot_orchestrator_service.dart';
import '../../core/services/facebook_api_service.dart';
import '../../core/services/action_executor.dart';
import '../../assistant/ai/ai_service.dart';
import '../../presentation/settings/bloc/settings_cubit.dart';
import '../../data/models/facebook_message.dart';
import '../../core/di/locator.dart'; // Added locator import

class BotControlScreen extends StatefulWidget {
  const BotControlScreen({super.key});

  @override
  State<BotControlScreen> createState() => _BotControlScreenState();
}

class _BotControlScreenState extends State<BotControlScreen> {
  List<FacebookMessage> _messages = [];
  bool _loadingMessages = false;
  String? _error;
  final TextEditingController _testMsgCtrl = TextEditingController();
  bool _isConnected = true;

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loadingMessages = true;
      _error = null;
    });
    try {
      final settingsCubit = context.read<SettingsCubit>();
      final facebookApi = FacebookApiService(settingsCubit);
      final since = DateTime.now().subtract(const Duration(days: 2));
      final msgs = await facebookApi.fetchNewMessages(since);
      setState(() {
        _messages = msgs;
      });
      _showNotification('تم تحديث الرسائل بنجاح');
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      _showNotification('حدث خطأ أثناء جلب الرسائل');
    } finally {
      setState(() {
        _loadingMessages = false;
      });
    }
  }

  Future<void> _sendTestMessage() async {
    if (_testMsgCtrl.text.trim().isEmpty || _messages.isEmpty) return;
    final msg = _messages.first;
    final settingsCubit = context.read<SettingsCubit>();
    final facebookApi = FacebookApiService(settingsCubit);
    try {
      await facebookApi.sendReply(msg.conversationId, _testMsgCtrl.text.trim());
      _testMsgCtrl.clear();
      await _loadMessages();
      _showNotification('تم إرسال الرسالة بنجاح');
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      _showNotification('فشل إرسال الرسالة');
    }
  }

  Future<void> _checkConnection() async {
    // تحقق من الاتصال عبر اختبار بسيط (مثلاً جلب صفحة فيسبوك)
    try {
      final settingsCubit = context.read<SettingsCubit>();
      final facebookApi = FacebookApiService(settingsCubit);
      await facebookApi.fetchNewMessages(
        DateTime.now().subtract(const Duration(minutes: 1)),
      );
      setState(() {
        _isConnected = true;
      });
    } catch (_) {
      setState(() {
        _isConnected = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _checkConnection();
  }

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.watch<SettingsCubit>();
    final orchestrator = BotOrchestratorService(
      facebookApiService: FacebookApiService(settingsCubit),
      actionExecutor: ActionExecutor(),
      aiService: sl<AiService>(),
      onError: (_) => context.read<BotControlCubit>().reportError(),
    );
    return BlocProvider(
      create: (_) => BotControlCubit(orchestrator),
      child: BlocBuilder<BotControlCubit, BotControlState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('تحكم بوت الذكاء الاصطناعي'),
              actions: [
                Icon(
                  _isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: _isConnected ? Colors.green : Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 12),
              ],
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          state == BotControlState.running
                              ? 'البوت يعمل'
                              : state == BotControlState.stopped
                              ? 'البوت متوقف'
                              : 'حدث خطأ',
                          style: TextStyle(
                            fontSize: 20,
                            color: state == BotControlState.error
                                ? Colors.red
                                : null,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: state == BotControlState.running
                            ? () => context.read<BotControlCubit>().stopBot()
                            : () => context.read<BotControlCubit>().startBot(),
                        child: Text(
                          state == BotControlState.running
                              ? 'إيقاف البوت'
                              : 'تشغيل البوت',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadingMessages ? null : _loadMessages,
                        tooltip: 'تحديث الرسائل',
                      ),
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'خطأ: $_error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Expanded(
                  child: _loadingMessages
                      ? const Center(child: CircularProgressIndicator())
                      : _messages.isEmpty
                      ? const Center(child: Text('لا توجد رسائل حديثة'))
                      : ListView.builder(
                          itemCount: _messages.length,
                          itemBuilder: (ctx, i) {
                            final msg = _messages[i];
                            return ListTile(
                              title: Text(msg.messageText),
                              subtitle: Text(
                                'من: ${msg.senderId} • ${msg.createdTime}',
                              ),
                              trailing: Text(msg.conversationId),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _testMsgCtrl,
                          decoration: const InputDecoration(
                            labelText: 'إرسال رسالة تجريبية للبوت',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _sendTestMessage,
                        child: const Text('إرسال'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:clothes_pos/core/di/locator.dart';
import 'package:clothes_pos/data/repositories/settings_repository.dart';
import 'ai_models.dart';

Future<AiSettings> loadAiSettings() async {
  final repo = sl<SettingsRepository>();
  final enabled = (await repo.get('ai_enabled')) == '1';
  final baseUrlStr =
      await repo.get('ai_base_url') ?? 'https://api.groq.com/openai/v1';
  final model = (await repo.get('ai_model')) ?? 'llama-3.1-8b-instant';
  final apiKey = (await repo.get('ai_api_key'));
  final tempStr = await repo.get('ai_temperature');
  final temperature = double.tryParse(tempStr ?? '') ?? 0.2;
  final baseUrl = (baseUrlStr.isEmpty) ? null : Uri.tryParse(baseUrlStr);
  return AiSettings(
    enabled: enabled,
    baseUrl: baseUrl,
    model: model,
    apiKey: apiKey,
    temperature: temperature,
  );
}

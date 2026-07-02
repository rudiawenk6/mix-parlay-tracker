import 'dart:convert';
import 'package:http/http.dart' as http;
import 'settings_service.dart';
import 'ai_models.dart';

/// AI analysis via OpenRouter API (FREE models only)
class AiService {
  static const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  /// Analyze parlay picks using AI
  static Future<String> analyzeParlay(String parlayInfo, {String? modelId}) async {
    final settings = SettingsService.instance;
    if (!settings.hasOpenRouterKey) {
      return 'Set OpenRouter API key first in Settings.';
    }

    final model = modelId ?? settings.aiModel;

    try {
      final resp = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer ${settings.openRouterKey}',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://mix-parlay-tracker.app',
        },
        body: json.encode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': '''You are a football betting analyst. Analyze the parlay picks.
Rules based on BWB365 winning pattern (29/29 legs ALL WIN):
- O/U = 52% winning legs (most reliable market)
- AH small (-0.5/-1.5) = safe, avoid AH > 1.5
- 1X2 underdog >2.0 = ok, never favorites <1.30 (bandar trap)
- Swedish Superettan = Under (defensive)
- China Super League = Over 3 (high-scoring)
- Chile Cup = AH favorite small + Over
- Brazil Serie B = O/U 2.5 balanced
- 10 leg max, 1 match = 1 leg only (no duplicate)
- Answer in Indonesian. Be concise and practical.''',
            },
            {
              'role': 'user',
              'content': parlayInfo,
            },
          ],
          'max_tokens': 1000,
        }),
      );

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final text = (data['choices']?[0]?['message']?['content'] ?? 'No analysis').toString();
        if (text.length > 4000) {
          return text.substring(0, 4000);
        }
        return text;
      } else if (resp.statusCode == 402 || resp.statusCode == 429) {
        return 'Rate limit or quota exceeded. Try a different free model in Settings.';
      } else {
        final body = resp.body;
        final preview = body.length <= 200 ? body : body.substring(0, 200);
        return 'AI Error $resp.statusCode: $preview';
      }
    } catch (e) {
      return 'AI Error: $e';
    }
  }
}

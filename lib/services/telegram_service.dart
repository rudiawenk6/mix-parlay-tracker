import 'dart:convert';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

/// Send parlay to Telegram
class TelegramService {
  static Future<bool> sendMessage(String message) async {
    final settings = SettingsService.instance;
    if (!settings.hasTelegramToken) return false;

    try {
      final url = 'https://api.telegram.org/bot${settings.telegramToken}/sendMessage';
      final resp = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'chat_id': settings.telegramChatId,
          'text': message,
          'parse_mode': 'HTML',
        }),
      );
      final data = json.decode(resp.body);
      return data['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sendParlay(List<Map<String, dynamic>> legs, {double stake = 55.0}) async {
    double totalOdds = 1.0;
    for (final leg in legs) {
      totalOdds *= (leg['odds'] as double? ?? 1.0);
    }

    var msg = '🎯 <b>MIX PARLAY ${legs.length} TEAM</b>\n';
    msg += '📊 Pattern BWB365\n';
    msg += '━━━━━━━━━━━━━━━━━━━━\n\n';

    for (var i = 0; i < legs.length; i++) {
      final leg = legs[i];
      final emoji = leg['market'] == 'O/U'
          ? (leg['pick'].toString().contains('Over') ? '⬆️' : '⬇️')
          : leg['market'] == 'AH'
              ? '🇭🇰'
              : '1️⃣';

      msg += '<b>#${(i + 1).toString().padLeft(2, '0')}</b> $emoji ${leg['match']}\n';
      msg += '     🏟 ${leg['league']}\n';
      msg += '     ⏰ ${leg['time']} | <b>${leg['pick']}</b>\n';
      msg += '     📊 Odds: <b>${leg['odds']}</b>\n\n';
    }

    msg += '━━━━━━━━━━━━━━━━━━━━\n';
    msg += '📈 <b>Total Odds: ${totalOdds.toStringAsFixed(1)}x</b>\n';
    msg += '💰 Stake $stake → Payout: <b>${(stake * totalOdds).toStringAsFixed(0)}</b>\n';

    return await sendMessage(msg);
  }
}

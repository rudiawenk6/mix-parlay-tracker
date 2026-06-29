import 'dart:convert';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

/// Fetch odds from odds API (custom domain)
class OddsService {
  /// Parse matches from odds API
  /// ot=r for finished+upcoming, ot=t for LIVE only
  static Future<List<OddsMatch>> fetchOdds({bool liveOnly = false}) async {
    final settings = SettingsService.instance;
    final ot = liveOnly ? 't' : 'r';
    final domain = settings.bwbDomain;
    final url = 'https://$domain/_view/ParGenWFH.ashx?g=2&ot=$ot&wd=&ia=0&update=true';

    // Try multiple domains if primary fails
    final domains = [domain];
    if (domain != 'letsaiabt365.com') domains.add('letsaiabt365.com');
    if (domain != 'bwbet365.com') domains.add('bwbet365.com');

    for (final d in domains) {
      try {
        final fetchUrl = 'https://$d/_view/ParGenWFH.ashx?g=2&ot=$ot&wd=&ia=0&update=true';
        final resp = await http.get(
          Uri.parse(fetchUrl),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36',
            'Referer': 'https://$d/',
            'Accept': '*/*',
          },
        ).timeout(const Duration(seconds: 15));

        if (resp.statusCode != 200) {
          if (d == domains.last) {
            throw Exception('HTTP ${resp.statusCode} from $d. All domains failed.');
          }
          continue; // try next domain
        }

        var text = resp.body.trim();
        while (text.startsWith('(')) text = text.substring(1);
        while (text.endsWith(')') || text.endsWith(';')) {
          text = text.substring(0, text.length - 1);
        }

        text = text.replaceAll("'", '"');

        List data;
        try {
          data = json.decode(text) as List;
        } catch (e) {
          if (d == domains.last) {
            throw Exception('Parse error from $d. Response format invalid.');
          }
          continue;
        }

        final matchesRoot = data[3] as List;
        final matches = <OddsMatch>[];
        final seen = <String>{};

        for (final league in matchesRoot) {
          if (league is! List) continue;
          String leagueName = 'Unknown';
          for (final item in league) {
            if (item is String && item.length > 3) {
              leagueName = item;
              break;
            }
        }

          for (final sub in league) {
            if (sub is! List) continue;
            for (final m in sub) {
              if (m is! List || m.length < 30) continue;
              try {
                final match = OddsMatch.fromArray(m, leagueName);
                final key = '${match.home}_${match.away}';
                if (!seen.contains(key) && match.home.isNotEmpty && match.away.isNotEmpty) {
                  seen.add(key);
                  matches.add(match);
                }
              } catch (_) {}
            }
          }
        }

        return matches;
      } on http.ClientException catch (e) {
        if (d == domains.last) {
          throw Exception('Network error: ${e.message}. Check internet connection.');
        }
        continue;
      } catch (e) {
        if (d == domains.last) rethrow;
        continue;
      }
    }

    return [];
  }

  /// Generate parlay picks from available matches
  static List<ParlayPick> generatePicks(List<OddsMatch> matches, {int maxLegs = 10}) {
    final picks = <ParlayPick>[];
    final usedMatches = <String>{};

    final ouPicks = <ParlayPick>[];
    final ahPicks = <ParlayPick>[];
    final x12Picks = <ParlayPick>[];

    for (final m in matches) {
      final key = '${m.home}_${m.away}';
      if (usedMatches.contains(key)) continue;

      if (m.ouOver >= 1.5 && m.ouOver <= 2.3) {
        ouPicks.add(ParlayPick(match: m, pick: 'Over 2.5', odds: m.ouOver, market: 'O/U', confidence: m.ouOver < 1.9 ? 'HIGH' : 'MED'));
      }
      if (m.ouUnder >= 1.5 && m.ouUnder <= 2.3) {
        ouPicks.add(ParlayPick(match: m, pick: 'Under 2.5', odds: m.ouUnder, market: 'O/U', confidence: m.ouUnder < 1.9 ? 'HIGH' : 'MED'));
      }
      if (m.ahHome >= 1.5 && m.ahHome <= 2.2 && m.ahLine.abs() <= 0.75) {
        ahPicks.add(ParlayPick(match: m, pick: 'AH Home ${m.ahLine}', odds: m.ahHome, market: 'AH', confidence: m.ahLine.abs() <= 0.5 ? 'HIGH' : 'MED'));
      }
      if (m.x12Home >= 2.0 && m.x12Home <= 2.5) {
        x12Picks.add(ParlayPick(match: m, pick: '1X2 Home', odds: m.x12Home, market: '1X2', confidence: 'LOW'));
      }
    }

    ouPicks.sort((a, b) => a.odds.compareTo(b.odds));
    ahPicks.sort((a, b) => a.odds.compareTo(b.odds));
    x12Picks.sort((a, b) => a.odds.compareTo(b.odds));

    for (final p in ouPicks) {
      final key = '${p.match.home}_${p.match.away}';
      if (!usedMatches.contains(key) && picks.length < 5) { usedMatches.add(key); picks.add(p); }
    }
    for (final p in ahPicks) {
      final key = '${p.match.home}_${p.match.away}';
      if (!usedMatches.contains(key) && picks.length < 8) { usedMatches.add(key); picks.add(p); }
    }
    for (final p in x12Picks) {
      final key = '${p.match.home}_${p.match.away}';
      if (!usedMatches.contains(key) && picks.length < maxLegs) { usedMatches.add(key); picks.add(p); }
    }

    return picks;
  }
}

class OddsMatch {
  final String league; final String time; final String home; final String away;
  final double x12Home; final double x12Draw; final double x12Away;
  final double ahLine; final double ahHome; final double ahAway;
  final double ouOver; final double ouUnder;

  OddsMatch({
    required this.league, required this.time, required this.home, required this.away,
    required this.x12Home, required this.x12Draw, required this.x12Away,
    required this.ahLine, required this.ahHome, required this.ahAway,
    required this.ouOver, required this.ouUnder,
  });

  factory OddsMatch.fromArray(List<dynamic> m, String leagueName) {
    double safeDouble(dynamic v, {double div = 1.0}) {
      if (v == null || v == 0 || v == '') return 0.0;
      return (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0) / div;
    }
    return OddsMatch(
      league: leagueName, time: m.length > 4 ? m[4].toString() : '',
      home: m.length > 6 ? m[6].toString() : '', away: m.length > 7 ? m[7].toString() : '',
      x12Home: safeDouble(m.length > 11 ? m[11] : 0),
      x12Draw: safeDouble(m.length > 12 ? m[12] : 0),
      x12Away: safeDouble(m.length > 13 ? m[13] : 0),
      ahLine: safeDouble(m.length > 15 ? m[15] : 0),
      ahHome: safeDouble(m.length > 17 ? m[17] : 0, div: 10),
      ahAway: safeDouble(m.length > 18 ? m[18] : 0, div: 10),
      ouOver: safeDouble(m.length > 24 ? m[24] : 0, div: 10),
      ouUnder: safeDouble(m.length > 25 ? m[25] : 0, div: 10),
    );
  }
}

class ParlayPick {
  final OddsMatch match; final String pick; final double odds; final String market; final String confidence;
  ParlayPick({required this.match, required this.pick, required this.odds, required this.market, required this.confidence});
}

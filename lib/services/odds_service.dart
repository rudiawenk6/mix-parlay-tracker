import 'dart:convert';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

class OddsService {
  /// Fetch odds filtered to: today until tomorrow 09:00 only
  static Future<List<OddsMatch>> fetchOdds({bool liveOnly = false}) async {
    final settings = SettingsService.instance;
    final ot = liveOnly ? 't' : 'r';
    final domain = settings.bwbDomain;
    final domains = [domain];
    if (domain != 'letsaiabt365.com') domains.add('letsaiabt365.com');
    if (domain != 'bwbet365.com') domains.add('bwbet365.com');

    for (final d in domains) {
      try {
        final url = 'https://$d/_view/ParGenWFH.ashx?g=2&ot=$ot&wd=&ia=0&update=true';
        final resp = await http.get(Uri.parse(url), headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 13)',
          'Referer': 'https://$d/',
        }).timeout(const Duration(seconds: 15));

        if (resp.statusCode != 200) { if (d == domains.last) continue; else continue; }

        var text = resp.body.trim();
        while (text.startsWith('(')) text = text.substring(1);
        while (text.endsWith(')') || text.endsWith(';')) text = text.substring(0, text.length - 1);
        text = text.replaceAll("'", '"');

        final data = json.decode(text) as List;
        final matchesRoot = data[3] as List;
        final matches = <OddsMatch>[];
        final seen = <String>{};

        for (final league in matchesRoot) {
          if (league is! List) continue;
          String leagueName = 'Unknown';
          for (final item in league) {
            if (item is String && item.length > 3) { leagueName = item; break; }
          }
          for (final sub in league) {
            if (sub is! List) continue;
            for (final m in sub) {
              if (m is! List || m.length < 30) continue;
              try {
                final match = OddsMatch.fromArray(m, leagueName);
                // FILTER: only today until tomorrow 09:00
                if (!_isInBettingWindow(match.time)) continue;
                // FILTER: skip LIVE matches (odds = 0 for 1X2)
                if (match.x12Home == 0 && match.x12Draw == 0 && match.x12Away == 0) continue;
                // FILTER: must have valid O/U or AH odds
                if (match.ouOver == 0 && match.ouUnder == 0 && match.ahHome == 0) continue;
                // DEDUP: 1 match = 1 entry
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
      } catch (e) {
        if (d == domains.last) return [];
        continue;
      }
    }
    return [];
  }

  /// Check if match time is within "today until tomorrow 09:00"
  /// API time format: "DD/MM HH:MM" (e.g. "01/07 01:00")
  static bool _isInBettingWindow(String timeStr) {
    if (timeStr.isEmpty) return false;
    try {
      final parts = timeStr.split(' ');
      if (parts.length != 2) return false;
      final dateParts = parts[0].split('/');
      if (dateParts.length != 2) return false;
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final timeParts = parts[1].split(':');
      if (timeParts.length != 2) return false;
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Convert to comparable value: month*1000000 + day*10000 + hour*100 + minute
      final val = month * 1000000 + day * 10000 + hour * 100 + minute;

      // Today = 29/06, Tomorrow = 30/06, Day after until 09:00 = 01/07 09:00
      // Window: 29/06 00:00 to 01/07 09:00
      const start = 6290000;  // 29/06 00:00
      const end = 7010900;    // 01/07 09:00

      return val >= start && val <= end;
    } catch (_) {
      return false;
    }
  }

  /// Generate parlay picks — NO duplicate teams guaranteed
  static List<ParlayPick> generatePicks(List<OddsMatch> matches, {int maxLegs = 10}) {
    final picks = <ParlayPick>[];
    final usedTeams = <String>{};  // Track individual teams, not just matches!

    final ouPicks = <ParlayPick>[];
    final ahPicks = <ParlayPick>[];
    final x12Picks = <ParlayPick>[];

    for (final m in matches) {
      // Skip if either team already used
      if (usedTeams.contains(m.home) || usedTeams.contains(m.away)) continue;

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

    // Build: 5 O/U + 3 AH + 2 1X2, each from DIFFERENT teams
    for (final p in ouPicks) {
      if (usedTeams.contains(p.match.home) || usedTeams.contains(p.match.away)) continue;
      if (picks.length < 5) {
        picks.add(p);
        usedTeams.add(p.match.home);
        usedTeams.add(p.match.away);
      }
    }
    for (final p in ahPicks) {
      if (usedTeams.contains(p.match.home) || usedTeams.contains(p.match.away)) continue;
      if (picks.length < 8) {
        picks.add(p);
        usedTeams.add(p.match.home);
        usedTeams.add(p.match.away);
      }
    }
    for (final p in x12Picks) {
      if (usedTeams.contains(p.match.home) || usedTeams.contains(p.match.away)) continue;
      if (picks.length < maxLegs) {
        picks.add(p);
        usedTeams.add(p.match.home);
        usedTeams.add(p.match.away);
      }
    }

    return picks;
  }
}

class OddsMatch {
  final String league; final String time; final String home; final String away;
  final double x12Home; final double x12Draw; final double x12Away;
  final double ahLine; final double ahHome; final double ahAway;
  final double ouOver; final double ouUnder;

  OddsMatch({required this.league, required this.time, required this.home, required this.away,
    required this.x12Home, required this.x12Draw, required this.x12Away,
    required this.ahLine, required this.ahHome, required this.ahAway,
    required this.ouOver, required this.ouUnder});

  factory OddsMatch.fromArray(List<dynamic> m, String leagueName) {
    double sd(dynamic v, {double div = 1.0}) {
      if (v == null || v == 0 || v == '') return 0.0;
      return (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0) / div;
    }
    return OddsMatch(
      league: leagueName, time: m.length > 4 ? m[4].toString() : '',
      home: m.length > 6 ? m[6].toString() : '', away: m.length > 7 ? m[7].toString() : '',
      x12Home: sd(m.length > 11 ? m[11] : 0), x12Draw: sd(m.length > 12 ? m[12] : 0), x12Away: sd(m.length > 13 ? m[13] : 0),
      ahLine: sd(m.length > 15 ? m[15] : 0), ahHome: sd(m.length > 17 ? m[17] : 0, div: 10), ahAway: sd(m.length > 18 ? m[18] : 0, div: 10),
      ouOver: sd(m.length > 24 ? m[24] : 0, div: 10), ouUnder: sd(m.length > 25 ? m[25] : 0, div: 10),
    );
  }
}

class ParlayPick {
  final OddsMatch match; final String pick; final double odds; final String market; final String confidence;
  ParlayPick({required this.match, required this.pick, required this.odds, required this.market, required this.confidence});
}

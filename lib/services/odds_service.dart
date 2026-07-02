import 'dart:convert';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

class OddsService {
  static Future<List<OddsMatch>> fetchOdds({String mode = 'tomorrow'}) async {
    final settings = SettingsService.instance;
    switch (mode) {
      case 'today':
        return await _fetchRaw(settings.bwbDomain, 't', filter: _isToday);
      case 'finished':
        return await _fetchRaw(settings.bwbDomain, 'r', filter: _isToday);
      case 'tomorrow':
      default:
        return await _fetchRaw(settings.bwbDomain, 'r', filter: _isTomorrow);
    }
  }

  static Future<List<OddsMatch>> _fetchRaw(String domain, String ot, {bool Function(String)? filter}) async {
    final domains = [domain];
    if (domain != 'letsaiabt365.com') domains.add('letsaiabt365.com');
    if (domain != 'bwbet365.com') domains.add('bwbet365.com');

    for (final d in domains) {
      try {
        final url = 'https://$d/_view/ParGenWFH.ashx?g=2&ot=$ot&wd=&ia=0&update=true&r=';
        final resp = await http.get(Uri.parse(url), headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 13)',
          'Referer': 'https://$d/',
          'Accept': '*/*',
        }).timeout(const Duration(seconds: 15));

        if (resp.statusCode != 200) continue;

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

          if (league.isNotEmpty && league[0] is List) {
            final info = league[0] as List;
            if (info.length > 1 && info[1] is String) {
              leagueName = info[1];
            }
          }

          for (var i = 1; i < league.length; i++) {
            final item = league[i];
            if (item is! List) continue;

            if (item.isNotEmpty && item[0] is List) {
              for (final m in item) {
                if (m is! List || m.length < 30) continue;
                try {
                  final match = OddsMatch.fromArray(m, leagueName);
                  if (filter != null && !filter(match.time)) continue;
                  if (match.x12Home == 0 && match.x12Draw == 0 && match.x12Away == 0) continue;
                  if (match.ouOver == 0 && match.ouUnder == 0 && match.ahHome == 0) continue;
                  final key = '${match.home}_${match.away}';
                  if (!seen.contains(key) && match.home.isNotEmpty && match.away.isNotEmpty) {
                    seen.add(key);
                    matches.add(match);
                  }
                } catch (_) {}
              }
            } else if (item.length >= 30) {
              try {
                final match = OddsMatch.fromArray(item, leagueName);
                if (filter != null && !filter(match.time)) continue;
                if (match.x12Home == 0 && match.x12Draw == 0 && match.x12Away == 0) continue;
                if (match.ouOver == 0 && match.ouUnder == 0 && match.ahHome == 0) continue;
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

  static bool _parseTime(String timeStr) {
    if (timeStr.isEmpty) return false;
    try {
      final parts = timeStr.split(' ');
      if (parts.length != 2) return false;
      final dateParts = parts[0].split('/');
      if (dateParts.length != 2) return false;
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final now = DateTime.now();
      final matchDate = DateTime(now.year, month, day);
      final diff = matchDate.difference(DateTime(now.year, now.month, now.day)).inDays;
      return diff == 0;
    } catch (_) {
      return false;
    }
  }

  static bool _isTimeOnlyToday(String timeStr) {
    if (timeStr.isEmpty) return false;
    final trimmed = timeStr.trim();
    if (trimmed.contains('/')) return false;
    final parts = trimmed.split(':');
    if (parts.length != 2) return false;
    final now = DateTime.now();
    final matchMinutes = int.tryParse(parts[0]) * 60 + int.tryParse(parts[1]);
    if (matchMinutes == null) return false;
    final startMinutes = 0;
    final endMinutes = 24 * 60;
    return matchMinutes >= startMinutes && matchMinutes <= endMinutes;
  }

  static bool _isToday(String timeStr) {
    if (_parseTime(timeStr)) return true;
    return _isTimeOnlyToday(timeStr);
  }

  static bool _isTomorrow(String timeStr) {
    if (timeStr.isEmpty) return false;
    try {
      final parts = timeStr.split(' ');
      if (parts.length != 2) return false;
      final dateParts = parts[0].split('/');
      if (dateParts.length != 2) return false;
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final now = DateTime.now();
      final matchDate = DateTime(now.year, month, day);
      final diff = matchDate.difference(DateTime(now.year, now.month, now.day)).inDays;
      return diff == 1;
    } catch (_) {
      return false;
    }
  }

  static List<ParlayPick> generatePicks(List<OddsMatch> matches, {int maxLegs = 10}) {
    final picks = <ParlayPick>[];
    final usedTeams = <String>{};

    final ouPicks = <ParlayPick>[];
    final ahPicks = <ParlayPick>[];
    final x12Picks = <ParlayPick>[];

    for (final m in matches) {
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

    for (final p in ouPicks) {
      if (usedTeams.contains(p.match.home) || usedTeams.contains(p.match.away)) continue;
      if (picks.length < 5) { picks.add(p); usedTeams.add(p.match.home); usedTeams.add(p.match.away); }
    }
    for (final p in ahPicks) {
      if (usedTeams.contains(p.match.home) || usedTeams.contains(p.match.away)) continue;
      if (picks.length < 8) { picks.add(p); usedTeams.add(p.match.home); usedTeams.add(p.match.away); }
    }
    for (final p in x12Picks) {
      if (usedTeams.contains(p.match.home) || usedTeams.contains(p.match.away)) continue;
      if (picks.length < maxLegs) { picks.add(p); usedTeams.add(p.match.home); usedTeams.add(p.match.away); }
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

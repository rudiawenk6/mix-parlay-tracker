import 'dart:convert';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

part 'odds_trimmer.dart';

class OddsService {
  static Future<List<OddsMatch>> fetchOdds({bool liveOnly = false}) async {
    final settings = SettingsService.instance;
    final ot = liveOnly ? 't' : 'r';

    if (liveOnly) {
      // BRUTE: get everything from letsaiabt365 and prune AFTER parse
      final matches = await _fetchRaw(settings.bwbDomain, 'r');
      final seen = <String>{};
      final out = <OddsMatch>[];
      for (final m in matches) {
        final key = '${m.home}_${m.away}';
        if (key.isEmpty) continue;
        if (seen.contains(key)) continue;
        if (!_isToday(m.time)) continue;
        seen.add(key);
        out.add(m);
      }
      return out;
    }

    return await _fetchRaw(settings.bwbDomain, 'r');
  }

  static Future<List<OddsMatch>> _fetchRaw(String domain, String ot) async {
    final domains = [domain];
    if (domain != 'letsaiabt365.com') domains.add('letsaiabt365.com');
    if (domain != 'bwbet365.com') domains.add('bwbet365.com');

    for (final d in domains) {
      try {
        final url = 'https://$d/_view/ParGenWFH.ashx?g=2&ot=$ot&wd=&ia=0&update=true';
        final resp = await http.get(Uri.parse(url), headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 13)',
          'Referer': 'https://$d/',
          'Accept': '*/*',
        }).timeout(const Duration(seconds: 30));

        if (resp.statusCode != 200) {
          if (d == domains.last) return [];
          continue;
        }

        var text = resp.body.trim();
        while (text.startsWith('(')) text = text.substring(1);
        while (text.endsWith(')') || text.endsWith(';')) text = text.substring(0, text.length - 1);
        text = text.replaceAll("'", '"');

        late final List data;
        try {
          data = json.decode(text) as List;
        } on FormatException catch (e) {
          if (d == domains.last) return [];
          continue;
        }

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
                  if (match.x12Home == 0 && match.x12Draw == 0 && match.x12Away == 0) continue;
                  if (match.ouOver == 0 && match.ouUnder == 0 && match.ahHome == 0) continue;
                  final key = '${match.home}_${match.away}';
                  if (!seen.contains(key) && match.home.isNotEmpty && match.away.isNotEmpty) {
                    seen.add(key);
                    matches.add(_trimMatchTime(match));
                  }
                } catch (_) {}
              }
            } else if (item.length >= 30) {
              try {
                final match = OddsMatch.fromArray(item, leagueName);
                if (match.x12Home == 0 && match.x12Draw == 0 && match.x12Away == 0) continue;
                if (match.ouOver == 0 && match.ouUnder == 0 && match.ahHome == 0) continue;
                final key = '${match.home}_${match.away}';
                if (!seen.contains(key) && match.home.isNotEmpty && match.away.isNotEmpty) {
                  seen.add(key);
                  matches.add(_trimMatchTime(match));
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/odds_service.dart';
import '../services/ai_service.dart';
import '../services/telegram_service.dart';
import '../services/settings_service.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  List<OddsMatch> _matches = [];
  List<ParlayPick> _picks = [];
  bool _loading = false;
  String _aiAnalysis = '';
  String _status = '';
  int _targetLegs = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate (Today→Tomorrow 9am)'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchOdds),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Legs:'),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _targetLegs,
                        items: [5,6,7,8,9,10].map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                        onChanged: (v) => setState(() => _targetLegs = v ?? 10),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _loading ? null : _fetchOdds,
                        icon: _loading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.download),
                        label: const Text('Fetch Odds'),
                      ),
                    ],
                  ),
                  if (_status.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_status, style: TextStyle(
                      fontSize: 12,
                      color: _status.contains('Error') || _status.contains('No matches') ? Colors.red : Colors.grey,
                    )),
                  ],
                  const SizedBox(height: 4),
                  Text('Domain: ${SettingsService.instance.bwbDomain}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_matches.isNotEmpty) ...[
            Text('${_matches.length} matches found', style: const TextStyle(fontSize: 12, color: Colors.green)),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _generatePicks,
              icon: const Icon(Icons.auto_fix_high),
              label: Text('Generate $_targetLegs Team Parlay'),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              title: Text('Available Matches (${_matches.length})', style: const TextStyle(fontSize: 13)),
              children: _matches.take(20).map((m) => ListTile(
                dense: true,
                title: Text('${m.home} vs ${m.away}', style: const TextStyle(fontSize: 12)),
                subtitle: Text('${m.league} | O/U:${m.ouOver}/${m.ouUnder} AH:${m.ahHome}(${m.ahLine})', style: const TextStyle(fontSize: 10)),
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],

          if (_picks.isNotEmpty) ...[
            Card(
              color: Colors.green.shade900,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text('${_picks.length} LEG PARLAY', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Total Odds: ${_totalOdds().toStringAsFixed(1)}x | Stake 55 → Payout: ${(_totalOdds() * 55).toStringAsFixed(0)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ..._picks.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              final emoji = p.market == 'O/U'
                  ? (p.pick.contains('Over') ? '⬆️' : '⬇️')
                  : p.market == 'AH' ? '🇭🇰' : '1️⃣';
              final confColor = p.confidence == 'HIGH' ? Colors.green : p.confidence == 'MED' ? Colors.orange : Colors.grey;

              return Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  dense: true,
                  leading: Text('#${i + 1}', style: const TextStyle(fontSize: 12)),
                  title: Text('${p.match.home} vs ${p.match.away}'),
                  subtitle: Text('${p.match.league} | $emoji ${p.pick} @ ${p.odds}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: confColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                    child: Text(p.confidence, style: TextStyle(color: confColor, fontSize: 10)),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _sendTelegram,
                    icon: const Icon(Icons.send),
                    label: const Text('Telegram'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _analyzeAI,
                    icon: const Icon(Icons.psychology),
                    label: const Text('AI Review'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_aiAnalysis.isNotEmpty) ...[
              const Text('AI ANALYSIS', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(_aiAnalysis, style: const TextStyle(fontSize: 13)))),
            ],
          ],

          if (!_loading && _matches.isEmpty && _picks.isEmpty) ...[
            const SizedBox(height: 40),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Tap "Fetch Odds" to load matches', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Make sure domain is set in Settings', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _windowLabel() {
    final now = DateTime.now();
    final today = DateFormat('dd/MM').format(now);
    final tomorrow = DateFormat('dd/MM').format(DateTime(now.year, now.month, now.day + 1));
    return 'Window: $today 00:00 → $tomorrow 09:00';
  }

  double _totalOdds() {
    double r = 1.0;
    for (final p in _picks) r *= p.odds;
    return r;
  }

  Future<void> _fetchOdds() async {
    setState(() { _loading = true; _status = 'Fetching from ${SettingsService.instance.bwbDomain}...'; });

    try {
      final matches = await OddsService.fetchOdds();
      if (!mounted) return;
      setState(() {
        _matches = matches;
        _loading = false;
        if (matches.isEmpty) {
          _status = 'No matches for TODAY→TOMORROW 09:00.\n${_windowLabel()}\nTry different domain in Settings.';
        } else {
          _status = '${matches.length} matches (today→tomorrow 9am). Tap Generate!';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _status = 'Error: $e\nCheck domain in Settings and network connection.';
      });
    }
  }

  void _generatePicks() {
    final picks = OddsService.generatePicks(_matches, maxLegs: _targetLegs);
    setState(() {
      _picks = picks;
      _aiAnalysis = '';
      if (picks.isEmpty) {
        _status = 'No safe picks found. Matches may not have valid odds (O/U or AH).';
      } else if (picks.length < _targetLegs) {
        _status = 'Only ${picks.length} legs generated (not enough safe picks). Consider different strategy.';
      } else {
        _status = '${picks.length} legs generated! Total odds: ${_totalOdds().toStringAsFixed(1)}x';
      }
    });
  }

  Future<void> _sendTelegram() async {
    final legs = _picks.map((p) => <String, dynamic>{
      'match': '${p.match.home} vs ${p.match.away}',
      'league': p.match.league,
      'time': p.match.time,
      'pick': p.pick,
      'odds': p.odds,
      'market': p.market,
    }).toList();

    final ok = await TelegramService.sendParlay(legs);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Sent to Telegram!' : 'Failed. Set token in Settings.'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _analyzeAI() async {
    if (!SettingsService.instance.hasOpenRouterKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set OpenRouter key in Settings first'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _aiAnalysis = 'Analyzing...');

    final info = StringBuffer();
    info.writeln('Parlay ${_picks.length} team:');
    for (var i = 0; i < _picks.length; i++) {
      final p = _picks[i];
      info.writeln('#${i+1} ${p.match.home} vs ${p.match.away} | ${p.match.league} | ${p.pick} @ ${p.odds}');
    }
    info.writeln('Total odds: ${_totalOdds().toStringAsFixed(1)}x');
    info.writeln('Strategy: ${SettingsService.instance.parlayStrategy}');
    info.writeln('\nAnalyze: Which picks are risky? Any improvements?');

    final analysis = await AiService.analyzeParlay(info.toString());
    if (!mounted) return;
    setState(() => _aiAnalysis = analysis);
  }
}

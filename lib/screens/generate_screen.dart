import 'package:flutter/material.dart';
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
  String _error = '';
  int _targetLegs = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Parlay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOdds,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Controls
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Target Legs:'),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _targetLegs,
                        items: [5, 6, 7, 8, 9, 10]
                            .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                            .toList(),
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
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_error, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Available matches
          if (_matches.isNotEmpty) ...[
            Text('Available: ${_matches.length} matches', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _generatePicks,
              icon: const Icon(Icons.auto_fix_high),
              label: Text('Generate $_targetLegs Team Parlay'),
            ),
            const SizedBox(height: 16),
          ],

          // Generated picks
          if (_picks.isNotEmpty) ...[
            Card(
              color: Colors.green.shade900,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text('${_picks.length} LEG PARLAY', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Total Odds: ${_totalOdds().toStringAsFixed(1)}x | Payout: ${(_totalOdds() * 55).toStringAsFixed(0)}'),
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
              final confColor = p.confidence == 'HIGH'
                  ? Colors.green
                  : p.confidence == 'MED'
                      ? Colors.orange
                      : Colors.grey;

              return Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  dense: true,
                  leading: Text('#${i + 1}', style: const TextStyle(fontSize: 12)),
                  title: Text('${p.match.home} vs ${p.match.away}'),
                  subtitle: Text('${p.match.league} | $emoji ${p.pick} @ ${p.odds}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: confColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(p.confidence, style: TextStyle(color: confColor, fontSize: 10)),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // Action buttons
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

            // AI Analysis result
            if (_aiAnalysis.isNotEmpty) ...[
              const Text('AI ANALYSIS', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_aiAnalysis, style: const TextStyle(fontSize: 13)),
                ),
              ),
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
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _totalOdds() {
    double result = 1.0;
    for (final p in _picks) {
      result *= p.odds;
    }
    return result;
  }

  Future<void> _fetchOdds() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final matches = await OddsService.fetchOdds();
      setState(() {
        _matches = matches;
        _loading = false;
        if (matches.isEmpty) _error = 'No matches found. Check domain in Settings.';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Error: $e';
      });
    }
  }

  void _generatePicks() {
    final picks = OddsService.generatePicks(_matches, maxLegs: _targetLegs);
    setState(() {
      _picks = picks;
      _aiAnalysis = '';
    });
  }

  Future<void> _sendTelegram() async {
    final legs = _picks.map((p) => {
      'match': '${p.match.home} vs ${p.match.away}',
      'league': p.match.league,
      'time': p.match.time,
      'pick': p.pick,
      'odds': p.odds,
      'market': p.market,
    }).toList();

    final ok = await TelegramService.sendParlay(legs);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Sent to Telegram!' : 'Failed. Check token in Settings.'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _analyzeAI() async {
    if (!SettingsService.instance.hasOpenRouterKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set OpenRouter API key in Settings first'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _aiAnalysis = 'Analyzing...');

    final parlayInfo = StringBuffer();
    parlayInfo.writeln('Parlay ${_picks.length} team:');
    for (var i = 0; i < _picks.length; i++) {
      final p = _picks[i];
      parlayInfo.writeln('#${i + 1} ${p.match.home} vs ${p.match.away} | ${p.match.league} | ${p.pick} @ ${p.odds}');
    }
    parlayInfo.writeln('Total odds: ${_totalOdds().toStringAsFixed(1)}x');
    parlayInfo.writeln('Strategy: ${SettingsService.instance.parlayStrategy}');
    parlayInfo.writeln('\nAnalyze: Which picks are risky? Any improvements?');

    final analysis = await AiService.analyzeParlay(parlayInfo.toString());
    setState(() => _aiAnalysis = analysis);
  }
}

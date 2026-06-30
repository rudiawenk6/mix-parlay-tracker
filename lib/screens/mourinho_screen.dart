import 'package:flutter/material.dart';
import '../services/odds_service.dart';
import '../services/ai_service.dart';
import '../services/telegram_service.dart';
import '../services/settings_service.dart';

class MourinhoScreen extends StatefulWidget {
  const MourinhoScreen({super.key});

  @override
  State<MourinhoScreen> createState() => _MourinhoScreenState();
}

class _MourinhoScreenState extends State<MourinhoScreen> {
  List<OddsMatch> _matches = [];
  bool _loading = false;
  String _status = '';
  String _analysis = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔴⚪ Cik Edi Analysis'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAndAnalyze),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.red.shade900,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Text('MOURINHO MODE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text('"The team that concedes less wins"', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _loading ? null : _fetchAndAnalyze,
                    icon: _loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.analytics),
                    label: Text(_loading ? 'Analyzing...' : 'ANALYZE ALL MATCHES'),
                  ),
                  if (_status.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_status, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_matches.isNotEmpty) ...[
            Text('${_matches.length} matches found', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            ..._matches.map((m) => _matchCard(m)),
          ],

          if (_analysis.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('AI TACTICAL ANALYSIS', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(_analysis, style: const TextStyle(fontSize: 13)))),
          ],

          if (!_loading && _matches.isEmpty) ...[
            const SizedBox(height: 40),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Tap "ANALYZE ALL MATCHES" to start', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _matchCard(OddsMatch m) {
    // Simple confidence based on odds
    double confidence = 50;
    String pick = 'Under 2.5';
    double pickOdds = m.ouUnder;
    
    if (m.x12Home > 1.3 && m.x12Home < 2.0) {
      confidence = 65 + ((2.0 - m.x12Home) * 20);
      pick = '1X2 Home';
      pickOdds = m.x12Home;
    }
    if (m.ouUnder >= 1.7 && m.ouUnder <= 2.0) {
      confidence = confidence + 5;
    }
    if (m.ahHome >= 1.7 && m.ahHome <= 2.0 && m.ahLine.abs() <= 0.5) {
      confidence = confidence + 8;
      pick = 'AH Home ${m.ahLine}';
      pickOdds = m.ahHome;
    }
    confidence = confidence.clamp(0, 95);

    final confColor = confidence > 75 ? Colors.green : confidence > 60 ? Colors.orange : Colors.red;
    final emoji = confidence > 75 ? '🔥' : confidence > 60 ? '⚡' : '🤔';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Expanded(child: Text('${m.home} vs ${m.away}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: confColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                  child: Text('${confidence.toStringAsFixed(0)}%', style: TextStyle(color: confColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${m.league} | ⏰ ${m.time}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Text('🎯 $pick @ $pickOdds', style: TextStyle(color: confColor, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text('1X2: ${m.x12Home}/${m.x12Draw}/${m.x12Away} | O/U: ${m.ouOver}/${m.ouUnder} | AH: ${m.ahHome}(${m.ahLine})', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchAndAnalyze() async {
    setState(() { _loading = true; _status = 'Fetching all matches...'; _analysis = ''; });

    try {
      final matches = await OddsService.fetchOdds();
      setState(() {
        _matches = matches;
        _loading = false;
        _status = '${matches.length} matches. Analyzing tactics...';
      });

      // AI Analysis
      if (SettingsService.instance.hasOpenRouterKey && matches.isNotEmpty) {
        final info = StringBuffer();
        info.writeln('Analyze these football matches as Mourinho:');
        for (final m in matches.take(15)) {
          info.writeln('${m.home} vs ${m.away} | ${m.league} | ${m.time} | 1X2:${m.x12Home}/${m.x12Draw}/${m.x12Away} | O/U:${m.ouOver}/${m.ouUnder} | AH:${m.ahHome}(${m.ahLine})');
        }
        info.writeln('\nFor each match: give pick, odds, confidence %, tactical reason. Format: TEAM vs TEAM → PICK @ ODDS (CONFIDENCE%) - REASON');

        final analysis = await AiService.analyzeParlay(info.toString());
        setState(() { _analysis = analysis; _status = 'Analysis complete!'; });
      } else {
        setState(() { _status = 'Set OpenRouter key in Settings for AI analysis'; });
      }
    } catch (e) {
      setState(() { _loading = false; _status = 'Error: $e'; });
    }
  }
}

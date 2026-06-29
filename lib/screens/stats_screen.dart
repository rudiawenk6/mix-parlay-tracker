import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/parlay_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ParlayProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Statistics')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Parlay Stats
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PARLAY STATS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _statRow('Total Parlays', '${provider.parlays.length}'),
                      _statRow('Wins', '${provider.totalWins}', color: Colors.green),
                      _statRow('Losses', '${provider.totalLoses}', color: Colors.red),
                      _statRow('Win Rate', '${(provider.winRate * 100).toStringAsFixed(1)}%'),
                      _statRow('Active', '${provider.activeParlays.length}', color: Colors.orange),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Leg Stats
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('LEG STATS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _statRow('Total Legs', '${provider.totalLegs}'),
                      _statRow('Leg Wins', '${provider.totalLegWins}', color: Colors.green),
                      _statRow('Leg Losses', '${provider.totalLegLoses}', color: Colors.red),
                      _statRow('Leg Win Rate', '${(provider.legWinRate * 100).toStringAsFixed(1)}%'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: provider.legWinRate,
                        backgroundColor: Colors.grey.shade800,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Market Breakdown
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MARKET BREAKDOWN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (provider.marketTotals.isEmpty)
                        const Text('No data yet', style: TextStyle(color: Colors.grey))
                      else
                        ...provider.marketTotals.entries.map((e) {
                          final wins = provider.marketWins[e.key] ?? 0;
                          final rate = wins / e.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('$wins/${e.value} (${(rate * 100).toStringAsFixed(0)}%)',
                                        style: TextStyle(color: rate > 0.5 ? Colors.green : Colors.red)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: rate,
                                  backgroundColor: Colors.grey.shade800,
                                  color: rate > 0.5 ? Colors.green : Colors.red,
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Bankroll
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BANKROLL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _statRow('Current', 'Rp ${provider.bankroll.round()}'),
                      _statRow('Total P/L', '${provider.totalProfit >= 0 ? "+" : ""}Rp ${provider.totalProfit.round()}',
                          color: provider.totalProfit >= 0 ? Colors.green : Colors.red),
                      _statRow('ROI', '${provider.parlays.isEmpty ? 0 : ((provider.totalProfit / (provider.parlays.fold(0.0, (s, p) => s + p.stake))) * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

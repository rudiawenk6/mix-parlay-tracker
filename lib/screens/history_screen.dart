import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/parlay_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ParlayProvider>(
      builder: (context, provider, _) {
        final parlays = provider.parlays;
        final fmt = NumberFormat.decimalPattern('id');

        return Scaffold(
          appBar: AppBar(title: const Text('History')),
          body: parlays.isEmpty
              ? const Center(child: Text('No parlays yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: parlays.length,
                  itemBuilder: (context, i) {
                    final p = parlays[i];
                    final statusColor = p.overallStatus == 'WIN'
                        ? Colors.green
                        : p.overallStatus == 'LOSE'
                            ? Colors.red
                            : Colors.orange;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  DateFormat('dd/MM HH:mm').format(p.date),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    p.overallStatus,
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${p.legs.length} Leg | Stake: ${fmt.format(p.stake.round())} | Odds: ${p.totalOdds.toStringAsFixed(1)}x',
                            ),
                            Text(
                              'Payout: ${fmt.format(p.estimatedPayout.round())} | P/L: ${p.profit >= 0 ? "+" : ""}${fmt.format(p.profit.round())}',
                              style: TextStyle(
                                color: p.profit >= 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Leg summary
                            Wrap(
                              spacing: 4,
                              children: p.legs.asMap().entries.map((e) {
                                final leg = e.value;
                                final c = leg.status == 'win'
                                    ? Colors.green
                                    : leg.status == 'lose'
                                        ? Colors.red
                                        : leg.status == 'pending'
                                            ? Colors.grey
                                            : Colors.orange;
                                return Chip(
                                  label: Text('#${e.key + 1}', style: TextStyle(fontSize: 10, color: c)),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                            ),
                            if (p.note.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(p.note, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

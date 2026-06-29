import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/parlay_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ParlayProvider>(
      builder: (context, provider, _) {
        final fmt = NumberFormat.decimalPattern('id');

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mix Parlay Tracker'),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_balance_wallet),
                onPressed: () => _showBankrollDialog(context, provider),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {},
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Bankroll Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('BANKROLL', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          'Rp ${fmt.format(provider.bankroll.round())}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _statChip('W', provider.totalWins, Colors.green),
                            _statChip('L', provider.totalLoses, Colors.red),
                            _statChip('Rate', '${(provider.winRate * 100).toStringAsFixed(1)}%', Colors.blue),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Profit Card
                Card(
                  color: provider.totalProfit >= 0
                      ? Colors.green.shade900
                      : Colors.red.shade900,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total P/L', style: TextStyle(fontSize: 16)),
                        Text(
                          '${provider.totalProfit >= 0 ? "+" : ""}Rp ${fmt.format(provider.totalProfit.round())}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Leg Stats
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('LEG STATS', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: Text('Leg Win Rate: ${(provider.legWinRate * 100).toStringAsFixed(1)}%')),
                            Expanded(child: Text('${provider.totalLegWins}W / ${provider.totalLegLoses}L / ${provider.totalLegs} total')),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: provider.legWinRate,
                          backgroundColor: Colors.red.shade200,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Active Parlays
                const Text('ACTIVE PARLAYS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (provider.activeParlays.isEmpty)
                  const Card(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No active parlays. Tap + to add!', style: TextStyle(color: Colors.grey)),
                  ))
                else
                  ...provider.activeParlays.map((p) => _parlayCard(context, p, provider)),

                const SizedBox(height: 16),

                // Recent Completed
                if (provider.completedParlays.isNotEmpty) ...[
                  const Text('RECENT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...provider.completedParlays.take(5).map((p) => _parlayCard(context, p, provider)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statChip(String label, dynamic value, Color color) {
    return Column(
      children: [
        Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _parlayCard(BuildContext context, parlay, ParlayProvider provider) {
    final fmt = NumberFormat.decimalPattern('id');
    final statusColor = parlay.overallStatus == 'WIN'
        ? Colors.green
        : parlay.overallStatus == 'LOSE'
            ? Colors.red
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text('${parlay.legs.length} Leg @ ${fmt.format(parlay.stake.round())}'),
            const Spacer(),
            Text(
              parlay.overallStatus,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        subtitle: Text(
          '${parlay.winCount}W ${parlay.loseCount}L ${parlay.pushCount}D ${parlay.pendingCount}P | Odds: ${parlay.totalOdds.toStringAsFixed(1)}x',
        ),
        children: parlay.legs.asMap().entries.map((e) {
          final i = e.key;
          final leg = e.value;
          final legColor = leg.status == 'win'
              ? Colors.green
              : leg.status == 'lose'
                  ? Colors.red
                  : leg.status == 'pending'
                      ? Colors.grey
                      : Colors.orange;

          return ListTile(
            dense: true,
            leading: Text('#${i + 1}', style: const TextStyle(fontSize: 12)),
            title: Text(
              '${leg.homeTeam} vs ${leg.awayTeam}',
              style: const TextStyle(fontSize: 13),
            ),
            subtitle: Text(
              '${leg.league} | ${leg.pick} @ ${leg.odds}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: leg.status == 'pending'
                ? IconButton(
                    icon: const Icon(Icons.edit, size: 16),
                    onPressed: () => _showResultDialog(context, provider, parlay.id, i),
                  )
                : Text(
                    '${leg.homeScore}-${leg.awayScore}',
                    style: TextStyle(color: legColor, fontWeight: FontWeight.bold),
                  ),
          );
        }).toList(),
      ),
    );
  }

  void _showBankrollDialog(BuildContext context, ParlayProvider provider) {
    final ctrl = TextEditingController(text: provider.bankroll.round().toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Set Bankroll'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.setBankroll(double.parse(ctrl.text));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(BuildContext context, ParlayProvider provider, String parlayId, int legIndex) {
    final hsCtrl = TextEditingController();
    final asCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update Score'),
        content: Row(
          children: [
            Expanded(child: TextField(controller: hsCtrl, decoration: const InputDecoration(labelText: 'Home'), keyboardType: TextInputType.number)),
            const Text(' - '),
            Expanded(child: TextField(controller: asCtrl, decoration: const InputDecoration(labelText: 'Away'), keyboardType: TextInputType.number)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.updateLegResult(parlayId, legIndex, int.parse(hsCtrl.text), int.parse(asCtrl.text));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

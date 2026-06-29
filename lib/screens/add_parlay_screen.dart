import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/parlay.dart';
import '../models/parlay_leg.dart';
import '../providers/parlay_provider.dart';

class AddParlayScreen extends StatefulWidget {
  const AddParlayScreen({super.key});

  @override
  State<AddParlayScreen> createState() => _AddParlayScreenState();
}

class _AddParlayScreenState extends State<AddParlayScreen> {
  final List<ParlayLeg> _legs = [];
  final _stakeCtrl = TextEditingController(text: '55');
  final _noteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Leg input controllers
  final _leagueCtrl = TextEditingController();
  final _homeCtrl = TextEditingController();
  final _awayCtrl = TextEditingController();
  final _oddsCtrl = TextEditingController();
  final _hcpCtrl = TextEditingController();
  final _lineCtrl = TextEditingController();
  String _market = '1X2';
  String _pick = 'Home';

  void _addLeg() {
    if (_homeCtrl.text.isEmpty || _awayCtrl.text.isEmpty) return;
    _legs.add(ParlayLeg(
      league: _leagueCtrl.text,
      homeTeam: _homeCtrl.text,
      awayTeam: _awayCtrl.text,
      market: _market,
      pick: _pick,
      odds: double.tryParse(_oddsCtrl.text) ?? 1.9,
      handicap: double.tryParse(_hcpCtrl.text),
      line: double.tryParse(_lineCtrl.text),
    ));
    _leagueCtrl.clear();
    _homeCtrl.clear();
    _awayCtrl.clear();
    _oddsCtrl.text = '1.9';
    _hcpCtrl.clear();
    _lineCtrl.clear();
    setState(() {});
  }

  void _saveParlay() {
    if (_legs.isEmpty) return;
    final provider = context.read<ParlayProvider>();
    provider.addParlay(Parlay(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      legs: _legs,
      stake: double.tryParse(_stakeCtrl.text) ?? 55,
      note: _noteCtrl.text,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Parlay')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stake
            Row(
              children: [
                const Text('Stake: '),
                Expanded(
                  child: TextFormField(
                    controller: _stakeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true, suffix: Text('Rp')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const Text('ADD LEG', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Market selector
            DropdownButtonFormField<String>(
              value: _market,
              items: ['1X2', 'AH', 'O/U', 'Odd/Even']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _market = v!;
                  _pick = v == '1X2'
                      ? 'Home'
                      : v == 'AH'
                          ? 'Home'
                          : v == 'O/U'
                              ? 'Over'
                              : 'Even';
                });
              },
              decoration: const InputDecoration(labelText: 'Market'),
            ),
            const SizedBox(height: 8),

            // Pick selector
            DropdownButtonFormField<String>(
              value: _pick,
              items: _pickOptions()
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _pick = v!),
              decoration: const InputDecoration(labelText: 'Pick'),
            ),
            const SizedBox(height: 8),

            TextFormField(controller: _leagueCtrl, decoration: const InputDecoration(labelText: 'League')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _homeCtrl, decoration: const InputDecoration(labelText: 'Home'))),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _awayCtrl, decoration: const InputDecoration(labelText: 'Away'))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _oddsCtrl, decoration: const InputDecoration(labelText: 'Odds'), keyboardType: TextInputType.number)),
                if (_market == 'AH')
                  Expanded(child: TextFormField(controller: _hcpCtrl, decoration: const InputDecoration(labelText: 'Handicap'), keyboardType: TextInputType.number)),
                if (_market == 'O/U')
                  Expanded(child: TextFormField(controller: _lineCtrl, decoration: const InputDecoration(labelText: 'Line'), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addLeg,
              icon: const Icon(Icons.add),
              label: Text('Add Leg (${_legs.length}/10)'),
            ),
            const SizedBox(height: 16),

            // Legs list
            if (_legs.isNotEmpty) ...[
              const Divider(),
              Text('LEGS (${_legs.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._legs.asMap().entries.map((e) {
                final i = e.key;
                final leg = e.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
                    title: Text('${leg.homeTeam} vs ${leg.awayTeam}'),
                    subtitle: Text('${leg.pick} @ ${leg.odds} | ${leg.market}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      onPressed: () => setState(() => _legs.removeAt(i)),
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 16),
            TextFormField(controller: _noteCtrl, decoration: const InputDecoration(labelText: 'Note (optional)')),
            const SizedBox(height: 24),

            // Save button
            FilledButton.icon(
              onPressed: _legs.isEmpty ? null : _saveParlay,
              icon: const Icon(Icons.save),
              label: Text('Save Parlay (${_legs.length} legs)'),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _pickOptions() {
    switch (_market) {
      case '1X2':
        return ['Home', 'Draw', 'Away'];
      case 'AH':
        return ['Home', 'Away'];
      case 'O/U':
        return ['Over', 'Under'];
      case 'Odd/Even':
        return ['Even', 'Odd'];
      default:
        return ['Home'];
    }
  }
}

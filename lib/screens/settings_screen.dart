import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/crypto_service.dart';
import '../services/ai_models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService.instance;
  bool _showORKey = false;
  bool _showTGToken = false;

  // Controllers
  final _orKeyCtrl = TextEditingController();
  final _tgTokenCtrl = TextEditingController();
  final _tgChatCtrl = TextEditingController();
  final _domainCtrl = TextEditingController();
  final _bankrollCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadControllers();
  }

  void _loadControllers() {
    _orKeyCtrl.text = _settings.openRouterKey;
    _tgTokenCtrl.text = _settings.telegramToken;
    _tgChatCtrl.text = _settings.telegramChatId;
    _domainCtrl.text = _settings.bwbDomain;
    _bankrollCtrl.text = _settings.bankroll.round().toString();
  }

  Future<void> _saveAll() async {
    final errors = <String>[];

    // Save OpenRouter key (validate if not empty)
    if (_orKeyCtrl.text.isNotEmpty && !CryptoService.isValidOpenRouterKey(_orKeyCtrl.text)) {
      errors.add('OpenRouter key format invalid (must start with sk-or-)');
    } else if (_orKeyCtrl.text.isNotEmpty) {
      await _settings.saveOpenRouterKey(_orKeyCtrl.text);
    }

    // Save Telegram token (validate if not empty)
    if (_tgTokenCtrl.text.isNotEmpty && !CryptoService.isValidTelegramToken(_tgTokenCtrl.text)) {
      errors.add('Telegram token format invalid (format: 123456:AAF...)');
    } else if (_tgTokenCtrl.text.isNotEmpty) {
      await _settings.saveTelegramToken(_tgTokenCtrl.text);
    }

    // Save chat ID
    if (_tgChatCtrl.text.isNotEmpty) {
      await _settings.saveTelegramChatId(_tgChatCtrl.text);
    }

    // Save domain (validate)
    if (_domainCtrl.text.isNotEmpty) {
      if (!CryptoService.isValidDomain(_domainCtrl.text)) {
        errors.add('Domain format invalid');
      } else {
        await _settings.saveBwbDomain(_domainCtrl.text);
      }
    }

    // Save bankroll
    if (_bankrollCtrl.text.isNotEmpty) {
      await _settings.saveBankroll(double.tryParse(_bankrollCtrl.text) ?? 7500000);
    }

    if (mounted) {
      if (errors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved! (sensitive data encrypted)'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errors.join('\n')), backgroundColor: Colors.red),
        );
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _saveAll,
              icon: const Icon(Icons.save),
              label: const Text('SAVE'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SECURITY NOTICE
          Card(
            color: Colors.green.shade900,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.greenAccent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'API keys & tokens are AES-256 encrypted before storage',
                      style: TextStyle(fontSize: 12, color: Colors.greenAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // OPENROUTER API KEY
          _sectionHeader('AI Analysis (OpenRouter)'),
          Row(
            children: [
              Expanded(child: Text('API Key', style: const TextStyle(fontWeight: FontWeight.w500))),
              IconButton(
                icon: Icon(_showORKey ? Icons.visibility_off : Icons.visibility, size: 18),
                onPressed: () => setState(() => _showORKey = !_showORKey),
              ),
            ],
          ),
          TextField(
            controller: _orKeyCtrl,
            obscureText: !_showORKey,
            decoration: InputDecoration(
              hintText: 'sk-or-v1-xxxxxxxxxxxx',
              suffixIcon: _settings.hasOpenRouterKey ? const Icon(Icons.lock, size: 16) : null,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_settings.hasOpenRouterKey)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Current: ${_settings.openRouterKeyMasked} (encrypted)', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ),
          const SizedBox(height: 20),

          // TELEGRAM
          _sectionHeader('Telegram Bot'),
          Row(
            children: [
              Expanded(child: Text('Bot Token', style: const TextStyle(fontWeight: FontWeight.w500))),
              IconButton(
                icon: Icon(_showTGToken ? Icons.visibility_off : Icons.visibility, size: 18),
                onPressed: () => setState(() => _showTGToken = !_showTGToken),
              ),
            ],
          ),
          TextField(
            controller: _tgTokenCtrl,
            obscureText: !_showTGToken,
            decoration: InputDecoration(
              hintText: '123456789:AAF8QD8h6Uei...',
              suffixIcon: _settings.hasTelegramToken ? const Icon(Icons.lock, size: 16) : null,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_settings.hasTelegramToken)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Current: ${_settings.telegramTokenMasked} (encrypted)', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _tgChatCtrl,
            decoration: const InputDecoration(
              labelText: 'Chat ID',
              hintText: '-1003943817890',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // ODDS DOMAIN
          _sectionHeader('Odds API Domain'),
          TextField(
            controller: _domainCtrl,
            decoration: const InputDecoration(
              labelText: 'Domain',
              hintText: 'letsaiabt365.com',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 4),
          Text('URL: https://${_domainCtrl.text}/_view/ParGenWFH.ashx',
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('letsaiabt365.com'),
                onPressed: () { _domainCtrl.text = 'letsaiabt365.com'; setState(() {}); },
              ),
              ActionChip(
                label: const Text('bwb365liga.com'),
                onPressed: () { _domainCtrl.text = 'bwb365liga.com'; setState(() {}); },
              ),
              ActionChip(
                label: const Text('bwbet365.com'),
                onPressed: () { _domainCtrl.text = 'bwbet365.com'; setState(() {}); },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // BANKROLL
          _sectionHeader('Bankroll'),
          TextField(
            controller: _bankrollCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Bankroll (Rp)',
              hintText: '7500000',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // STRATEGY
          _sectionHeader('Parlay Strategy'),
          DropdownButtonFormField<String>(
            value: _settings.parlayStrategy,
            items: const [
              DropdownMenuItem(value: 'bwb365', child: Text('BWB365 Pattern (O/U dominant)')),
              DropdownMenuItem(value: 'oddeven', child: Text('Odd/Even (defensive leagues)')),
              DropdownMenuItem(value: 'conservative', child: Text('Conservative (AH only)')),
            ],
            onChanged: (v) {
              if (v != null) _settings.saveParlayStrategy(v);
            },
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),

          // AI MODEL (FREE only)
          _sectionHeader('AI Model (Free Only)'),
          DropdownButtonFormField<String>(
            value: _settings.aiModel,
            items: AiModels.allModels.map((m) => DropdownMenuItem(
              value: m['id'],
              child: Text('${m['name']} (${m['provider']}) [${m['ctx']}]', style: const TextStyle(fontSize: 13)),
            )).toList(),
            onChanged: (v) {
              if (v != null) {
                _settings.saveAiModel(v);
                setState(() {});
              }
            },
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              suffixIcon: _settings.hasOpenRouterKey ? null : const Tooltip(
                message: 'Set OpenRouter key first',
                child: Icon(Icons.warning, color: Colors.orange, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('Selected: ${AiModels.getModelName(_settings.aiModel)} by ${AiModels.getProvider(_settings.aiModel)}',
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 30),

          // CLEAR
          OutlinedButton.icon(
            onPressed: () => _clearSensitive(),
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            label: const Text('Clear All API Keys & Tokens', style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  void _clearSensitive() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All Keys?'),
        content: const Text('Delete all API keys and tokens (encrypted data). This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _settings.clearSensitive();
              _orKeyCtrl.clear();
              _tgTokenCtrl.clear();
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All keys cleared'), backgroundColor: Colors.orange),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

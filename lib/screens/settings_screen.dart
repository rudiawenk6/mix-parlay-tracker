import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/crypto_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService.instance;
  bool _showORKey = false;
  bool _showTGToken = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // === SECURITY NOTICE ===
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
                      'All API keys & tokens are AES-256 encrypted before storage',
                      style: TextStyle(fontSize: 12, color: Colors.greenAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // === OPENROUTER API KEY ===
          _sectionHeader('AI Analysis (OpenRouter)'),
          _encryptedField(
            label: 'OpenRouter API Key',
            value: _settings.openRouterKey,
            maskedValue: _settings.openRouterKeyMasked,
            showValue: _showORKey,
            onToggleShow: () => setState(() => _showORKey = !_showORKey),
            validator: CryptoService.isValidOpenRouterKey,
            hintText: 'sk-or-v1-xxxxx',
            onSave: (v) => _settings.saveOpenRouterKey(v),
          ),
          const SizedBox(height: 16),

          // === TELEGRAM ===
          _sectionHeader('Telegram Bot'),
          _encryptedField(
            label: 'Bot Token',
            value: _settings.telegramToken,
            maskedValue: _settings.telegramTokenMasked,
            showValue: _showTGToken,
            onToggleShow: () => setState(() => _showTGToken = !_showTGToken),
            validator: CryptoService.isValidTelegramToken,
            hintText: '123456789:AAF8Q...xxxx',
            onSave: (v) => _settings.saveTelegramToken(v),
          ),
          const SizedBox(height: 8),
          _textField(
            label: 'Chat ID',
            value: _settings.telegramChatId,
            hintText: '-1003943817890',
            onSave: (v) => _settings.saveTelegramChatId(v),
          ),
          const SizedBox(height: 16),

          // === ODDS DOMAIN ===
          _sectionHeader('Odds API Domain'),
          _textField(
            label: 'Domain',
            value: _settings.bwbDomain,
            hintText: 'letsaiabt365.com',
            validator: CryptoService.isValidDomain,
            onSave: (v) => _settings.saveBwbDomain(v),
          ),
          Text(
            'Current URL: https://${_settings.bwbDomain}/_view/ParGenWFH.ashx',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // === BANKROLL ===
          _sectionHeader('Bankroll'),
          _textField(
            label: 'Bankroll (Rp)',
            value: _settings.bankroll.round().toString(),
            hintText: '7500000',
            isNumber: true,
            onSave: (v) => _settings.saveBankroll(double.parse(v)),
          ),
          const SizedBox(height: 16),

          // === STRATEGY ===
          _sectionHeader('Parlay Strategy'),
          DropdownButtonFormField<String>(
            value: _settings.parlayStrategy,
            items: const [
              DropdownMenuItem(value: 'bwb365', child: Text('BWB365 Pattern (O/U dominant)')),
              DropdownMenuItem(value: 'oddeven', child: Text('Odd/Even (defensif leagues)')),
              DropdownMenuItem(value: 'conservative', child: Text('Conservative (AH only)')),
            ],
            onChanged: (v) {
              if (v != null) {
                _settings.saveParlayStrategy(v);
                setState(() {});
              }
            },
            decoration: const InputDecoration(labelText: 'Strategy'),
          ),
          const SizedBox(height: 24),

          // === CLEAR SENSITIVE ===
          FilledButton.icon(
            onPressed: () => _clearSensitive(),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Clear All API Keys & Tokens'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade800),
          ),
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

  Widget _encryptedField({
    required String label,
    required String value,
    required String maskedValue,
    required bool showValue,
    required VoidCallback onToggleShow,
    required bool Function(String) validator,
    required String hintText,
    required Future Function(String) onSave,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
            IconButton(
              icon: Icon(showValue ? Icons.visibility_off : Icons.visibility, size: 18),
              onPressed: onToggleShow,
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: showValue ? value : maskedValue,
          obscureText: !showValue && value.isNotEmpty,
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: value.isNotEmpty ? const Icon(Icons.lock, size: 16) : null,
          ),
          onFieldSubmitted: (v) async {
            if (validator(v)) {
              await onSave(v);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label saved (encrypted)'), backgroundColor: Colors.green),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invalid $label format'), backgroundColor: Colors.red),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _textField({
    required String label,
    required String value,
    required String hintText,
    bool Function(String)? validator,
    bool isNumber = false,
    required Future Function(String) onSave,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        initialValue: value,
        keyboardType: isNumber ? TextInputType.number : null,
        decoration: InputDecoration(labelText: label, hintText: hintText),
        onFieldSubmitted: (v) async {
          if (validator != null && !validator(v)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid $label'), backgroundColor: Colors.red),
            );
            return;
          }
          await onSave(v);
          setState(() {});
        },
      ),
    );
  }

  void _clearSensitive() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All Keys?'),
        content: const Text('This will permanently delete all API keys and tokens (encrypted data).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _settings.clearSensitive();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

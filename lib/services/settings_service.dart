import 'package:shared_preferences/shared_preferences.dart';
import 'crypto_service.dart';

class SettingsService {
  // Keys stored ENCRYPTED in SharedPreferences
  static const _keyOpenRouter = 'enc_openrouter';
  static const _keyTelegramToken = 'enc_tg_token';
  static const _keyTelegramChat = 'enc_tg_chat';

  // Keys stored as plain (not sensitive)
  static const _keyBwbDomain = 'bwb_domain';
  static const _keyBankroll = 'bankroll';
  static const _keyParlayStrategy = 'parlay_strategy';
  static const _keyAiModel = 'ai_model';

  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();

  SettingsService._();

  // Sensitive fields (decrypted in memory only)
  String _openRouterKey = '';
  String _telegramToken = '';
  String _telegramChatId = '-1003943817890';

  // Non-sensitive fields
  String bwbDomain = 'letsaiabt365.com';
  double bankroll = 7500000;
  String parlayStrategy = 'bwb365'; // bwb365, oddeven, conservative
  String aiModel = 'google/gemini-2.0-flash-001'; // default free model

  // Getters (never expose raw values in logs)
  String get openRouterKey => _openRouterKey;
  String get openRouterKeyMasked => CryptoService.mask(_openRouterKey);
  String get telegramToken => _telegramToken;
  String get telegramTokenMasked => CryptoService.mask(_telegramToken);
  String get telegramChatId => _telegramChatId;
  bool get hasOpenRouterKey => _openRouterKey.isNotEmpty;
  bool get hasTelegramToken => _telegramToken.isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Decrypt sensitive values
    final encOR = prefs.getString(_keyOpenRouter) ?? '';
    _openRouterKey = encOR.isNotEmpty ? CryptoService.decrypt(encOR) : '';

    final encTG = prefs.getString(_keyTelegramToken) ?? '';
    _telegramToken = encTG.isNotEmpty ? CryptoService.decrypt(encTG) : '';

    final encChat = prefs.getString(_keyTelegramChat) ?? '';
    _telegramChatId = encChat.isNotEmpty ? CryptoService.decrypt(encChat) : '-1003943817890';

    // Plain values
    bwbDomain = prefs.getString(_keyBwbDomain) ?? 'letsaiabt365.com';
    bankroll = prefs.getDouble(_keyBankroll) ?? 7500000;
    parlayStrategy = prefs.getString(_keyParlayStrategy) ?? 'bwb365';
    aiModel = prefs.getString(_keyAiModel) ?? 'google/gemini-2.0-flash-001';
  }

  Future<bool> saveOpenRouterKey(String key) async {
    if (!CryptoService.isValidOpenRouterKey(key)) return false;
    _openRouterKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOpenRouter, CryptoService.encrypt(key));
    return true;
  }

  Future<bool> saveTelegramToken(String token) async {
    if (!CryptoService.isValidTelegramToken(token)) return false;
    _telegramToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTelegramToken, CryptoService.encrypt(token));
    return true;
  }

  Future<void> saveTelegramChatId(String chatId) async {
    _telegramChatId = chatId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTelegramChat, CryptoService.encrypt(chatId));
  }

  Future<bool> saveBwbDomain(String domain) async {
    if (!CryptoService.isValidDomain(domain)) return false;
    bwbDomain = domain;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBwbDomain, domain);
    return true;
  }

  Future<void> saveBankroll(double value) async {
    bankroll = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyBankroll, value);
  }

  Future<void> saveParlayStrategy(String strategy) async {
    parlayStrategy = strategy;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyParlayStrategy, strategy);
  }

  Future<void> saveAiModel(String model) async {
    aiModel = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAiModel, model);
  }

  /// Clear all sensitive data (logout)
  Future<void> clearSensitive() async {
    _openRouterKey = '';
    _telegramToken = '';
    _telegramChatId = '-1003943817890';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOpenRouter);
    await prefs.remove(_keyTelegramToken);
    await prefs.remove(_keyTelegramChat);
  }

  /// Get full odds URL based on current domain
  String get oddsUrlLive =>
      'https://$bwbDomain/_view/ParGenWFH.ashx?g=2&ot=t&wd=&ia=0&update=true';
  String get oddsUrlFinished =>
      'https://$bwbDomain/_view/ParGenWFH.ashx?g=2&ot=r&wd=&ia=0&update=true';
}

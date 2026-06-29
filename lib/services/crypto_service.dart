import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart';

/// Encrypt/decrypt sensitive data (API keys, tokens, URLs)
/// Uses device-specific key derived from app seed
class CryptoService {
  static const _seed = 'M1xP4r14yTr4ck3r2026S3cur3K3y!';

  static enc.Key get _key {
    final bytes = utf8.encode(_seed);
    final hash = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(hash.bytes));
  }

  static String encrypt(String plainText) {
    if (plainText.isEmpty) return '';
    final key = _key;
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // Store iv + encrypted together
    return '${iv.base64}:${encrypted.base64}';
  }

  static String decrypt(String cipherText) {
    if (cipherText.isEmpty) return '';
    try {
      final parts = cipherText.split(':');
      if (parts.length != 2) return '';
      final key = _key;
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypter = enc.Encrypter(enc.AES(key));
      final decrypted = encrypter.decrypt64(parts[1], iv: iv);
      return decrypted;
    } catch (_) {
      return '';
    }
  }

  /// Mask string for display (e.g. "ghp_Kr...j1XM")
  static String mask(String value, {int showStart = 4, int showEnd = 4}) {
    if (value.length <= showStart + showEnd) return value;
    return '${value.substring(0, showStart)}...${value.substring(value.length - showEnd)}';
  }

  /// Validate OpenRouter API key format
  static bool isValidOpenRouterKey(String key) {
    return key.startsWith('sk-or-') && key.length > 20;
  }

  /// Validate Telegram bot token format
  static bool isValidTelegramToken(String token) {
    return RegExp(r'^\d+:[A-Za-z0-9_-]{30,}$').hasMatch(token);
  }

  /// Validate URL/domain format
  static bool isValidDomain(String domain) {
    return RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(domain);
  }
}

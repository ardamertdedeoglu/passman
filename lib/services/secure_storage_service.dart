import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around FlutterSecureStorage for storing sensitive data
/// (encryption key for biometric unlock).
class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyEncryptionKey = 'encryption_key';
  static const _keyEmail = 'user_email';
  static const _keyBiometricEnabled = 'biometric_enabled';

  // ── Encryption Key ──

  Future<void> saveEncryptionKey(Uint8List key) async {
    await _storage.write(key: _keyEncryptionKey, value: base64Encode(key));
  }

  Future<Uint8List?> getEncryptionKey() async {
    final encoded = await _storage.read(key: _keyEncryptionKey);
    if (encoded == null) return null;
    return base64Decode(encoded);
  }

  Future<void> deleteEncryptionKey() async {
    await _storage.delete(key: _keyEncryptionKey);
  }

  // ── Email ──

  Future<void> saveEmail(String email) async {
    await _storage.write(key: _keyEmail, value: email);
  }

  Future<String?> getEmail() async {
    return _storage.read(key: _keyEmail);
  }

  // ── Biometric Flag ──

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyBiometricEnabled);
    return val == 'true';
  }

  // ── Clear All ──

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

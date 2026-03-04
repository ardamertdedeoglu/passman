import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Zero-knowledge crypto engine using the "Two-Key" derivation approach.
///
/// From a single Master Password + user-specific salt, we derive:
/// 1. [authKey]       — sent to server for authentication (never used for encryption)
/// 2. [encryptionKey] — stays on-device, used for AES-256-GCM encrypt/decrypt
class CryptoEngine {
  CryptoEngine._();

  /// Derives two keys from the master password and salt.
  ///
  /// Returns a [DerivedKeys] containing both the auth hash (base64)
  /// and the raw encryption key bytes.
  static Future<DerivedKeys> deriveKeys(
    String masterPassword,
    String salt,
  ) async {
    final algorithm = Argon2id(
      memory: 65536, // 64 MB
      parallelism: 1,
      iterations: 3,
      hashLength: 32,
    );

    // Derive auth key using "auth" context appended to salt
    final authSalt = utf8.encode('$salt:auth');
    final authResult = await algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(masterPassword)),
      nonce: authSalt,
    );
    final authKeyBytes = await authResult.extractBytes();

    // Derive encryption key using "enc" context appended to salt
    final encSalt = utf8.encode('$salt:enc');
    final encResult = await algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(masterPassword)),
      nonce: encSalt,
    );
    final encKeyBytes = await encResult.extractBytes();

    return DerivedKeys(
      authHash: base64Encode(authKeyBytes),
      encryptionKey: Uint8List.fromList(encKeyBytes),
    );
  }

  /// Encrypts [plaintext] using AES-256-GCM with the given [encryptionKey].
  ///
  /// Returns an [EncryptedData] containing base64-encoded ciphertext and nonce.
  static Future<EncryptedData> encrypt(
    String plaintext,
    Uint8List encryptionKey,
  ) async {
    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(encryptionKey);
    final nonce = algorithm.newNonce();

    final secretBox = await algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );

    // Combine ciphertext + MAC for storage
    final combined = Uint8List.fromList([
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    return EncryptedData(
      ciphertext: base64Encode(combined),
      nonce: base64Encode(nonce),
    );
  }

  /// Decrypts [ciphertext] using AES-256-GCM with the given [encryptionKey] and [nonce].
  ///
  /// Returns the original plaintext string.
  static Future<String> decrypt(
    String ciphertextBase64,
    String nonceBase64,
    Uint8List encryptionKey,
  ) async {
    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(encryptionKey);

    final combined = base64Decode(ciphertextBase64);
    final nonceBytes = base64Decode(nonceBase64);

    // Split combined into ciphertext + MAC (last 16 bytes)
    final cipherText = combined.sublist(0, combined.length - 16);
    final mac = Mac(combined.sublist(combined.length - 16));

    final secretBox = SecretBox(cipherText, nonce: nonceBytes, mac: mac);

    final decrypted = await algorithm.decrypt(secretBox, secretKey: secretKey);
    return utf8.decode(decrypted);
  }
}

/// Holds the two derived keys from the master password.
class DerivedKeys {
  final String authHash; // Base64-encoded, sent to server
  final Uint8List encryptionKey; // Raw bytes, NEVER leaves the device

  const DerivedKeys({required this.authHash, required this.encryptionKey});
}

/// Holds encrypted output data.
class EncryptedData {
  final String ciphertext; // Base64-encoded
  final String nonce; // Base64-encoded

  const EncryptedData({required this.ciphertext, required this.nonce});
}

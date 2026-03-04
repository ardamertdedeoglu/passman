import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passman_frontend/crypto/crypto_engine.dart';
import 'package:passman_frontend/services/api_service.dart';
import 'package:passman_frontend/services/biometric_service.dart';
import 'package:passman_frontend/services/secure_storage_service.dart';
import 'package:uuid/uuid.dart';

// ── Service Providers ──

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);
final biometricServiceProvider = Provider<BiometricService>(
  (ref) => BiometricService(),
);

// ── Auth State ──

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? userId;
  final String? email;
  final Uint8List? encryptionKey; // In-memory only, cleared on lock
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.userId,
    this.email,
    this.encryptionKey,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? userId,
    String? email,
    Uint8List? encryptionKey,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      encryptionKey: encryptionKey ?? this.encryptionKey,
      error: error,
    );
  }
}

// ── Auth Notifier ──

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;
  final SecureStorageService _secureStorage;
  final BiometricService _biometric;

  AuthNotifier(this._api, this._secureStorage, this._biometric)
    : super(const AuthState());

  Future<bool> register(String email, String masterPassword) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Generate a random salt for this user
      final betterSalt = const Uuid().v4();

      // Derive keys
      final keys = await CryptoEngine.deriveKeys(masterPassword, betterSalt);

      // Register with server (only authHash + salt, never the encryption key)
      await _api.register(
        email: email,
        authHash: keys.authHash,
        salt: betterSalt,
      );

      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> login(String email, String masterPassword) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // First, get the user's salt
      final salt = await _api.getSalt(email);
      if (salt == null) {
        state = state.copyWith(isLoading: false, error: 'User not found');
        return false;
      }

      // Derive keys from master password + salt
      final keys = await CryptoEngine.deriveKeys(masterPassword, salt);

      // Login with authHash (NOT the encryption key)
      final response = await _api.login(email: email, authHash: keys.authHash);

      // Extract user ID from JWT payload
      final token = response['token'] as String;
      final payload = _decodeJwtPayload(token);
      final userId = payload['sub'] as String;

      // Check if biometric verification is needed (BEFORE setting isAuthenticated)
      final biometricEnabled = await _secureStorage.isBiometricEnabled();
      final biometricAvailable = await _biometric.isAvailable();

      if (biometricEnabled && biometricAvailable) {
        state = state.copyWith(isLoading: false);
        final biometricPassed = await _biometric.authenticate();
        if (!biometricPassed) {
          _api.clearToken();
          state = state.copyWith(
            isLoading: false,
            error: 'Biometric verification failed. Please try again.',
          );
          return false;
        }
      }

      // All checks passed — set authenticated
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        userId: userId,
        email: email,
        encryptionKey: keys.encryptionKey,
      );

      // Save email for future use
      await _secureStorage.saveEmail(email);

      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> unlockWithBiometrics() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final isAuthenticated = await _biometric.authenticate();
      if (!isAuthenticated) {
        state = state.copyWith(
          isLoading: false,
          error: 'Biometric authentication failed',
        );
        return false;
      }

      final encKey = await _secureStorage.getEncryptionKey();
      final email = await _secureStorage.getEmail();

      if (encKey == null || email == null) {
        state = state.copyWith(
          isLoading: false,
          error:
              'No stored credentials found. Please login with master password.',
        );
        return false;
      }

      // Biometric unlock uses stored encryption key for offline vault access
      // No server call needed — vault will sync when loadVault() runs
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        email: email,
        encryptionKey: encKey,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Biometric unlock failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> enableBiometrics() async {
    if (state.encryptionKey != null) {
      await _secureStorage.saveEncryptionKey(state.encryptionKey!);
      await _secureStorage.setBiometricEnabled(true);
    }
  }

  /// Simple biometric verification — just prompts the dialog, no credential management.
  /// Used as extra security step after successful email/password login.
  Future<bool> verifyBiometric() async {
    try {
      return await _biometric.authenticate();
    } catch (e) {
      return false;
    }
  }

  Future<void> disableBiometrics() async {
    await _secureStorage.deleteEncryptionKey();
    await _secureStorage.setBiometricEnabled(false);
  }

  void lock() {
    // Clear encryption key from memory (critical security measure)
    state = const AuthState();
    _api.clearToken();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Invalid JWT');
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return Map<String, dynamic>.from(
      const JsonDecoder().convert(decoded) as Map,
    );
  }
}

// ── Providers ──

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(apiServiceProvider),
    ref.read(secureStorageProvider),
    ref.read(biometricServiceProvider),
  );
});

final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  final biometric = ref.read(biometricServiceProvider);
  return biometric.isAvailable();
});

final biometricEnabledProvider = FutureProvider<bool>((ref) async {
  final storage = ref.read(secureStorageProvider);
  return storage.isBiometricEnabled();
});

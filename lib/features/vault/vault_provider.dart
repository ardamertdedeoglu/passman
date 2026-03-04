import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passman_frontend/crypto/crypto_engine.dart';
import 'package:passman_frontend/features/auth/auth_provider.dart';
import 'package:passman_frontend/features/vault/models/vault_item_model.dart';
import 'package:passman_frontend/services/api_service.dart';
import 'package:passman_frontend/services/local_db_service.dart';
import 'package:uuid/uuid.dart';

// ── Local DB Provider ──

final localDbServiceProvider = Provider<LocalDbService>(
  (ref) => LocalDbService(),
);

// ── Vault State ──

class VaultState {
  final List<VaultItemModel> items;
  final bool isLoading;
  final bool isSyncing;
  final String? error;
  final String searchQuery;

  const VaultState({
    this.items = const [],
    this.isLoading = false,
    this.isSyncing = false,
    this.error,
    this.searchQuery = '',
  });

  VaultState copyWith({
    List<VaultItemModel>? items,
    bool? isLoading,
    bool? isSyncing,
    String? error,
    String? searchQuery,
  }) {
    return VaultState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<VaultItemModel> get filteredItems {
    if (searchQuery.isEmpty) return items;
    final q = searchQuery.toLowerCase();
    return items
        .where(
          (item) =>
              item.title.toLowerCase().contains(q) ||
              item.username.toLowerCase().contains(q) ||
              (item.url?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }
}

// ── Vault Notifier ──

class VaultNotifier extends StateNotifier<VaultState> {
  final ApiService _api;
  final LocalDbService _localDb;
  final Ref _ref;

  VaultNotifier(this._api, this._localDb, this._ref)
    : super(const VaultState());

  Uint8List? get _encryptionKey => _ref.read(authStateProvider).encryptionKey;
  String? get _userId => _ref.read(authStateProvider).userId;

  /// Fetch vault from server (or cache if offline), decrypt all items.
  Future<void> loadVault() async {
    final encKey = _encryptionKey;
    if (encKey == null) {
      print('[VAULT] loadVault: encryptionKey is null, aborting');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      List<dynamic> rawItems;

      try {
        // Try fetching from server
        rawItems = await _api.fetchVault();
        print('[VAULT] Fetched ${rawItems.length} items from server');

        // Cache encrypted items locally
        if (_userId != null) {
          final cacheItems = rawItems
              .map<Map<String, dynamic>>(
                (item) => {
                  'id': item['id'],
                  'user_id': item['user_id'],
                  'encrypted_blob': item['encrypted_blob'],
                  'nonce': item['nonce'],
                  'updated_at': item['updated_at']?.toString() ?? '',
                },
              )
              .toList();
          await _localDb.replaceAllItems(_userId!, cacheItems);
        }
      } catch (e) {
        print('[VAULT] Server fetch failed: $e, loading from cache');
        // Offline: load from local cache
        if (_userId != null) {
          final cached = await _localDb.getVaultItems(_userId!);
          rawItems = cached;
        } else {
          rawItems = [];
        }
      }

      // Decrypt all items
      final decrypted = <VaultItemModel>[];
      for (final raw in rawItems) {
        try {
          final plaintext = await CryptoEngine.decrypt(
            raw['encrypted_blob'] as String,
            raw['nonce'] as String,
            encKey,
          );
          final updatedAtStr = raw['updated_at']?.toString() ?? '';
          final updatedAt = DateTime.tryParse(updatedAtStr) ?? DateTime.now();
          decrypted.add(
            VaultItemModel.fromJsonString(
              plaintext,
              raw['id'] as String,
              updatedAt,
            ),
          );
        } catch (e) {
          print('[VAULT] Decryption failed for item ${raw['id']}: $e');
        }
      }

      print(
        '[VAULT] Successfully decrypted ${decrypted.length}/${rawItems.length} items',
      );
      state = state.copyWith(items: decrypted, isLoading: false);
    } catch (e) {
      print('[VAULT] loadVault error: $e');
      state = state.copyWith(isLoading: false, error: 'Failed to load vault');
    }
  }

  /// Add or update a vault item.
  Future<bool> saveItem(VaultItemModel item) async {
    final encKey = _encryptionKey;
    final userId = _userId;
    if (encKey == null || userId == null) return false;

    try {
      final isNew = !state.items.any((i) => i.id == item.id);
      final now = DateTime.now();
      final updatedItem = item.copyWith(updatedAt: now);

      // Encrypt the item
      final encrypted = await CryptoEngine.encrypt(
        updatedItem.toJsonString(),
        encKey,
      );

      final syncItem = {
        'id': updatedItem.id,
        'user_id': userId,
        'encrypted_blob': encrypted.ciphertext,
        'nonce': encrypted.nonce,
        'updated_at': now.toUtc().toIso8601String(),
      };

      // Try syncing to server
      try {
        await _api.syncVault([syncItem]);
      } catch (_) {
        // Save locally if offline
      }

      // Always save to local cache
      await _localDb.upsertVaultItem(syncItem);

      // Update state
      final newItems = List<VaultItemModel>.from(state.items);
      if (isNew) {
        newItems.insert(0, updatedItem);
      } else {
        final idx = newItems.indexWhere((i) => i.id == item.id);
        if (idx != -1) newItems[idx] = updatedItem;
      }
      state = state.copyWith(items: newItems);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to save item');
      return false;
    }
  }

  /// Delete a vault item.
  Future<bool> deleteItem(String id) async {
    try {
      try {
        await _api.deleteVaultItem(id);
      } catch (_) {
        // Offline
      }
      await _localDb.deleteVaultItem(id);

      final newItems = state.items.where((i) => i.id != id).toList();
      state = state.copyWith(items: newItems);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete item');
      return false;
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Clear all decrypted data from memory (lock).
  void clearVault() {
    state = const VaultState();
  }
}

// ── Provider ──

final vaultProvider = StateNotifierProvider<VaultNotifier, VaultState>((ref) {
  return VaultNotifier(
    ref.read(apiServiceProvider),
    ref.read(localDbServiceProvider),
    ref,
  );
});

/// Helper to generate a new UUID for vault items.
String generateItemId() => const Uuid().v4();

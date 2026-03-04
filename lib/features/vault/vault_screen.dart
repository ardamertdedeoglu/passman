import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:passman_frontend/core/constants.dart';
import 'package:passman_frontend/core/theme.dart';
import 'package:passman_frontend/features/auth/auth_provider.dart';
import 'package:passman_frontend/features/vault/vault_provider.dart';
import 'package:intl/intl.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen>
    with WidgetsBindingObserver {
  Timer? _autoLockTimer;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetAutoLockTimer();

    // Load vault on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vaultProvider.notifier).loadVault();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoLockTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // When app goes to background, start a short timer to lock
      _autoLockTimer?.cancel();
      _autoLockTimer = Timer(const Duration(seconds: 30), _lock);
    } else if (state == AppLifecycleState.resumed) {
      _resetAutoLockTimer();
    }
  }

  void _resetAutoLockTimer() {
    _autoLockTimer?.cancel();
    _autoLockTimer = Timer(
      const Duration(seconds: AppConstants.autoLockTimeoutSeconds),
      _lock,
    );
  }

  void _lock() {
    ref.read(vaultProvider.notifier).clearVault();
    ref.read(authStateProvider.notifier).lock();
    if (mounted) context.go('/login');
  }

  void _onUserInteraction() {
    _resetAutoLockTimer();
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultProvider);
    final authState = ref.watch(authStateProvider);

    return GestureDetector(
      onTap: _onUserInteraction,
      onPanDown: (_) => _onUserInteraction(),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── App Bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'My Vault',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              authState.email ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.lock_outline,
                          color: AppTheme.textSecondary,
                        ),
                        tooltip: 'Lock',
                        onPressed: _lock,
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppTheme.textSecondary,
                        ),
                        color: AppTheme.card,
                        onSelected: (value) async {
                          if (value == 'biometric') {
                            final biometricEnabled = await ref
                                .read(secureStorageProvider)
                                .isBiometricEnabled();
                            if (biometricEnabled) {
                              await ref
                                  .read(authStateProvider.notifier)
                                  .disableBiometrics();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Biometrics disabled'),
                                  ),
                                );
                              }
                            } else {
                              await ref
                                  .read(authStateProvider.notifier)
                                  .enableBiometrics();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Biometrics enabled'),
                                    backgroundColor: AppTheme.secondary,
                                  ),
                                );
                              }
                            }
                          } else if (value == 'sync') {
                            await ref.read(vaultProvider.notifier).loadVault();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'sync',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sync,
                                  color: AppTheme.textSecondary,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text('Sync Vault'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'biometric',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.fingerprint,
                                  color: AppTheme.textSecondary,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text('Toggle Biometrics'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Search ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (q) =>
                        ref.read(vaultProvider.notifier).setSearchQuery(q),
                    decoration: InputDecoration(
                      hintText: 'Search vault...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.textSecondary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppTheme.textSecondary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(vaultProvider.notifier)
                                    .setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),

                // ── Vault List ──
                Expanded(
                  child: vaultState.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                          ),
                        )
                      : vaultState.filteredItems.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          itemCount: vaultState.filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = vaultState.filteredItems[index];
                            return Dismissible(
                              key: Key(item.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.error,
                                ),
                              ),
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppTheme.card,
                                    title: const Text('Delete Item?'),
                                    content: Text(
                                      'Are you sure you want to delete "${item.title}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: AppTheme.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (_) {
                                ref
                                    .read(vaultProvider.notifier)
                                    .deleteItem(item.id);
                              },
                              child: _VaultItemCard(
                                title: item.title,
                                username: item.username,
                                url: item.url,
                                updatedAt: item.updatedAt,
                                onTap: () =>
                                    context.go('/vault/edit/${item.id}'),
                                onCopyPassword: () {
                                  Clipboard.setData(
                                    ClipboardData(text: item.password),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Password copied to clipboard',
                                      ),
                                      duration: Duration(seconds: 2),
                                      backgroundColor: AppTheme.secondary,
                                    ),
                                  );
                                  // Auto-clear clipboard after 30 seconds
                                  Future.delayed(
                                    const Duration(seconds: 30),
                                    () {
                                      Clipboard.setData(
                                        const ClipboardData(text: ''),
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.go('/vault/add'),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_open_outlined,
            size: 72,
            color: AppTheme.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your vault is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to add your first password',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Vault Item Card Widget ──

class _VaultItemCard extends StatelessWidget {
  final String title;
  final String username;
  final String? url;
  final DateTime updatedAt;
  final VoidCallback onTap;
  final VoidCallback onCopyPassword;

  const _VaultItemCard({
    required this.title,
    required this.username,
    this.url,
    required this.updatedAt,
    required this.onTap,
    required this.onCopyPassword,
  });

  IconData _getIconForUrl(String? url) {
    if (url == null || url.isEmpty) return Icons.key_outlined;
    final lower = url.toLowerCase();
    if (lower.contains('google')) return Icons.g_mobiledata;
    if (lower.contains('github')) return Icons.code;
    if (lower.contains('twitter') || lower.contains('x.com')) {
      return Icons.alternate_email;
    }
    if (lower.contains('facebook') || lower.contains('meta')) {
      return Icons.facebook;
    }
    return Icons.language;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassCard(opacity: 0.08, radius: 16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForUrl(url),
                    color: AppTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM d, yyyy').format(updatedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  tooltip: 'Copy password',
                  onPressed: onCopyPassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

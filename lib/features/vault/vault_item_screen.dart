import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:passman_frontend/core/theme.dart';
import 'package:passman_frontend/features/vault/models/vault_item_model.dart';
import 'package:passman_frontend/features/vault/vault_provider.dart';

class VaultItemScreen extends ConsumerStatefulWidget {
  final String? itemId;

  const VaultItemScreen({super.key, this.itemId});

  @override
  ConsumerState<VaultItemScreen> createState() => _VaultItemScreenState();
}

class _VaultItemScreenState extends ConsumerState<VaultItemScreen> {
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _notesController = TextEditingController();
  final _urlController = TextEditingController();
  bool _obscurePassword = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.itemId != null) {
      _isEditing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final vaultState = ref.read(vaultProvider);
        final item = vaultState.items.firstWhere(
          (i) => i.id == widget.itemId,
          orElse: () => throw Exception('Item not found'),
        );
        _titleController.text = item.title;
        _usernameController.text = item.username;
        _passwordController.text = item.password;
        _notesController.text = item.notes ?? '';
        _urlController.text = item.url ?? '';
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  String _generatePassword({int length = 20}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()-_=+[]{}|;:,.<>?';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (title.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title, username, and password are required'),
        ),
      );
      return;
    }

    final item = VaultItemModel(
      id: widget.itemId ?? generateItemId(),
      title: title,
      username: username,
      password: password,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      url: _urlController.text.trim().isEmpty
          ? null
          : _urlController.text.trim(),
      updatedAt: DateTime.now(),
    );

    final success = await ref.read(vaultProvider.notifier).saveItem(item);
    if (success && mounted) {
      context.go('/vault');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── App Bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppTheme.textPrimary,
                      ),
                      onPressed: () => context.go('/vault'),
                    ),
                    Expanded(
                      child: Text(
                        _isEditing ? 'Edit Item' : 'Add Item',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _save,
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Form ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: AppTheme.glassCard(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Title'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Google Account',
                            prefixIcon: Icon(
                              Icons.label_outline,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('Username / Email'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. user@example.com',
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('Password'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Enter password',
                            prefixIcon: const Icon(
                              Icons.key_outlined,
                              color: AppTheme.textSecondary,
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppTheme.textSecondary,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.auto_awesome,
                                    color: AppTheme.secondary,
                                  ),
                                  tooltip: 'Generate password',
                                  onPressed: () {
                                    setState(() {
                                      _passwordController.text =
                                          _generatePassword();
                                      _obscurePassword = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('URL (optional)'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _urlController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            hintText: 'e.g. https://accounts.google.com',
                            prefixIcon: Icon(
                              Icons.language,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildLabel('Notes (optional)'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Any additional notes...',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 60),
                              child: Icon(
                                Icons.notes_outlined,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

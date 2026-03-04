import 'dart:convert';

/// Represents a decrypted vault item displayed in the UI.
class VaultItemModel {
  final String id;
  final String title;
  final String username;
  final String password;
  final String? notes;
  final String? url;
  final DateTime updatedAt;

  const VaultItemModel({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    this.notes,
    this.url,
    required this.updatedAt,
  });

  /// Convert to JSON string for encryption.
  String toJsonString() {
    return jsonEncode({
      'title': title,
      'username': username,
      'password': password,
      'notes': notes,
      'url': url,
    });
  }

  /// Create from decrypted JSON string.
  factory VaultItemModel.fromJsonString(
    String jsonStr,
    String id,
    DateTime updatedAt,
  ) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return VaultItemModel(
      id: id,
      title: map['title'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      notes: map['notes'],
      url: map['url'],
      updatedAt: updatedAt,
    );
  }

  VaultItemModel copyWith({
    String? id,
    String? title,
    String? username,
    String? password,
    String? notes,
    String? url,
    DateTime? updatedAt,
  }) {
    return VaultItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      notes: notes ?? this.notes,
      url: url ?? this.url,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

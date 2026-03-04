import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:passman_frontend/core/constants.dart';

class ApiService {
  String? _token;
  late final String _baseUrl;

  ApiService() {
    // Use appropriate URL based on platform
    try {
      if (Platform.isAndroid) {
        _baseUrl = AppConstants.apiBaseUrl;
      } else {
        _baseUrl = AppConstants.apiBaseUrlDesktop;
      }
    } catch (_) {
      _baseUrl = AppConstants.apiBaseUrlDesktop;
    }
  }

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;
  bool get hasToken => _token != null;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── Auth ──

  Future<Map<String, dynamic>> register({
    required String email,
    required String authHash,
    required String salt,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: _headers,
      body: jsonEncode({'email': email, 'auth_hash': authHash, 'salt': salt}),
    );
    return _handleResponse(response);
  }

  Future<String?> getSalt(String email) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/salt?email=${Uri.encodeQueryComponent(email)}'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['salt'] as String?;
    }
    return null;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String authHash,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'auth_hash': authHash}),
    );
    final data = _handleResponse(response);
    if (data.containsKey('token')) {
      _token = data['token'] as String;
    }
    return data;
  }

  // ── Vault ──

  Future<List<dynamic>> fetchVault() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/vault'),
      headers: _headers,
    );
    final data = _handleResponse(response);
    return data['items'] as List<dynamic>? ?? [];
  }

  Future<void> syncVault(List<Map<String, dynamic>> items) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/vault/sync'),
      headers: _headers,
      body: jsonEncode({'items': items}),
    );
    _handleResponse(response);
  }

  Future<void> deleteVaultItem(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/vault/$id'),
      headers: _headers,
    );
    _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException(
        statusCode: response.statusCode,
        message: body['error']?.toString() ?? 'Unknown error',
      );
    }
    return body;
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

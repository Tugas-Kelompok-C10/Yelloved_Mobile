import 'dart:convert';

import 'package:http/http.dart' as http;

/// Configure with --dart-define=API_BASE_URL=http://... and override the
/// endpoint paths with API_REGISTER_PATH, API_LOGIN_PATH, and API_PROFILE_PATH
/// when the Django project uses different routes.
class AccountApi {
  AccountApi({http.Client? client}) : _client = client ?? http.Client();

  static const baseUrl = String.fromEnvironment('API_BASE_URL');
  static const registerPath = String.fromEnvironment(
    'API_REGISTER_PATH',
    defaultValue: '/api/account/register/',
  );
  static const loginPath = String.fromEnvironment(
    'API_LOGIN_PATH',
    defaultValue: '/api/account/login/',
  );
  static const profilePath = String.fromEnvironment(
    'API_PROFILE_PATH',
    defaultValue: '/api/account/profile/',
  );

  final http.Client _client;
  String? _token;
  bool _usesTokenAuth = false;

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final parts = name.trim().split(RegExp(r'\s+'));
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.skip(1).join(' ') : '';
    final data = await _send(
      'POST',
      registerPath,
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email.trim(),
        'password': password,
      },
    );
    return data;
  }

  Future<void> login({required String email, required String password}) async {
    final data = await _send(
      'POST',
      loginPath,
      body: {'email': email.trim(), 'password': password},
    );
    final token = data['token'] ?? data['key'] ?? data['access'];
    if (token is! String || token.isEmpty) {
      throw const AccountApiException(
        'Login response tidak berisi token (token, key, atau access).',
      );
    }
    _token = token;
    _usesTokenAuth = data.containsKey('key') && !data.containsKey('access');
  }

  Future<Map<String, dynamic>> getProfile() async {
    final data = await _send('GET', profilePath, authenticated: true);
    final profile = data['user'] ?? data['profile'] ?? data;
    if (profile is! Map) {
      throw const AccountApiException('Format data profil dari server tidak valid.');
    }
    return Map<String, dynamic>.from(profile);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    final data = await _send(
      'PATCH',
      profilePath,
      authenticated: true,
      body: {'first_name': firstName, 'last_name': lastName},
    );
    final profile = data['user'] ?? data['profile'] ?? data;
    if (profile is! Map) {
      throw const AccountApiException('Format data profil dari server tidak valid.');
    }
    return Map<String, dynamic>.from(profile);
  }

  void logout() => _token = null;

  void close() => _client.close();

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    if (baseUrl.isEmpty) {
      throw const AccountApiException(
        'URL backend belum diatur. Jalankan app dengan --dart-define=API_BASE_URL=... ',
      );
    }
    if (authenticated && _token == null) {
      throw const AccountApiException('Silakan login kembali.');
    }

    final uri = Uri.parse(baseUrl).resolve(path);
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (authenticated) {
      headers['Authorization'] = '${_usesTokenAuth ? 'Token' : 'Bearer'} $_token';
    }
    final encodedBody = body == null ? null : jsonEncode(body);
    final response = switch (method) {
      'GET' => await _client.get(uri, headers: headers),
      'POST' => await _client.post(uri, headers: headers, body: encodedBody),
      'PATCH' => await _client.patch(uri, headers: headers, body: encodedBody),
      _ => throw ArgumentError.value(method, 'method', 'Unsupported HTTP method'),
    };
    final decoded = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AccountApiException(_errorMessage(decoded, response.statusCode));
    }
    return decoded;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.bodyBytes.isEmpty) return <String, dynamic>{};
    final body = utf8.decode(response.bodyBytes);
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return <String, dynamic>{'data': decoded};
    } on FormatException {
      throw const AccountApiException('Server mengirim respons yang bukan JSON.');
    }
  }

  String _errorMessage(Map<String, dynamic> data, int statusCode) {
    final detail = data['detail'] ?? data['message'] ?? data['non_field_errors'];
    if (detail is List) return detail.join('\n');
    if (detail is String) return detail;
    final fieldError = data.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n');
    return fieldError.isEmpty ? 'Request gagal ($statusCode).' : fieldError;
  }
}

class AccountApiException implements Exception {
  const AccountApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

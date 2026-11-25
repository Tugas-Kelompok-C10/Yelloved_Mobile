import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:yelloved_mobile/account_profile/account_models.dart';
import 'package:yelloved_mobile/core/api_config.dart';
import 'package:yelloved_mobile/core/app_session.dart';

/// Client for the DRF account endpoints in the Django `account_profile` app.
///
/// Configure with --dart-define=API_BASE_URL=http://... and override the
/// endpoint paths with API_REGISTER_PATH, API_LOGIN_PATH, and API_PROFILE_PATH
/// when the Django project uses different routes.
class AccountApi {
  AccountApi({
    required this.session,
    http.Client? client,
    this.baseUrl = ApiConfig.baseUrl,
  }) : _client = client ?? http.Client();

  static const _mobileRoot = '/account/api/mobile/';
  static const registerPath = String.fromEnvironment(
    'API_REGISTER_PATH',
    defaultValue: '${_mobileRoot}register/',
  );
  static const loginPath = String.fromEnvironment(
    'API_LOGIN_PATH',
    defaultValue: '${_mobileRoot}login/',
  );
  static const profilePath = String.fromEnvironment(
    'API_PROFILE_PATH',
    defaultValue: '${_mobileRoot}profile/',
  );
  static const logoutPath = String.fromEnvironment(
    'API_LOGOUT_PATH',
    defaultValue: '${_mobileRoot}logout/',
  );
  static const profilePhotoPath = '${_mobileRoot}profile/photo/';
  static const addressesPath = '${_mobileRoot}addresses/';
  static const paymentMethodsPath = '${_mobileRoot}payment-methods/';
  static const changePasswordPath = '${_mobileRoot}change-password/';

  final String baseUrl;
  final http.Client _client;
  final AppSession session;

  // ---------------------------------------------------------------- auth

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return _send(
      'POST',
      registerPath,
      body: {
        'first_name': name.trim(),
        'email': email.trim(),
        'password': password,
      },
    );
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
    session.signIn(
      token: token,
      usesTokenAuth:
          data.containsKey('token') ||
          (data.containsKey('key') && !data.containsKey('access')),
    );
  }

  Future<void> logout() async {
    try {
      if (session.isAuthenticated) {
        await _send('POST', logoutPath, authenticated: true);
      }
    } catch (_) {
      // Always clear the local session even if the network is unavailable.
    } finally {
      session.signOut();
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _send(
      'POST',
      changePasswordPath,
      authenticated: true,
      body: {
        'old_password': oldPassword,
        'new_password1': newPassword,
        'new_password2': confirmPassword,
      },
    );
  }

  // ------------------------------------------------------------- profile

  Future<Map<String, dynamic>> getProfile() async {
    final data = await _send('GET', profilePath, authenticated: true);
    return _storeProfile(data);
  }

  /// PATCHes only the fields that are given. Pass an empty string to clear
  /// [phoneNumber] or [gender]; use [clearDateOfBirth] to clear the date.
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
    DateTime? dateOfBirth,
    bool clearDateOfBirth = false,
    String? gender,
  }) async {
    final body = <String, dynamic>{
      'first_name': ?name?.trim(),
      'email': ?email?.trim(),
      'phone_number': ?phoneNumber?.trim(),
      'gender': ?gender,
      if (dateOfBirth != null) 'date_of_birth': formatDate(dateOfBirth),
      if (clearDateOfBirth && dateOfBirth == null) 'date_of_birth': null,
    };
    final data = await _send(
      'PATCH',
      profilePath,
      authenticated: true,
      body: body,
    );
    return _storeProfile(data);
  }

  Future<Map<String, dynamic>> uploadProfilePhoto({
    required List<int> bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest('POST', _uri(profilePhotoPath))
      ..files.add(
        http.MultipartFile.fromBytes('photo', bytes, filename: filename),
      );
    final data = await _dispatch(request, authenticated: true);
    // The photo endpoint returns a partial profile; merge it into the session
    // so fields such as `name` stay available.
    return _storeProfile({...?session.profile, ...data});
  }

  static String formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  // ----------------------------------------------------------- addresses

  Future<List<Address>> listAddresses() async {
    final data = await _send('GET', addressesPath, authenticated: true);
    return _results(data).map(Address.fromJson).toList();
  }

  Future<Address> createAddress(Address address) async {
    final data = await _send(
      'POST',
      addressesPath,
      authenticated: true,
      body: address.toJson(),
    );
    return Address.fromJson(data);
  }

  Future<Address> updateAddress(int id, Address address) async {
    final data = await _send(
      'PATCH',
      '$addressesPath$id/',
      authenticated: true,
      body: address.toJson(),
    );
    return Address.fromJson(data);
  }

  Future<void> deleteAddress(int id) =>
      _send('DELETE', '$addressesPath$id/', authenticated: true);

  Future<Address> setDefaultAddress(int id) async {
    final data = await _send(
      'POST',
      '$addressesPath$id/default/',
      authenticated: true,
    );
    return Address.fromJson(data);
  }

  // ----------------------------------------------------- payment methods

  Future<List<PaymentMethod>> listPaymentMethods() async {
    final data = await _send('GET', paymentMethodsPath, authenticated: true);
    return _results(data).map(PaymentMethod.fromJson).toList();
  }

  Future<PaymentMethod> createPaymentMethod(PaymentMethod method) async {
    final data = await _send(
      'POST',
      paymentMethodsPath,
      authenticated: true,
      body: method.toJson(),
    );
    return PaymentMethod.fromJson(data);
  }

  /// [fields] holds only what changed, so the masked identifier the server
  /// returned is never sent back as the real account number.
  Future<PaymentMethod> updatePaymentMethod(
    int id,
    Map<String, dynamic> fields,
  ) async {
    final data = await _send(
      'PATCH',
      '$paymentMethodsPath$id/',
      authenticated: true,
      body: fields,
    );
    return PaymentMethod.fromJson(data);
  }

  Future<void> deletePaymentMethod(int id) =>
      _send('DELETE', '$paymentMethodsPath$id/', authenticated: true);

  void close() => _client.close();

  // ------------------------------------------------------------ plumbing

  Map<String, dynamic> _storeProfile(Map<String, dynamic> data) {
    final profile = data['user'] ?? data['profile'] ?? data;
    if (profile is! Map) {
      throw const AccountApiException(
        'Format data profil dari server tidak valid.',
      );
    }
    final result = Map<String, dynamic>.from(profile);
    session.updateProfile(result);
    return result;
  }

  List<Map<String, dynamic>> _results(Map<String, dynamic> data) {
    final results = data['results'] ?? data['data'];
    if (results is! List) {
      throw const AccountApiException('Format daftar dari server tidak valid.');
    }
    return results
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Uri _uri(String path) {
    if (baseUrl.isEmpty) {
      throw const AccountApiException(
        'URL backend belum diatur. Jalankan app dengan --dart-define=API_BASE_URL=... ',
      );
    }
    return Uri.parse(baseUrl).resolve(path);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    final request = http.Request(method, _uri(path));
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    return _dispatch(request, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> _dispatch(
    http.BaseRequest request, {
    required bool authenticated,
  }) async {
    request.headers['Accept'] = 'application/json';
    if (authenticated) {
      final authorization = session.authorizationHeader;
      if (authorization == null) {
        throw const AccountApiException('Silakan login kembali.');
      }
      request.headers['Authorization'] = authorization;
    }
    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    if (response.statusCode == 401 && authenticated) {
      session.signOut();
      throw const AccountApiException('Sesi berakhir. Silakan login kembali.');
    }
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
      throw AccountApiException(
        'Server mengirim respons yang bukan JSON (${response.statusCode}).',
      );
    }
  }

  /// Handles both DRF errors (`{"detail": ...}` / `{"field": [...]}`) and the
  /// legacy account handlers (`{"error": ...}` / `{"errors": {...}}`).
  static String _errorMessage(Map<String, dynamic> data, int statusCode) {
    final detail =
        data['detail'] ??
        data['error'] ??
        data['message'] ??
        data['non_field_errors'];
    if (detail is List) return detail.join('\n');
    if (detail is String) return detail;
    final errors = data['errors'] is Map
        ? Map<String, dynamic>.from(data['errors'] as Map)
        : data;
    final lines = errors.entries.map((entry) {
      final value = entry.value;
      final message = value is List ? value.join(' ') : '$value';
      return entry.key == '__all__' || entry.key == 'non_field_errors'
          ? message
          : '${_fieldLabel(entry.key)}: $message';
    });
    final text = lines.join('\n');
    return text.isEmpty ? 'Request gagal ($statusCode).' : text;
  }

  static String _fieldLabel(String key) {
    final words = key.replaceAll(RegExp(r'\d+$'), '').split('_');
    final label = words.where((word) => word.isNotEmpty).join(' ');
    return label.isEmpty
        ? key
        : '${label[0].toUpperCase()}${label.substring(1)}';
  }
}

class AccountApiException implements Exception {
  const AccountApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

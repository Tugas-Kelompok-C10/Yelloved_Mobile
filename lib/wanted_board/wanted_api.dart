import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:yelloved_mobile/core/api_config.dart';

import 'wanted_post.dart';

/// No request runs until a method is called. This class is not wired to a page.
/// Wanted uses Django sessions, not the Bearer/Token auth in AccountApi.
/// Native: supply the sessionId from login through setSession().
/// Web: inject a shared BrowserClient with withCredentials = true. The browser
/// manages cookies; cross-origin access still needs backend CORS/CSRF setup.
class WantedApi {
  WantedApi({
    http.Client? client,
    String baseUrl = ApiConfig.baseUrl,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _baseUri = Uri.parse(baseUrl);

  static const _path = '/wanted-post/api/';
  final http.Client _client;
  final bool _ownsClient;
  final Uri _baseUri;
  final Duration timeout;
  String? _sessionId;
  String? _csrfToken;
  String? _csrfCookie;

  /// In-memory credentials only. Call again after changing account/login.
  void setSession({required String sessionId, String? csrfToken}) {
    _sessionId = sessionId;
    _csrfToken = csrfToken;
    _csrfCookie = csrfToken;
  }

  void clearSession() {
    _sessionId = null;
    _csrfToken = null;
    _csrfCookie = null;
  }

  Future<List<WantedPost>> fetchWantedPosts({
    String search = '',
    String category = '',
    String sort = '',
    bool mine = false,
    String? status,
  }) async {
    final data = await _request(
      'GET',
      _path,
      query: _filters(
        search: search,
        category: category,
        sort: sort,
        mine: mine,
        status: status,
      ),
    );
    return (data as List)
        .map((item) => WantedPost.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<WantedPostPage> fetchWantedPage({
    int page = 1,
    String search = '',
    String category = '',
    String sort = '',
    bool mine = false,
    String? status,
  }) async {
    final query = _filters(
      search: search,
      category: category,
      sort: sort,
      mine: mine,
      status: status,
    );
    query['page'] = page.toString();
    final data = await _request('GET', _path, query: query);
    return WantedPostPage.fromJson(data as Map<String, dynamic>);
  }

  Future<WantedPost> fetchWantedDetail(String id) async {
    final data = await _request('GET', _detailPath(id));
    return WantedPost.fromJson(data as Map<String, dynamic>);
  }

  /// Requires login. Stores CSRF for subsequent writes, but does not auto-submit.
  Future<WantedCreateOptions> fetchCreateOptions() async {
    final data = await _request('GET', '${_path}create-options/');
    final options = WantedCreateOptions.fromJson(data as Map<String, dynamic>);
    _csrfToken = options.csrfToken;
    return options;
  }

  Future<WantedPost> createWanted({
    required String creationToken,
    required String title,
    required String description,
    required String budget,
    String category = 'other',
    String location = '',
  }) async {
    final data = await _request(
      'POST',
      _path,
      body: {
        'creation_token': creationToken,
        'title': title,
        'description': description,
        'budget': budget,
        'category': category,
        'location': location,
      },
    );
    return WantedPost.fromJson(data as Map<String, dynamic>);
  }

  /// PATCH: only send fields that changed. Use the latest post.updatedAt.
  Future<WantedPost> updateWanted(
    String id, {
    required DateTime revision,
    String? title,
    String? description,
    String? budget,
    String? category,
    String? location,
  }) async {
    final body = <String, dynamic>{'revision': revision.toIso8601String()};
    if (title != null) {
      body['title'] = title;
    }
    if (description != null) {
      body['description'] = description;
    }
    if (budget != null) {
      body['budget'] = budget;
    }
    if (category != null) {
      body['category'] = category;
    }
    if (location != null) {
      body['location'] = location;
    }
    final data = await _request('PATCH', _detailPath(id), body: body);
    return WantedPost.fromJson(data as Map<String, dynamic>);
  }

  /// PUT: send the complete editable form.
  Future<WantedPost> replaceWanted(
    String id, {
    required DateTime revision,
    required String title,
    required String description,
    required String budget,
    String category = 'other',
    String location = '',
  }) async {
    final data = await _request(
      'PUT',
      _detailPath(id),
      body: {
        'revision': revision.toIso8601String(),
        'title': title,
        'description': description,
        'budget': budget,
        'category': category,
        'location': location,
      },
    );
    return WantedPost.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteWanted(String id) async {
    await _request('DELETE', _detailPath(id));
  }

  Future<WantedPost> updateWantedStatus(
    String id, {
    required String status,
    required DateTime revision,
  }) async {
    final data = await _request(
      'POST',
      '${_detailPath(id)}status/',
      body: {'status': status, 'revision': revision.toIso8601String()},
    );
    return WantedPost.fromJson(data as Map<String, dynamic>);
  }

  // An injected client may be shared with login/other modules: caller closes it.
  void close() {
    if (_ownsClient) _client.close();
  }

  String _detailPath(String id) => '$_path${Uri.encodeComponent(id)}/';

  Map<String, String> _filters({
    required String search,
    required String category,
    required String sort,
    required bool mine,
    required String? status,
  }) {
    return {
      if (search.isNotEmpty) 'search': search,
      if (category.isNotEmpty) 'category': category,
      if (sort.isNotEmpty) 'sort': sort,
      if (mine) 'mine': 'true',
      if (status != null && status.isNotEmpty) 'status': status,
    };
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = _baseUri.resolve(path).replace(queryParameters: query);
    final request = http.Request(method, uri);
    request.headers['Accept'] = 'application/json';
    if (!kIsWeb) {
      final cookies = [
        if (_sessionId != null) 'sessionid=$_sessionId',
        if (_csrfCookie != null) 'csrftoken=$_csrfCookie',
      ];
      if (cookies.isNotEmpty) request.headers['Cookie'] = cookies.join('; ');
    }
    if (method != 'GET' && method != 'HEAD') {
      if (_csrfToken == null) {
        throw const WantedApiException(
          'Login lalu ambil create-options untuk token CSRF.',
        );
      }
      request.headers['X-CSRFToken'] = _csrfToken!;
      // Django requires a matching Referer on HTTPS session requests.
      // Browsers supply their own Origin/Referer; do not override those on web.
      if (!kIsWeb) {
        request.headers['Referer'] = '${_baseUri.origin}/';
      }
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    late http.Response response;
    try {
      final streamed = await _client.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed).timeout(timeout);
    } on TimeoutException {
      throw const WantedApiException(
        'Request timeout. Coba lagi dengan token form yang sama.',
      );
    } on http.ClientException {
      throw const WantedApiException('Tidak dapat terhubung ke server.');
    }

    if (!kIsWeb) {
      final cookie = RegExp(r'(?:^|,\s*)csrftoken=([^;,\s]+)')
          .firstMatch(response.headers['set-cookie'] ?? '');
      if (cookie != null) _csrfCookie = cookie.group(1);
    }
    // DELETE returns 204 with no JSON body.
    if (response.statusCode == 204) return null;
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw WantedApiException(
        'Server tidak mengirim JSON.',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final headerRetry = int.tryParse(response.headers['retry-after'] ?? '');
      throw WantedApiException(
        _errorMessage(data, response.statusCode),
        statusCode: response.statusCode,
        errors: data,
        retryAfter:
            headerRetry ??
            (data is Map ? int.tryParse('${data['retry_after']}') : null),
      );
    }
    return data;
  }

  String _errorMessage(dynamic data, int code) {
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List) return detail.join('\n');
      return data.entries
          .map((entry) {
            final value = entry.value;
            return '${entry.key}: ${value is List ? value.join(', ') : value}';
          })
          .join('\n');
    }
    return 'Request gagal ($code).';
  }
}

class WantedApiException implements Exception {
  const WantedApiException(
    this.message, {
    this.statusCode,
    this.errors,
    this.retryAfter,
  });

  final String message;
  final int? statusCode;
  final Object? errors;
  final int? retryAfter;

  @override
  String toString() => message;
}

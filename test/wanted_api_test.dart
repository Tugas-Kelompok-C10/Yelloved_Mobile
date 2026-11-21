import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yelloved_mobile/wanted_board/wanted_api.dart';
import 'package:yelloved_mobile/wanted_board/wanted_post.dart';

const postId = '10761a89-7d9e-4e49-8506-c1e741add417';

Map<String, dynamic> postJson() => {
  'id': postId,
  'title': 'Buku kuliah — bekas',
  'description': 'Untuk belajar',
  'category': 'books',
  'budget': '1234567890.01',
  'location': 'Kukusan',
  'requester': 1,
  'requester_username': 'Cindy',
  'status': 'open',
  'created_at': '2026-11-21T10:00:00.123456+07:00',
  'updated_at': '2026-11-21T11:00:00.654321+07:00',
};

http.Response jsonResponse(
  Object data, [
  int code = 200,
  Map<String, String>? headers,
]) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(data)),
    code,
    headers: {'content-type': 'application/json', ...?headers},
  );
}

void main() {
  test(
    'Model preserves decimal strings, null budgets, and revision precision',
    () {
      final post = WantedPost.fromJson(postJson());
      expect(post.budget, '1234567890.01');
      expect(post.updatedAt.microsecond, 321);
      expect(post.updatedAt.toIso8601String(), '2026-11-21T04:00:00.654321Z');
      expect(
        WantedPost.fromJson({...postJson(), 'budget': null}).budget,
        isNull,
      );
    },
  );

  test(
    'Constructing API makes no requests; list supports UTF-8 and filters',
    () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        expect(request.method, 'GET');
        expect(request.url.origin, 'https://example.com');
        expect(request.url.path, '/wanted-post/api/');
        expect(request.url.queryParameters, {
          'search': 'buku & study',
          'category': 'books',
          'sort': 'budget_asc',
          'mine': 'true',
          'status': 'closed',
        });
        expect(request.headers['Accept'], 'application/json');
        return jsonResponse([postJson()]);
      });
      final api = WantedApi(client: client, baseUrl: 'https://example.com');
      addTearDown(client.close);
      expect(calls, 0);
      final posts = await api.fetchWantedPosts(
        search: 'buku & study',
        category: 'books',
        sort: 'budget_asc',
        mine: true,
        status: 'closed',
      );
      expect(posts.single.title, 'Buku kuliah — bekas');
      expect(calls, 1);
    },
  );

  test('Pagination and public detail use their own response shapes', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('$postId/')) {
        return jsonResponse(postJson());
      }
      expect(request.url.queryParameters['page'], '2');
      return jsonResponse({
        'count': 13,
        'next': null,
        'previous': 'https://example.com/wanted-post/api/?page=1',
        'results': [postJson()],
      });
    });
    addTearDown(client.close);
    final api = WantedApi(client: client, baseUrl: 'https://example.com');
    final page = await api.fetchWantedPage(page: 2);
    expect(page.count, 13);
    expect(page.next, isNull);
    expect(page.previous, contains('page=1'));
    expect(page.results.single.id, postId);
    expect((await api.fetchWantedDetail(postId)).id, postId);
  });

  test('Create options bootstrap CSRF; all writes carry session and correct data', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      expect(request.headers['Cookie'], contains('sessionid=session-secret'));
      if (request.method == 'GET') {
        return jsonResponse(
          {
            'creation_token': 'signed-create-token',
            'csrf_token': 'masked-csrf-token',
            'categories': [
              {'value': 'books', 'label': 'Books & Study'},
            ],
          },
          200,
          {'set-cookie': 'csrftoken=cookie-secret; Path=/; SameSite=Lax'},
        );
      }
      expect(request.headers['Cookie'], contains('csrftoken=cookie-secret'));
      expect(request.headers['X-CSRFToken'], 'masked-csrf-token');
      expect(request.headers['Referer'], 'https://example.com/');
      expect(request.headers['Authorization'], isNull);
      if (request.method == 'DELETE') return http.Response('', 204);
      expect(request.headers['Content-Type'], 'application/json');
      return jsonResponse(
        postJson(),
        request.url.path == '/wanted-post/api/' ? 201 : 200,
      );
    });
    addTearDown(client.close);
    final api = WantedApi(client: client, baseUrl: 'https://example.com');
    api.setSession(sessionId: 'session-secret');
    final options = await api.fetchCreateOptions();
    expect(options.categories.single.label, 'Books & Study');
    final post = await api.createWanted(
      creationToken: options.creationToken,
      title: 'Buku',
      description: 'For class',
      budget: '1234567890.01',
      category: 'books',
    );
    // Retrying keeps the caller's signed token instead of generating a new one.
    await api.createWanted(
      creationToken: options.creationToken,
      title: 'Buku',
      description: 'For class',
      budget: '1234567890.01',
      category: 'books',
    );
    expect(
      jsonDecode(requests[1].body)['creation_token'],
      'signed-create-token',
    );
    expect(
      jsonDecode(requests[2].body)['creation_token'],
      'signed-create-token',
    );
    await api.updateWanted(post.id, revision: post.updatedAt, title: 'Updated');
    expect(jsonDecode(requests.last.body), {
      'revision': '2026-11-21T04:00:00.654321Z',
      'title': 'Updated',
    });
    await api.replaceWanted(
      post.id,
      revision: post.updatedAt,
      title: 'Replacement',
      description: 'Complete form',
      budget: '9000.00',
    );
    expect(requests.last.method, 'PUT');
    expect(jsonDecode(requests.last.body)['description'], 'Complete form');
    await api.updateWantedStatus(
      post.id,
      status: 'closed',
      revision: post.updatedAt,
    );
    expect(requests.last.url.path, '/wanted-post/api/$postId/status/');
    expect(jsonDecode(requests.last.body)['status'], 'closed');
    await api.deleteWanted(post.id);
    expect(requests.last.method, 'DELETE');
    expect(requests.last.url.path, '/wanted-post/api/$postId/');
  });

  test(
    'No CSRF prevents writes; clearing session removes stored credentials',
    () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        expect(request.headers['Cookie'], isNull);
        expect(request.headers['X-CSRFToken'], isNull);
        return jsonResponse([]);
      });
      addTearDown(client.close);
      final api = WantedApi(client: client);
      await expectLater(
        api.deleteWanted(postId),
        throwsA(isA<WantedApiException>()),
      );
      expect(calls, 0);
      api.setSession(sessionId: 'old-session', csrfToken: 'old-csrf');
      api.clearSession();
      await api.fetchWantedPosts();
      await expectLater(
        api.deleteWanted(postId),
        throwsA(isA<WantedApiException>()),
      );
      expect(calls, 1);
    },
  );

  test('Field validation, permission, missing data, conflicts and quota stay readable', () async {
    for (final code in [400, 403, 404, 409, 429]) {
      final errors = code == 400
          ? {
              'budget': ['Must be greater than zero.'],
            }
          : {'detail': 'Request rejected', if (code == 429) 'retry_after': 60};
      final client = MockClient(
        (_) async => jsonResponse(
          errors,
          code,
          code == 429 ? {'retry-after': '60'} : null,
        ),
      );
      final api = WantedApi(client: client);
      try {
        await api.fetchWantedDetail(postId);
        fail('Expected API error');
      } on WantedApiException catch (error) {
        expect(error.statusCode, code);
        expect(error.errors, errors);
        expect(
          error.message,
          code == 400 ? contains('budget') : 'Request rejected',
        );
        expect(error.retryAfter, code == 429 ? 60 : isNull);
      } finally {
        client.close();
      }
    }
  });

  test(
    'HTML errors and transport failures become WantedApiException',
    () async {
      final htmlClient = MockClient(
        (_) async => http.Response('<h1>Server Error</h1>', 500),
      );
      final htmlApi = WantedApi(client: htmlClient);
      await expectLater(
        htmlApi.fetchWantedPosts(),
        throwsA(
          isA<WantedApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
      htmlClient.close();
      final brokenClient = MockClient(
        (_) async => throw http.ClientException('offline'),
      );
      await expectLater(
        WantedApi(client: brokenClient).fetchWantedPosts(),
        throwsA(isA<WantedApiException>()),
      );
      brokenClient.close();
      final slowClient = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return jsonResponse([]);
      });
      await expectLater(
        WantedApi(
          client: slowClient,
          timeout: const Duration(milliseconds: 1),
        ).fetchWantedPosts(),
        throwsA(isA<WantedApiException>()),
      );
      slowClient.close();
    },
  );
}

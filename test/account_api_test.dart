import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yelloved_mobile/account_profile/account_api.dart';
import 'package:yelloved_mobile/account_profile/account_models.dart';
import 'package:yelloved_mobile/core/app_session.dart';

const base = 'https://example.test';

http.Response json(Object? data, [int code = 200]) => http.Response.bytes(
  data == null ? const [] : utf8.encode(jsonEncode(data)),
  code,
  headers: {'content-type': 'application/json'},
);

AppSession signedIn() =>
    AppSession()..signIn(token: 'abc123', usesTokenAuth: true);

void main() {
  late List<http.Request> requests;

  AccountApi apiFor(
    AppSession session,
    http.Response Function(http.Request request) handler,
  ) {
    requests = [];
    return AccountApi(
      session: session,
      baseUrl: base,
      client: MockClient((request) async {
        requests.add(request);
        return handler(request);
      }),
    );
  }

  test('login stores the DRF token and sends it as "Token <key>"', () async {
    final session = AppSession();
    final api = apiFor(session, (request) {
      if (request.url.path.endsWith('/login/')) {
        return json({'token': 'k1', 'user': {}});
      }
      return json({'id': 1, 'name': 'Adib', 'email': 'a@ui.ac.id'});
    });

    await api.login(email: ' a@ui.ac.id ', password: 'secret123');
    final profile = await api.getProfile();

    expect(jsonDecode(requests.first.body), {
      'email': 'a@ui.ac.id',
      'password': 'secret123',
    });
    expect(requests.last.headers['Authorization'], 'Token k1');
    expect(profile['name'], 'Adib');
    expect(session.profile?['email'], 'a@ui.ac.id');
  });

  test('updateProfile PATCHes only given fields with ISO date', () async {
    final api = apiFor(signedIn(), (_) => json({'name': 'Adib'}));

    await api.updateProfile(
      name: ' Adib Islami ',
      phoneNumber: '0812',
      dateOfBirth: DateTime(2004, 3, 7),
    );

    final request = requests.single;
    expect(request.method, 'PATCH');
    expect(request.url.path, '/account/api/mobile/profile/');
    expect(jsonDecode(request.body), {
      'first_name': 'Adib Islami',
      'phone_number': '0812',
      'date_of_birth': '2004-03-07',
    });
  });

  test('clearDateOfBirth sends an explicit null', () async {
    final api = apiFor(signedIn(), (_) => json({}));
    await api.updateProfile(clearDateOfBirth: true);
    expect(jsonDecode(requests.single.body), {'date_of_birth': null});
  });

  test('address CRUD hits the mobile endpoints', () async {
    final address = {
      'id': 4,
      'label': 'Kos',
      'recipient_name': 'Adib',
      'phone_number': '0812',
      'street_address': 'Jl. Margonda',
      'city': 'Depok',
      'province': 'Jawa Barat',
      'postal_code': '16424',
      'is_default': true,
    };
    final api = apiFor(signedIn(), (request) {
      return switch (request.method) {
        'GET' => json({
          'results': [address],
        }),
        'DELETE' => json({'deleted': true}),
        _ => json(address, request.method == 'POST' ? 201 : 200),
      };
    });

    final list = await api.listAddresses();
    expect(list.single.label, 'Kos');
    expect(list.single.isDefault, isTrue);
    expect(list.single.summary, 'Jl. Margonda, Depok, Jawa Barat, 16424');

    await api.createAddress(Address.fromJson(address));
    await api.updateAddress(4, Address.fromJson(address));
    await api.setDefaultAddress(4);
    await api.deleteAddress(4);

    expect(requests.map((r) => '${r.method} ${r.url.path}').toList(), [
      'GET /account/api/mobile/addresses/',
      'POST /account/api/mobile/addresses/',
      'PATCH /account/api/mobile/addresses/4/',
      'POST /account/api/mobile/addresses/4/default/',
      'DELETE /account/api/mobile/addresses/4/',
    ]);
    expect(jsonDecode(requests[1].body)['recipient_name'], 'Adib');
  });

  test('payment method update sends only the changed fields', () async {
    final api = apiFor(
      signedIn(),
      (_) => json({
        'id': 2,
        'method_type': 'e_wallet',
        'provider': 'GoPay',
        'account_name': 'Adib',
        'account_identifier': '•••• 7890',
        'is_default': true,
      }),
    );

    final method = await api.updatePaymentMethod(2, {'is_default': true});

    expect(requests.single.url.path, '/account/api/mobile/payment-methods/2/');
    expect(jsonDecode(requests.single.body), {'is_default': true});
    expect(method.typeLabel, 'E-wallet');
  });

  test('change password uses Django PasswordChangeForm field names', () async {
    final api = apiFor(signedIn(), (_) => json({'message': 'ok'}));
    await api.changePassword(
      oldPassword: 'old',
      newPassword: 'newpass123',
      confirmPassword: 'newpass123',
    );
    expect(jsonDecode(requests.single.body), {
      'old_password': 'old',
      'new_password1': 'newpass123',
      'new_password2': 'newpass123',
    });
  });

  test('legacy {"errors": {...}} responses become readable messages', () async {
    final api = apiFor(
      signedIn(),
      (_) => json({
        'errors': {
          'old_password': ['Your old password was entered incorrectly.'],
          'new_password2': ['The two password fields didn’t match.'],
        },
      }, 400),
    );

    await expectLater(
      api.changePassword(
        oldPassword: 'x',
        newPassword: 'y',
        confirmPassword: 'z',
      ),
      throwsA(
        isA<AccountApiException>().having(
          (e) => e.message,
          'message',
          'Old password: Your old password was entered incorrectly.\n'
              'New password: The two password fields didn’t match.',
        ),
      ),
    );
  });

  test('a 401 on an authenticated call signs the user out', () async {
    final session = signedIn();
    final api = apiFor(session, (_) => json({'detail': 'Invalid token.'}, 401));

    await expectLater(api.getProfile(), throwsA(isA<AccountApiException>()));
    expect(session.isAuthenticated, isFalse);
  });

  test('photo upload is multipart and keeps existing profile fields', () async {
    final session = signedIn()..updateProfile({'name': 'Adib', 'photo': null});
    late String contentType;
    final api = AccountApi(
      session: session,
      baseUrl: base,
      client: MockClient((request) async {
        contentType = request.headers['content-type']!;
        expect(request.url.path, '/account/api/mobile/profile/photo/');
        expect(request.headers['Authorization'], 'Token abc123');
        return json({'photo': '$base/media/p.jpg'});
      }),
    );

    final profile = await api.uploadProfilePhoto(
      bytes: [1, 2, 3],
      filename: 'p.jpg',
    );

    expect(contentType, startsWith('multipart/form-data'));
    expect(profile, {'name': 'Adib', 'photo': '$base/media/p.jpg'});
  });
}

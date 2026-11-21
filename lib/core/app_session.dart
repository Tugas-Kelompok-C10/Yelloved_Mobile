import 'package:flutter/widgets.dart';

class AppSession extends ChangeNotifier {
  String? _token;
  bool _usesTokenAuth = false;
  Map<String, dynamic>? _profile;

  bool get isAuthenticated => _token != null;
  Map<String, dynamic>? get profile => _profile;

  String? get authorizationHeader {
    final token = _token;
    if (token == null) return null;
    return '${_usesTokenAuth ? 'Token' : 'Bearer'} $token';
  }

  void signIn({required String token, required bool usesTokenAuth}) {
    _token = token;
    _usesTokenAuth = usesTokenAuth;
    notifyListeners();
  }

  void updateProfile(Map<String, dynamic> profile) {
    _profile = Map<String, dynamic>.unmodifiable(profile);
    notifyListeners();
  }

  void signOut() {
    _token = null;
    _usesTokenAuth = false;
    _profile = null;
    notifyListeners();
  }
}

class AppSessionScope extends InheritedNotifier<AppSession> {
  const AppSessionScope({
    super.key,
    required AppSession session,
    required super.child,
  }) : super(notifier: session);

  static AppSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSessionScope>();
    assert(scope != null, 'AppSessionScope is missing above this context.');
    return scope!.notifier!;
  }
}

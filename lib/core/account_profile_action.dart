import 'package:flutter/material.dart';
import 'package:yelloved_mobile/core/app_session.dart';

class AccountProfileAction extends StatelessWidget {
  const AccountProfileAction({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);
    final name = session.profile?['name']?.toString();
    return IconButton(
      tooltip: session.isAuthenticated && name != null ? name : 'Account',
      onPressed: () => Navigator.pushNamed(context, '/account'),
      icon: Icon(
        session.isAuthenticated ? Icons.account_circle : Icons.person_outline,
      ),
    );
  }
}

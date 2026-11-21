import 'package:flutter/material.dart';

import 'account_profile/account_profile_page.dart';
import 'core/app_session.dart';
import 'menu.dart';

void main() {
  runApp(AppSessionScope(session: AppSession(), child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yelloved',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      routes: {'/account': (_) => const AccountProfilePage()},
      home: const MyHomePage(title: 'Yelloved'),
    );
  }
}

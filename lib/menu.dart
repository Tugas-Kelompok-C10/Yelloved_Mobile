import 'package:flutter/material.dart';
import 'package:yelloved_mobile/account_profile/account_profile_page.dart';
import 'package:yelloved_mobile/wanted_board/wanted_board_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text(
              'Give good things another love.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WantedBoardPage(),
                  ),
                );
              },
              icon: const Icon(Icons.push_pin_outlined),
              label: const Text('Wanted Board'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountProfilePage(),
                  ),
                );
              },
              icon: const Icon(Icons.person_outline),
              label: const Text('Account & Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

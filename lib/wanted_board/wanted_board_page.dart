import 'package:flutter/material.dart';
import 'package:yelloved_mobile/core/account_profile_action.dart';

class WantedBoardPage extends StatelessWidget {
  const WantedBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wanted Board'),
        actions: const [AccountProfileAction()],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Looking for something?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Post what you need and let the community help you find it.'),
            SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: Icon(Icons.push_pin_outlined),
                title: Text('Scientific calculator'),
                subtitle: Text(
                  'Maximum budget: Rp150.000\nLocation: UI Campus',
                ),
                isThreeLine: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

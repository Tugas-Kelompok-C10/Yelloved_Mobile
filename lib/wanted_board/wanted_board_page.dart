import 'package:flutter/material.dart';
import 'package:yelloved_mobile/widgets/top_nav.dart';

class WantedBoardPage extends StatelessWidget {
  const WantedBoardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const CustomTopNav(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Looking for something?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Post what you need and let the community help you find it.'),
                  const SizedBox(height: 24),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.push_pin_outlined),
                      title: const Text('Scientific calculator'),
                      subtitle: const Text(
                        'Maximum budget: Rp150.000\nLocation: UI Campus',
                      ),
                      isThreeLine: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
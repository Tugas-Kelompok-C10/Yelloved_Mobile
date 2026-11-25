import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Messages',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Chat with buyers or sellers regarding your items and wanted posts.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                title: const Text('Jane Doe'),
                subtitle: const Text('Halo, apakah barangnya masih ada?'),
                trailing: const Text(
                  '12:45',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
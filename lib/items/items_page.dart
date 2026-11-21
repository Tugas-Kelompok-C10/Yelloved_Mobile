import 'package:flutter/material.dart';
import 'package:yelloved_mobile/core/account_profile_action.dart';

class ItemsPage extends StatelessWidget {
  const ItemsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My items'),
      actions: const [AccountProfileAction()],
    ),
    body: const Center(child: Text('Your posted items will appear here.')),
  );
}

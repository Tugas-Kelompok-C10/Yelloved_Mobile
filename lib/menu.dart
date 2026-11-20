import 'package:flutter/material.dart';

import 'package:yelloved_mobile/account_profile/account_profile_page.dart';
import 'package:yelloved_mobile/items/items_page.dart';
import 'package:yelloved_mobile/transactions/transaction_page.dart';
import 'package:yelloved_mobile/wanted_board/wanted_board_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  void _selectTab(int index) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: Text(widget.title),
            )
          : null,
      // Keep each page mounted so switching tabs preserves its form/scroll state.
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHome(),
          const ItemsPage(),
          const WantedBoardPage(),
          const AccountProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Catalogue',
          ),
          NavigationDestination(
            icon: Icon(Icons.push_pin_outlined),
            selectedIcon: Icon(Icons.push_pin),
            label: 'Wanted Board',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Give good things another love.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _selectTab(2),
              icon: const Icon(Icons.push_pin_outlined),
              label: const Text('Wanted Board'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _selectTab(1),
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Catalogue'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _selectTab(3),
              icon: const Icon(Icons.person_outline),
              label: const Text('Account & Profile'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionPage(),
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text('My Transactions'),
            ),
          ],
        ),
      ),
    );
  }
}

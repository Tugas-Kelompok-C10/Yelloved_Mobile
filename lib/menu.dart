import 'package:flutter/material.dart';

import 'package:yelloved_mobile/account_profile/account_profile_page.dart';
import 'package:yelloved_mobile/core/app_session.dart';
import 'package:yelloved_mobile/items/items_page.dart';
import 'package:yelloved_mobile/wanted_board/wanted_board_page.dart';
import 'package:yelloved_mobile/transactions/transaction_page.dart';
import 'package:yelloved_mobile/theme/app_colors.dart';
import 'package:yelloved_mobile/wanted_board/wanted_board_page.dart';
import 'package:yelloved_mobile/item_matching/item_matching.dart';

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
    final session = AppSessionScope.of(context);
    final profile = session.profile ?? const <String, dynamic>{};
    final fallbackName =
        '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
    final accountName = profile['name']?.toString() ?? fallbackName;
    return Scaffold(
      appBar: _selectedIndex == 0 ? AppBar(title: Text(widget.title)) : null,
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
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.gradient),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _selectTab,
          destinations: [
            const NavigationDestination(
              icon: Icon(CupertinoIcons.house, size: 24),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(CupertinoIcons.square_list, size: 24),
              label: 'Catalogue',
            ),
            NavigationDestination(
              icon: Transform.rotate(
                angle: 0.65,
                child: const Icon(CupertinoIcons.pin, size: 24),
              ),
              label: 'Wanted Board',
            ),
            NavigationDestination(
              icon: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.text, width: 1.5),
                ),
                child: const Text(
                  'U',
                  style: TextStyle(
                    color: AppColors.violet,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              label: 'Profile',
            ),
          ],
        ),
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

            if (session.isAuthenticated) ...[
              Text('Signed in${accountName.isEmpty ? '' : ' as $accountName'}'),
              const SizedBox(height: 16),
            ],

            // Wanted Board
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

            const SizedBox(height: 12),

            // item-matching
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MatchingPage(),
                  ),
                );
              },
              icon: const Icon(Icons.punch_clock),
              label: const Text('Item Matching'),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ItemsPage()),
                );
              },
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Items'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:yelloved_mobile/theme/app_colors.dart';

import 'package:yelloved_mobile/chat/chat_page.dart';
import 'package:yelloved_mobile/transactions/transaction_page.dart';

class CustomTopNav extends StatelessWidget {
  final VoidCallback? onCartTap;
  final VoidCallback? onSearchTap;

  const CustomTopNav({
    super.key,
    this.onCartTap,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.violet,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          // Karena bagian kiri kosong, kita set rata kanan (end)
          mainAxisAlignment: MainAxisAlignment.end, 
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.search),
                  color: AppColors.text,
                  onPressed: onSearchTap ?? () {
                    // Aksi default kalau tidak di-override
                  },
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.cart),
                  color: AppColors.text,
                  onPressed: onCartTap ?? () {
                    // Aksi default
                  },
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.time),
                  color: AppColors.text,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransactionPage(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.forum_outlined),
                  color: AppColors.text,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatPage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
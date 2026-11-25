import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/account_profile_action.dart';
import '../core/api_config.dart';
import '../core/app_session.dart';
import '../models/transaction.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  static const _baseUrl = ApiConfig.baseUrl;
  static const _transactionsPath = String.fromEnvironment(
    'API_TRANSACTIONS_PATH',
    defaultValue: '/transactions/api/',
  );

  Future<List<Transaction>> fetchTransactions(AppSession session) async {
    if (_baseUrl.isEmpty) {
      throw Exception('Atur URL backend dengan --dart-define=API_BASE_URL=...');
    }
    final url = Uri.parse(_baseUrl).resolve(_transactionsPath);

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        if (session.authorizationHeader != null)
          'Authorization': session.authorizationHeader!,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((json) => Transaction.fromJson(json)).toList();
    } else if (response.statusCode == 403) {
      throw Exception('Akses ditolak. Pengguna belum terautentikasi.');
    } else {
      throw Exception('Gagal mengambil transaksi: ${response.statusCode}');
    }
  }

  String formatRupiah(double amount) {
    return 'Rp${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Transactions'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: const [AccountProfileAction()],
      ),
      body: !session.isAuthenticated
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Sign in to view your transactions.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/account').then((_) {
                            if (mounted) setState(() {});
                          }),
                      child: const Text('Go to account'),
                    ),
                  ],
                ),
              ),
            )
          : FutureBuilder<List<Transaction>>(
              future: fetchTransactions(session),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final transactions = snapshot.data ?? [];

                if (transactions.isEmpty) {
                  return const Center(child: Text('Belum ada transaksi.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];

                    return transactionCard(transaction);
                  },
                );
              },
            ),
    );
  }

  Widget transactionCard(Transaction transaction) {
    final isCompleted =
        transaction.transactionStatus.toLowerCase() == 'completed';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction.itemName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Transaction ID: ${transaction.orderId}'),
            Text('Quantity: ${transaction.quantity}'),
            Text('Total: ${formatRupiah(transaction.totalAmount)}'),
            Text('Payment: ${transaction.paymentMethod}'),
            const SizedBox(height: 8),
            Text(
              transaction.transactionStatus,
              style: TextStyle(
                color: isCompleted ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

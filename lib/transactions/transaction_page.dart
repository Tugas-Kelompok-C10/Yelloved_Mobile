
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/transaction.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  Future<List<Transaction>> fetchTransactions() async {
    final url = Uri.parse(
      'http://127.0.0.1:8000/transactions/api/',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map((json) => Transaction.fromJson(json))
          .toList();
    } else if (response.statusCode == 403) {
      throw Exception(
        'Akses ditolak. Pengguna belum terautentikasi.',
      );
    } else {
      throw Exception(
        'Gagal mengambil transaksi: ${response.statusCode}',
      );
    }
  }

  String formatRupiah(double amount) {
    return 'Rp${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Transactions'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Transaction>>(
        future: fetchTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
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
            return const Center(
              child: Text('Belum ada transaksi.'),
            );
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
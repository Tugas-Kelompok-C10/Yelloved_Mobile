
import 'package:flutter/material.dart';

class TransactionPage extends StatelessWidget {
  const TransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Transactions'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          transactionCard(
            'Vintage Denim Jacket',
            'TRX001',
            'Rp75.000',
            'COD',
            'Pending',
            Colors.orange,
          ),
          const SizedBox(height: 12),
          transactionCard(
            'Canvas Tote Bag',
            'TRX002',
            'Rp35.000',
            'Transfer',
            'Completed',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget transactionCard(
    String item,
    String id,
    String price,
    String payment,
    String status,
    Color statusColor,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Transaction ID: $id'),
            Text('Total: $price'),
            Text('Payment: $payment'),
            const SizedBox(height: 8),
            Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


import 'dart:convert';

import 'package:flutter/material.dart';

import 'transaction_detail_page.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> statusFilters = [
    {'label': 'Semua', 'value': 'all'},
    {'label': 'Pending', 'value': 'pending'},
    {'label': 'Processing', 'value': 'processing'},
    {'label': 'Completed', 'value': 'completed'},
    {'label': 'Cancelled', 'value': 'cancelled'},
  ];

  String selectedBoughtStatus = 'all';
  String selectedSoldStatus = 'all';

  Future<List<Transaction>> fetchTransactions(
    String type,
    String status,
  ) async {
    final response = await ApiService.get(
      '/transactions/api/history/?type=$type&status=$status',
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> results = data['results'];

      return results
          .map((json) => Transaction.fromJson(json))
          .toList();
    } else if (response.statusCode == 401 ||
        response.statusCode == 403) {
      throw Exception(
        'Sesi login tidak valid. Silakan login kembali.',
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

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget statusFilter({
    required String selectedStatus,
    required Function(String) onSelected,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      child: Row(
        children: statusFilters.map((filter) {
          final isSelected = selectedStatus == filter['value'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter['label']!),
              selected: isSelected,
              selectedColor: Colors.green,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              onSelected: (_) {
                onSelected(filter['value']!);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget transactionList({
    required String type,
    required String status,
  }) {
    return FutureBuilder<List<Transaction>>(
      key: ValueKey('$type-$status'),
      future: fetchTransactions(type, status),
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
          return Center(
            child: Text(
              status == 'all'
                  ? type == 'bought'
                      ? 'Belum ada transaksi pembelian.'
                      : 'Belum ada transaksi penjualan.'
                  : 'Tidak ada transaksi dengan status ${status.toUpperCase()}.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return transactionCard(transactions[index]);
          },
        );
      },
    );
  }

  Widget transactionCard(Transaction transaction) {
    final statusColor = getStatusColor(
      transaction.transactionStatus,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionDetailPage(
                transaction: transaction,
              ),
            ),
          );
        },
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
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Lihat Detail',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildBoughtTab() {
    return Column(
      children: [
        statusFilter(
          selectedStatus: selectedBoughtStatus,
          onSelected: (status) {
            setState(() {
              selectedBoughtStatus = status;
            });
          },
        ),
        Expanded(
          child: transactionList(
            type: 'bought',
            status: selectedBoughtStatus,
          ),
        ),
      ],
    );
  }

  Widget buildSoldTab() {
    return Column(
      children: [
        statusFilter(
          selectedStatus: selectedSoldStatus,
          onSelected: (status) {
            setState(() {
              selectedSoldStatus = status;
            });
          },
        ),
        Expanded(
          child: transactionList(
            type: 'sold',
            status: selectedSoldStatus,
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Transactions'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.shopping_bag_outlined),
              text: 'Pembelian',
            ),
            Tab(
              icon: Icon(Icons.storefront_outlined),
              text: 'Penjualan',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildBoughtTab(),
          buildSoldTab(),
        ],
      ),
    );
  }
}

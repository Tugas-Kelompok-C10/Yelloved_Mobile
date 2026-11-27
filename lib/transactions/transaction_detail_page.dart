
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/transaction.dart';
import '../services/api_service.dart';

class TransactionDetailPage extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailPage({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailPage> createState() =>
      _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  late Future<Transaction> transactionFuture;

  @override
  void initState() {
    super.initState();
    transactionFuture = fetchTransactionDetail();
  }

  Future<Transaction> fetchTransactionDetail() async {
    final orderId = Uri.encodeComponent(widget.transaction.orderId);

    final response = await ApiService.get(
      '/transactions/api/$orderId/',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Transaction.fromJson(data);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Sesi login tidak valid. Silakan login kembali.');
    }

    if (response.statusCode == 404) {
      throw Exception('Detail transaksi tidak ditemukan.');
    }

    throw Exception(
      'Gagal mengambil detail transaksi (${response.statusCode}).',
    );
  }

  Future<void> copyToClipboard(String value) async {
    await Clipboard.setData(ClipboardData(text: value));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nomor Virtual Account berhasil disalin'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String formatRupiah(double amount) {
    return 'Rp${amount.toStringAsFixed(0)}';
  }

  String formatDate(DateTime? date) {
    if (date == null) return '-';

    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year} '
        '${localDate.hour.toString().padLeft(2, '0')}:'
        '${localDate.minute.toString().padLeft(2, '0')}';
  }

  Widget detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget virtualAccountRow(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            flex: 2,
            child: Text(
              'Virtual Account',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: SelectableText(
                    value,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Salin nomor VA',
                  icon: const Icon(
                    Icons.copy,
                    size: 18,
                    color: Colors.green,
                  ),
                  onPressed: () => copyToClipboard(value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Load QRIS image through Django proxy endpoint.
  Widget buildQrisImage(Transaction transaction) {
    final orderId = Uri.encodeComponent(transaction.orderId);

    final imageUrl =
        '${ApiService.baseUrl}/transactions/api/$orderId/qris-image/';

    return FutureBuilder<Map<String, String>>(
      future: ApiService.getHeaders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 220,
            height: 220,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox(
            width: 220,
            height: 220,
            child: Center(
              child: Text(
                'Gagal memuat autentikasi QRIS.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Image.network(
          imageUrl,
          headers: snapshot.data,
          width: 220,
          height: 220,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }

            return const SizedBox(
              width: 220,
              height: 220,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(
              width: 220,
              height: 220,
              child: Center(
                child: Text(
                  'QR Code gagal dimuat.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildDetailContent(Transaction transaction) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transaction Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transaction Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),
                  detailRow('Order ID', transaction.orderId),
                  detailRow('Item', transaction.itemName),
                  detailRow('Quantity', '${transaction.quantity}'),
                  detailRow(
                    'Total Amount',
                    formatRupiah(transaction.totalAmount),
                  ),
                  detailRow(
                    'Created At',
                    formatDate(transaction.createdAt),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Payment Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),
                  detailRow(
                    'Payment Method',
                    transaction.paymentMethod.toUpperCase(),
                  ),
                  detailRow(
                    'Payment Status',
                    transaction.paymentStatus,
                  ),
                  detailRow(
                    'Transaction Status',
                    transaction.transactionStatus,
                  ),
                  detailRow(
                    'Expiry Time',
                    formatDate(transaction.expiryTime),
                  ),
                  if (transaction.virtualAccountBank.isNotEmpty)
                    detailRow(
                      'Bank',
                      transaction.virtualAccountBank.toUpperCase(),
                    ),
                  if (transaction.virtualAccountNumber.isNotEmpty)
                    virtualAccountRow(
                      transaction.virtualAccountNumber,
                    ),
                  if (transaction.virtualAccountBillKey.isNotEmpty)
                    detailRow(
                      'Bill Key',
                      transaction.virtualAccountBillKey,
                    ),
                  if (transaction.virtualAccountBillerCode.isNotEmpty)
                    detailRow(
                      'Biller Code',
                      transaction.virtualAccountBillerCode,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Delivery Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivery Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),
                  if (transaction.paymentMethod.toLowerCase() == 'cod') ...[
                    detailRow(
                      'Meeting Location',
                      transaction.codMeetingLocation,
                    ),
                    detailRow(
                      'Meeting Time',
                      formatDate(transaction.codMeetingTime),
                    ),
                  ] else
                    detailRow(
                      'Shipping Address',
                      transaction.shippingAddress,
                    ),
                ],
              ),
            ),
          ),

          // QRIS Payment
          if (transaction.qrCodeUrl.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'QRIS Payment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: buildQrisImage(transaction),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Scan QR Code menggunakan aplikasi pembayaran '
                      'yang mendukung QRIS.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Detail'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Transaction>(
        future: transactionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          transactionFuture = fetchTransactionDetail();
                        });
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasData) {
            return buildDetailContent(snapshot.data!);
          }

          return const Center(
            child: Text('Detail transaksi tidak tersedia.'),
          );
        },
      ),
    );
  }
}

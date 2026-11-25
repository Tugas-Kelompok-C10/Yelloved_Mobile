import 'package:flutter/material.dart';

class MatchingPage extends StatelessWidget {
  const MatchingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Matching & Exchange')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aktivitas Matching Anda',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kelola request barang dan penawaran tukar tambah di sini.',
            ),
            const SizedBox(height: 24),

            // Contoh Card Item Request Masuk
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const ListTile(
                leading: Icon(Icons.swap_horiz, color: Colors.purple),
                title: Text('Request Barang: Buku Pemrograman'),
                subtitle: Text(
                  'Diminta oleh: user_c10\nStatus: Menunggu Konfirmasi (Pending)',
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

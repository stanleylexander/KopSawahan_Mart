import 'package:flutter/material.dart';
import '../drawer/drawer_cashier.dart';

class HomeCashier extends StatelessWidget {
  const HomeCashier({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CashierDrawer(),
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Home Cashier'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section: Terima Pesanan
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pesanan Masuk',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Belum ada pesanan saat ini'),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Navigate ke halaman detail pesanan
                      },
                      child: const Text('Lihat Pesanan'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

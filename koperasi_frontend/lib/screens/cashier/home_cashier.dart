import 'package:flutter/material.dart';
import '../drawer/drawer_cashier.dart';
import '../../services/order_service.dart';

class HomeCashier extends StatefulWidget {
  const HomeCashier({super.key});

  @override
  State<HomeCashier> createState() => _HomeCashierState();
}

class _HomeCashierState extends State<HomeCashier> {
  List orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    setState(() => isLoading = true);

    try {
      final data = await OrderService.getOrders();

      setState(() {
        orders = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal load data")),
      );
    }
  }

  Future<void> completeOrder(int orderId) async {
    try {
      await OrderService.completeOrder(orderId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pesanan selesai")),
      );

      loadOrders(); // refresh data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal update status")),
      );
    }
  }

  Widget _buildOrderCard(dynamic order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Nama User
            Text(
              "${order['user']['name']}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            // 🔹 Payment Method
            Text(
              "Metode: ${order['payment_method']}",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 8),

            // 🔹 List Produk
            ...order['items'].map<Widget>((item) {
              return Text(
                "- ${item['product']['name']} (${item['quantity']}x)",
              );
            }).toList(),

            const SizedBox(height: 12),

            // 🔹 Total + Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Rp ${order['total_price']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),

                ElevatedButton(
                  onPressed: () => completeOrder(order['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Selesai"),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CashierDrawer(),
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Home Cashier'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text("Belum ada pesanan"))
              : RefreshIndicator(
                  onRefresh: loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _buildOrderCard(order);
                    },
                  ),
                ),
    );
  }
}
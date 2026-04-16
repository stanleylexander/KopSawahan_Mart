import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../receipt/receipt_detail_page.dart';
import '../drawer/drawer_cashier.dart';

class HomeCashier extends StatefulWidget {
  const HomeCashier({super.key});

  @override
  State<HomeCashier> createState() => _HomeCashierState();
}

class _HomeCashierState extends State<HomeCashier> {
  List orders = [];
  bool isLoading = true;
  String selectedTab = 'pending';
  final TextEditingController searchController = TextEditingController();
  final Set<int> expandedOrderIds = {};

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
      showMessage("Gagal load data");
    }
  }

  Future<void> completeOrder(int orderId) async {
    final response = await OrderService.completeOrder(orderId);

    if (response != null) {
      showMessage("Pesanan selesai dikemas");

      final receipt = response["receipt"];

      if (receipt is Map<String, dynamic> &&
          receipt['receipt_type'] == 'print' &&
          mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiptDetailPage(
              initialReceipt: receipt,
              showPrintButton: true,
              autoPrintOnOpen: true,
            ),
          ),
        );
      }

      await loadOrders();
    } else {
      showMessage("Gagal update status");
    }
  }

  Future<void> markOrderAsTaken(int orderId) async {
    final success = await OrderService.markOrderAsTaken(orderId);

    if (success) {
      showMessage("Pesanan sudah diambil");
      await loadOrders();
    } else {
      showMessage("Gagal update status");
    }
  }

  List getFilteredOrders() {
    final keyword = searchController.text.toLowerCase();

    return orders.where((order) {
      if (order['status'] != selectedTab) {
        return false;
      }

      if (keyword.isEmpty) {
        return true;
      }

      final userName = (order['user']?['name'] ?? order['customer_name'] ?? '')
          .toString()
          .toLowerCase();
      final orderId = order['id'].toString().toLowerCase();
      final productNames = (order['items'] as List)
          .map((item) {
            return (item['product_name'] ?? item['product']?['name'] ?? '')
                .toString()
                .toLowerCase();
          })
          .join(' ');

      return userName.contains(keyword) ||
          orderId.contains(keyword) ||
          productNames.contains(keyword);
    }).toList();
  }

  Widget buildTabButton({
    required String value,
    required String label,
  }) {
    final isActive = selectedTab == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.red.shade700 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: searchController,
        onChanged: (_) {
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: "Cari order, nama member, atau produk...",
          prefixIcon: Icon(Icons.search, color: Colors.red.shade700),
          filled: true,
          fillColor: Colors.red.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade700, width: 2),
          ),
        ),
      ),
    );
  }

  Widget buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          buildTabButton(
            value: 'pending',
            label: 'Order Diterima',
          ),
          const SizedBox(width: 12),
          buildTabButton(
            value: 'selesai',
            label: 'Sudah Diambil',
          ),
        ],
      ),
    );
  }

  Widget buildActionButton(dynamic order) {
    if (order['status'] == 'pending') {
      return ElevatedButton(
        onPressed: () => completeOrder(order['id']),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text("Selesai"),
      );
    }

    return ElevatedButton(
      onPressed: () => markOrderAsTaken(order['id']),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text("Sudah Diambil"),
    );
  }

  Widget buildProductDetails(dynamic order) {
    final orderId = order['id'] as int;
    final isExpanded = expandedOrderIds.contains(orderId);
    final items = (order['items'] as List?) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey("order_items_$orderId"),
          initiallyExpanded: isExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          collapsedIconColor: Colors.red.shade700,
          iconColor: Colors.red.shade700,
          onExpansionChanged: (value) {
            setState(() {
              if (value) {
                expandedOrderIds.add(orderId);
              } else {
                expandedOrderIds.remove(orderId);
              }
            });
          },
          title: Text(
            "Detail Produk",
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          children: items.map<Widget>((item) {
            final productName = item['product_name'] ?? item['product']?['name'] ?? 'Produk';
            final quantity = item['quantity'] ?? 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "- ",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "$productName ($quantity x)",
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildOrderCard(dynamic order) {
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
            Text(
              "${order['user']?['name'] ?? order['customer_name'] ?? 'Pelanggan'}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Order #${order['id']}",
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              "Metode: ${order['payment_method']}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              "Status: ${order['status']}",
              style: TextStyle(
                color: order['status'] == 'pending' ? Colors.orange : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            buildProductDetails(order),
            const SizedBox(height: 12),
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
                buildActionButton(order),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOrderList() {
    final filteredOrders = getFilteredOrders();

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredOrders.isEmpty) {
      return const Center(
        child: Text("Belum ada pesanan"),
      );
    }

    return RefreshIndicator(
      onRefresh: loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          return buildOrderCard(filteredOrders[index]);
        },
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
      body: Column(
        children: [
          buildSearchBar(),
          buildTabs(),
          const SizedBox(height: 12),
          Expanded(
            child: buildOrderList(),
          ),
        ],
      ),
    );
  }
}

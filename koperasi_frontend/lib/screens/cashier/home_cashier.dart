import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/push_notification_service.dart';
import '../../services/order_service.dart';
import '../../utils/receipt_helper.dart';
import '../drawer/drawer_cashier.dart';
import '../receipt/receipt_detail_page.dart';

class HomeCashier extends StatefulWidget {
  const HomeCashier({super.key});

  @override
  State<HomeCashier> createState() => _HomeCashierState();
}

class _HomeCashierState extends State<HomeCashier> {
  final Color primaryRed = const Color(0xFFB71C1C);
  List orders = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();
  final Set<int> expandedOrderIds = {};
  final Map<int, DateTime> notificationCooldowns = {};
  final Map<int, Timer> notificationCooldownTimers = {};

  @override
  void initState() {
    super.initState();
    PushNotificationService.syncDeviceTokenWithServer();
    loadOrders();
  }

  @override
  void dispose() {
    for (final timer in notificationCooldownTimers.values) {
      timer.cancel();
    }
    searchController.dispose();
    super.dispose();
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

      if (!mounted) {
        return;
      }

      await loadNotificationCooldowns(data);

      setState(() {
        orders = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => isLoading = false);
      showMessage("Gagal load data");
    }
  }

  String getNotificationCooldownKey(int orderId) {
    return "order_notification_cooldown_$orderId";
  }

  Future<void> loadNotificationCooldowns(List data) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    for (final order in data) {
      final orderId = order['id'];
      if (orderId is! int) {
        continue;
      }

      final raw = prefs.getString(getNotificationCooldownKey(orderId));
      final cooldownUntil = DateTime.tryParse(raw ?? '');

      if (cooldownUntil == null || cooldownUntil.isBefore(now)) {
        notificationCooldowns.remove(orderId);
        notificationCooldownTimers[orderId]?.cancel();
        notificationCooldownTimers.remove(orderId);
        await prefs.remove(getNotificationCooldownKey(orderId));
      } else {
        notificationCooldowns[orderId] = cooldownUntil;
        scheduleNotificationCooldownTimer(orderId, cooldownUntil);
      }
    }
  }

  void scheduleNotificationCooldownTimer(int orderId, DateTime cooldownUntil) {
    notificationCooldownTimers[orderId]?.cancel();

    final remaining = cooldownUntil.difference(DateTime.now());

    if (remaining.isNegative) {
      notificationCooldowns.remove(orderId);
      return;
    }

    notificationCooldownTimers[orderId] = Timer(remaining, () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(getNotificationCooldownKey(orderId));

      if (!mounted) {
        return;
      }

      setState(() {
        notificationCooldowns.remove(orderId);
        notificationCooldownTimers.remove(orderId);
      });
    });
  }

  bool isNotificationDisabled(int orderId) {
    final cooldownUntil = notificationCooldowns[orderId];
    return cooldownUntil != null && cooldownUntil.isAfter(DateTime.now());
  }

  String getNotificationCooldownLabel(int orderId) {
    final cooldownUntil = notificationCooldowns[orderId];

    if (cooldownUntil == null) {
      return "Notifikasi";
    }

    final remaining = cooldownUntil.difference(DateTime.now());

    if (remaining.isNegative) {
      return "Notifikasi";
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);

    if (hours > 0) {
      return "${hours}j ${minutes}m";
    }

    return "${minutes}m";
  }

  Future<void> handleCompleteOrder(int orderId, {int? amountPaid}) async {
    final response = await OrderService.completeOrder(orderId, amountPaid: amountPaid);

    if (response != null) {

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

  Future<void> sendOrderNotification(int orderId) async {
    if (isNotificationDisabled(orderId)) {
      showMessage("Notifikasi sudah dikirim. Tunggu 3 jam untuk mengirim lagi.");
      return;
    }

    final success = await OrderService.notifyOrder(orderId);

    if (success) {
      final cooldownUntil = DateTime.now().add(const Duration(hours: 3));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        getNotificationCooldownKey(orderId),
        cooldownUntil.toIso8601String(),
      );

      if (mounted) {
        setState(() {
          notificationCooldowns[orderId] = cooldownUntil;
        });
        scheduleNotificationCooldownTimer(orderId, cooldownUntil);
      }
    }

    showMessage(
      success ? "Notifikasi berhasil dikirim" : "Gagal mengirim notifikasi",
    );
  }

  Future<void> confirmCompleteOrder(dynamic order, {int? amountPaid}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: Text(
          order['payment_method'] == 'cash'
              ? "Pastikan pembayaran customer sudah diterima. Lanjutkan selesaikan pesanan?"
              : "Apakah kamu yakin ingin menyelesaikan pesanan ini?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text("Lanjut"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await handleCompleteOrder(order['id'], amountPaid: amountPaid);
    }
  }

  Future<void> openCashPaymentSheet(dynamic order) async {
    final amountController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 56,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "Pembayaran Cash",
                    style: TextStyle(
                      color: primaryRed,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Total bayar: ${ReceiptHelper.formatCurrency(order['total_price'] ?? 0)}",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      if (errorText != null) {
                        setModalState(() {
                          errorText = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: "Nominal pembayaran",
                      prefixText: "Rp ",
                      filled: true,
                      fillColor: Colors.grey[50],
                      errorText: errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final amountPaid = int.tryParse(amountController.text) ?? 0;
                        final totalPrice = order['total_price'] ?? 0;

                        if (amountPaid <= 0) {
                          setModalState(() {
                            errorText = "Masukkan nominal pembayaran";
                          });
                          return;
                        }

                        if (amountPaid < totalPrice) {
                          setModalState(() {
                            errorText = "Salah memasukkan nominal pembayaran";
                          });
                          return;
                        }

                        Navigator.pop(context);
                        await confirmCompleteOrder(order, amountPaid: amountPaid);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Selesai",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
          },
        );
      },
    );

    amountController.dispose();
  }

  List getFilteredOrders() {
    final keyword = searchController.text.toLowerCase();
    final sortedOrders = List.of(orders)
      ..sort((a, b) {
        final aPending = a['status'] == 'pending' ? 0 : 1;
        final bPending = b['status'] == 'pending' ? 0 : 1;
        return aPending.compareTo(bPending);
      });

    return sortedOrders.where((order) {
      if (order['status'] != 'pending') {
        return false;
      }

      if (keyword.isEmpty) {
        return true;
      }

      final userName = (order['user']?['name'] ?? order['customer_name'] ?? '')
          .toString()
          .toLowerCase();
      final orderId = order['id'].toString().toLowerCase();
      final productNames = (order['items'] as List? ?? [])
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

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: searchController,
        onChanged: (_) => setState(() {}),
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

  Widget buildStatusChip(String status) {
    final isPending = status == 'pending';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isPending ? "Pending" : "Selesai",
        style: TextStyle(
          color: isPending ? Colors.orange.shade700 : Colors.green.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget buildActionButtons(dynamic order) {
    if (order['status'] != 'pending') {
      return buildStatusChip('selesai');
    }

    final isCashPayment = order['payment_method'] == 'cash';
    final hasUser = order['user_id'] != null;
    final orderId = order['id'] as int;
    final notificationDisabled = isNotificationDisabled(orderId);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        if (hasUser)
          OutlinedButton.icon(
            onPressed: notificationDisabled
                ? null
                : () => sendOrderNotification(orderId),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryRed,
              side: BorderSide(color: Colors.red.shade200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.notifications_active_outlined, size: 18),
            label: Text(
              getNotificationCooldownLabel(orderId),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ElevatedButton(
          onPressed: isCashPayment
              ? () => openCashPaymentSheet(order)
              : () => confirmCompleteOrder(order),
          style: ElevatedButton.styleFrom(
            backgroundColor: isCashPayment ? Colors.green : Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            isCashPayment ? "Bayar" : "Selesai",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
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
    final status = order['status'] ?? 'pending';

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    "${order['user']?['name'] ?? order['customer_name'] ?? 'Pelanggan'}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                buildStatusChip(status),
              ],
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
            const SizedBox(height: 10),
            buildProductDetails(order),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    ReceiptHelper.formatCurrency(order['total_price'] ?? 0),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ),
                buildActionButtons(order),
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
          Expanded(
            child: buildOrderList(),
          ),
        ],
      ),
    );
  }
}

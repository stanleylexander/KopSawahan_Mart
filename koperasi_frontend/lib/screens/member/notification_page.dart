import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../services/receipt_service.dart';
import '../../utils/receipt_helper.dart';
import '../receipt/receipt_detail_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final Color primaryRed = const Color(0xFFB71C1C);
  String selectedTab = 'notification';
  List notifications = [];
  List receipts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> loadNotifications() async {
    setState(() {
      isLoading = true;
    });

    final data = await NotificationService.getNotifications();

    if (!mounted) {
      return;
    }

    setState(() {
      notifications = data;
      isLoading = false;
    });
  }

  Future<void> loadReceipts() async {
    setState(() {
      isLoading = true;
    });

    final data = await ReceiptService.getMyReceipts();

    if (!mounted) {
      return;
    }

    setState(() {
      receipts = data;
      isLoading = false;
    });
  }

  Future<void> refreshCurrentTab() async {
    if (selectedTab == 'notification') {
      await loadNotifications();
      return;
    }

    await loadReceipts();
  }

  Future<void> openNotification(dynamic notification) async {
    final success = await NotificationService.markAsRead(notification['id']);

    if (!success) {
      showMessage("Gagal membuka notifikasi");
      return;
    }

    await loadNotifications();
  }

  Future<void> openReceipt(dynamic receipt) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptDetailPage(
          receiptId: receipt['id'],
          initialReceipt: Map<String, dynamic>.from(receipt),
        ),
      ),
    );
  }

  Color getTypeColor(String type) {
    if (type == 'checkout') {
      return Colors.blue;
    }

    if (type == 'pickup') {
      return Colors.green;
    }

    if (type == 'point') {
      return Colors.orange;
    }

    return Colors.grey;
  }

  IconData getTypeIcon(String type) {
    if (type == 'checkout') {
      return Icons.shopping_bag;
    }

    if (type == 'pickup') {
      return Icons.inventory_2;
    }

    if (type == 'point') {
      return Icons.stars_rounded;
    }

    return Icons.notifications;
  }

  Widget buildNotificationCard(dynamic notification) {
    final type = notification['type'] ?? 'info';
    final isRead = notification['is_read'] == true;

    return InkWell(
      onTap: () => openNotification(notification),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? Colors.grey.shade200 : Colors.red.shade100,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: getTypeColor(type).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                getTypeIcon(type),
                color: getTypeColor(type),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'] ?? '-',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification['message'] ?? '-',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification['created_at'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTabButton({
    required String value,
    required String label,
  }) {
    final isActive = selectedTab == value;

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          if (selectedTab == value) {
            return;
          }

          setState(() {
            selectedTab = value;
          });

          await refreshCurrentTab();
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

  Widget buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          buildTabButton(
            value: 'notification',
            label: 'Notifikasi',
          ),
          const SizedBox(width: 12),
          buildTabButton(
            value: 'receipt',
            label: 'Nota',
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildNotificationList() {
    if (notifications.isEmpty) {
      return buildEmptyState(
        icon: Icons.notifications_none_rounded,
        title: "Belum ada notifikasi",
        subtitle: "Info checkout dan poin akan muncul di sini",
      );
    }

    return RefreshIndicator(
      onRefresh: loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return buildNotificationCard(notifications[index]);
        },
      ),
    );
  }

  Widget buildReceiptCard(dynamic receipt) {
    return InkWell(
      onTap: () => openReceipt(receipt),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.red.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade50,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.receipt_long, color: primaryRed),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt['receipt_number'] ?? '-',
                    style: TextStyle(
                      color: primaryRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ReceiptHelper.formatDateTime(receipt['created_at']),
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
              ),
            ),
            Text(
              ReceiptHelper.formatCurrency(receipt['total_price'] ?? 0),
              style: TextStyle(
                color: primaryRed,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildReceiptList() {
    if (receipts.isEmpty) {
      return buildEmptyState(
        icon: Icons.receipt_long,
        title: "Belum ada nota digital",
        subtitle: "Nota cash dan online akan tersimpan di sini",
      );
    }

    return RefreshIndicator(
      onRefresh: loadReceipts,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: receipts.length,
        itemBuilder: (context, index) {
          return buildReceiptCard(receipts[index]);
        },
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (selectedTab == 'notification') {
      return buildNotificationList();
    }

    return buildReceiptList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      appBar: AppBar(
        title: const Text("Notifikasi"),
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryRed, Colors.red.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          buildTabs(),
          Expanded(
            child: buildBody(),
          ),
        ],
      ),
    );
  }
}

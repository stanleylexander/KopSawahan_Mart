import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final Color primaryRed = const Color(0xFFB71C1C);
  List notifications = [];
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

    setState(() {
      notifications = data;
      isLoading = false;
    });
  }

  Future<void> openNotification(dynamic notification) async {
    final success = await NotificationService.markAsRead(notification['id']);

    if (!success) {
      showMessage("Gagal membuka notifikasi");
      return;
    }

    await loadNotifications();
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

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifications.isEmpty) {
      return const Center(
        child: Text("Belum ada notifikasi"),
      );
    }

    return RefreshIndicator(
      onRefresh: loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return buildNotificationCard(notifications[index]);
        },
      ),
    );
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
      body: buildBody(),
    );
  }
}

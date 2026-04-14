import 'package:flutter/material.dart';
import '../../services/receipt_service.dart';
import '../../utils/receipt_helper.dart';
import 'receipt_detail_page.dart';

class ReceiptListPage extends StatefulWidget {
  const ReceiptListPage({super.key});

  @override
  State<ReceiptListPage> createState() => _ReceiptListPageState();
}

class _ReceiptListPageState extends State<ReceiptListPage> {
  final Color primaryRed = const Color(0xFFB71C1C);
  List receipts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadReceipts();
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

  Future<void> openReceipt(dynamic receipt) async {
    final receiptId = receipt['id'];

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptDetailPage(
          receiptId: receiptId,
          initialReceipt: Map<String, dynamic>.from(receipt),
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "Belum ada nota digital",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Nota online akan tersimpan di akun kamu",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
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
                  const SizedBox(height: 4),
                  Text(
                    "Kasir: ${receipt['cashier_name'] ?? '-'} • ${(receipt['payment_method'] ?? '-').toString().toUpperCase()}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  ReceiptHelper.formatCurrency(receipt['total_price'] ?? 0),
                  style: TextStyle(
                    color: primaryRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    receipt['receipt_type'] == 'digital' ? "Digital" : "Print",
                    style: TextStyle(
                      color: primaryRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      appBar: AppBar(
        title: const Text("Nota Saya"),
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: primaryRed),
            )
          : receipts.isEmpty
              ? buildEmptyState()
              : RefreshIndicator(
                  onRefresh: loadReceipts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: receipts.length,
                    itemBuilder: (context, index) {
                      return buildReceiptCard(receipts[index]);
                    },
                  ),
                ),
    );
  }
}

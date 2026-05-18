import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../receipt/receipt_detail_page.dart';

class QrisMember extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final int originalSubtotal;
  final int workerDiscountAmount;
  final int voucherDiscountAmount;
  final int? userVoucherId;

  const QrisMember({
    super.key,
    required this.items,
    required this.originalSubtotal,
    required this.workerDiscountAmount,
    required this.voucherDiscountAmount,
    required this.userVoucherId,
  });

  @override
  State<QrisMember> createState() => _QrisMemberState();
}

class _QrisMemberState extends State<QrisMember> {
  bool isLoading = false;

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int? getOrderId(Map<String, dynamic>? response) {
    if (response == null) return null;

    final order = response["order"];
    if (order is Map<String, dynamic>) {
      final id = order["id"];

      if (id is int) return id;
      if (id is String) return int.tryParse(id);
    }

    return null;
  }

  Future<void> payNow() async {
    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    final response = await OrderService.createOrder(
      paymentMethod: "online",
      items: widget.items,
      totalPrice: getFinalTotal(),
      status: "pending",
      userVoucherId: widget.userVoucherId,
    );

    final orderId = getOrderId(response);

    if (orderId == null) {
      setState(() {
        isLoading = false;
      });
      showMessage("Order gagal dibuat");
      return;
    }

    await CartService.clearCart();

    if (!mounted) {
      return;
    }

    final receipt = response?["receipt"];

    if (receipt is Map<String, dynamic>) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptDetailPage(
            initialReceipt: receipt,
          ),
        ),
      );
    }

    Navigator.pop(context, true);
  }

  String getQrData() {
    return "QRIS|TOTAL:${getFinalTotal()}";
  }

  int getSubtotalAfterWorkerDiscount() {
    final total = widget.originalSubtotal - widget.workerDiscountAmount;
    return total < 0 ? 0 : total;
  }

  int getFinalTotal() {
    final total = getSubtotalAfterWorkerDiscount() - widget.voucherDiscountAmount;
    return total < 0 ? 0 : total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pembayaran QRIS"),
        backgroundColor: Colors.red.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              "Scan QR untuk bayar",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 20),
            QrImageView(
              data: getQrData(),
              size: 220,
            ),
            const SizedBox(height: 20),
            Text(
              "Subtotal: Rp ${widget.originalSubtotal}",
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
            if (widget.workerDiscountAmount > 0) ...[
              const SizedBox(height: 6),
              Text(
                "Diskon worker: -Rp ${widget.workerDiscountAmount}",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              "Diskon voucher: -Rp ${widget.voucherDiscountAmount}",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Total: Rp ${getFinalTotal()}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : payNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text("Saya sudah bayar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

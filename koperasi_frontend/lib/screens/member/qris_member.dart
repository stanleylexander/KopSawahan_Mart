import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';

class QrisPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final int totalPrice;

  const QrisPage({
    super.key,
    required this.items,
    required this.totalPrice,
  });

  @override
  State<QrisPage> createState() => _QrisPageState();
}

class _QrisPageState extends State<QrisPage> {
  bool isPaid = false;
  bool isProcessingPayment = false;
  int? orderId;

  Future<void> _createOrder() async {
    final response = await OrderService.createOrder(
      paymentMethod: "online",
      items: widget.items,
      totalPrice: widget.totalPrice,
      status: "pending",
    );

    if (!mounted) return;

    final createdOrderId = _extractOrderId(response);

    if (createdOrderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal membuat order QRIS")),
      );
      Navigator.pop(context, false);
      return;
    }

    setState(() {
      orderId = createdOrderId;
    });
  }

  int? _extractOrderId(Map<String, dynamic>? response) {
    if (response == null) return null;

    final order = response["order"];
    if (order is Map<String, dynamic>) {
      final id = order["id"];
      if (id is int) return id;
      if (id is String) return int.tryParse(id);
    }

    final id = response["id"] ?? response["order_id"];
    if (id is int) return id;
    if (id is String) return int.tryParse(id);

    return null;
  }

  String generateQRData() {
    return "QRIS|TOTAL:${widget.totalPrice}";
  }

  Future<void> simulatePayment() async {
    setState(() {
      isProcessingPayment = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    await _createOrder();

    if (!mounted) return;

    if (orderId == null) {
      setState(() {
        isProcessingPayment = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal membuat order")),
      );
      return;
    }

    await CartService.clearCart();

    if (!mounted) return;

    setState(() {
      isPaid = true;
      isProcessingPayment = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Pembayaran berhasil")),
    );

    Navigator.pop(context, true);
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
              data: generateQRData(),
              size: 220,
            ),
            const SizedBox(height: 20),
            Text(
              "Total: Rp ${widget.totalPrice}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isPaid || isProcessingPayment) ? null : simulatePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                child: isProcessingPayment
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isPaid ? "Sudah Dibayar" : "Saya sudah bayar",
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

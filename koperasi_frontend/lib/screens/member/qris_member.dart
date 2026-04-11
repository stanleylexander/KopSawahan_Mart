import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';

class QrisMember extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final int totalPrice;

  const QrisMember({
    super.key,
    required this.items,
    required this.totalPrice,
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
      totalPrice: widget.totalPrice,
      status: "pending",
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

    // Cek dulu, jangan lanjut kalau halaman ini sudah ditutup.
    if (!mounted) {
      return;
    }

    showMessage("Pembayaran berhasil");
    Navigator.pop(context, true);
  }

  String getQrData() {
    return "QRIS|TOTAL:${widget.totalPrice}";
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

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/order_service.dart';
import '../../services/cart_service.dart';

class QrisCashier extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final int totalPrice;

  const QrisCashier({
    Key? key,
    required this.items,
    required this.totalPrice,
  }) : super(key: key);

  @override
  State<QrisCashier> createState() => _QrisCashierState();
}

class _QrisCashierState extends State<QrisCashier> {

  bool isPaid = false;

  String generateQRData() {
    // 🔥 Dummy QRIS format
    return "QRIS|TOTAL:${widget.totalPrice}";
  }

  Future<void> simulatePayment() async {
    // ⏳ Simulasi delay bayar
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isPaid = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Pembayaran berhasil")),
    );

    Navigator.pop(context);
  }

  //PAYMENT
  Future<void> onPaymentSuccess(BuildContext context) async {

    final response = await OrderService.createOrder(
      paymentMethod: "online",
      items: widget.items,
      totalPrice: widget.totalPrice,
      status: "diambil",
    );

    if (response != null) {

      await CartService.clearCart();

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pembayaran berhasil")),
      );
    }
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

            // 🔥 QR CODE
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

            // 🔥 BUTTON BAYAR
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isPaid ? null : () async {
                  await simulatePayment();
                  await onPaymentSuccess(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                child: Text(
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
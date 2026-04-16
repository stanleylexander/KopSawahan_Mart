import 'package:flutter/material.dart';
import '../../class/cart.dart';
import '../../config/api.dart';
import '../../services/order_service.dart';
import '../../utils/receipt_helper.dart';
import 'qris_member.dart';

class CheckoutDetailPage extends StatefulWidget {
  final List<Cart> cartItems;
  final List<Map<String, dynamic>> orderItems;
  final bool isWorker;
  final int originalSubtotal;
  final int workerDiscountAmount;
  final int voucherDiscountAmount;
  final int finalTotalPrice;
  final int? userVoucherId;
  final dynamic selectedVoucher;

  const CheckoutDetailPage({
    super.key,
    required this.cartItems,
    required this.orderItems,
    required this.isWorker,
    required this.originalSubtotal,
    required this.workerDiscountAmount,
    required this.voucherDiscountAmount,
    required this.finalTotalPrice,
    required this.userVoucherId,
    required this.selectedVoucher,
  });

  @override
  State<CheckoutDetailPage> createState() => _CheckoutDetailPageState();
}

class _CheckoutDetailPageState extends State<CheckoutDetailPage> {
  final Color primaryRed = const Color(0xFFB71C1C);
  final Color creamBackground = const Color(0xFFFFF8F6);
  String selectedPaymentMethod = "cash";
  bool isLoading = false;

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int getDisplayPrice(num price) {
    if (!widget.isWorker) {
      return price.toInt();
    }

    return (price * 0.9).floor();
  }

  Future<void> checkoutCash() async {
    setState(() {
      isLoading = true;
    });

    final response = await OrderService.createOrder(
      paymentMethod: "cash",
      items: widget.orderItems,
      totalPrice: widget.finalTotalPrice,
      status: "pending",
      userVoucherId: widget.userVoucherId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = false;
    });

    if (response == null) {
      showMessage("Checkout gagal");
      return;
    }

    if (!mounted) {
      return;
    }

    showMessage("Checkout berhasil dibuat");
    Navigator.pop(context, true);
  }

  Future<void> checkoutOnline() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QrisMember(
          items: widget.orderItems,
          originalSubtotal: widget.originalSubtotal,
          workerDiscountAmount: widget.workerDiscountAmount,
          voucherDiscountAmount: widget.voucherDiscountAmount,
          userVoucherId: widget.userVoucherId,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> handleCheckout() async {
    if (selectedPaymentMethod == "cash") {
      await checkoutCash();
      return;
    }

    await checkoutOnline();
  }

  Widget buildStepItem(String number, String title, String subtitle, {bool isActive = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? primaryRed : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Text(
            number,
            style: TextStyle(
              color: isActive ? Colors.white : primaryRed,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: primaryRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = selectedPaymentMethod == value;

    return InkWell(
      onTap: () {
        setState(() {
          selectedPaymentMethod = value;
        });
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? primaryRed : Colors.red.shade100,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: primaryRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? primaryRed : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProductItem(Cart item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.image != null
                ? Image.network(
                    "${Api.storageUrl}${item.image}",
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 64,
                    height: 64,
                    color: Colors.grey[100],
                    child: const Icon(Icons.image),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: primaryRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${item.quantity} x ${ReceiptHelper.formatCurrency(getDisplayPrice(item.price))}",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          Text(
            ReceiptHelper.formatCurrency(getDisplayPrice(item.price) * item.quantity),
            style: TextStyle(
              color: primaryRed,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildVoucherSection() {
    final voucher = widget.selectedVoucher;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.local_offer, color: primaryRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              voucher == null
                  ? "Belum menggunakan voucher"
                  : "${voucher['voucher']['name']} - Diskon ${voucher['voucher']['discount_amount']}% maks. ${ReceiptHelper.formatCurrency(voucher['voucher']['max_discount_amount'] ?? 0)}",
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ringkasan Belanja",
            style: TextStyle(
              color: primaryRed,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          buildSummaryRow("Subtotal", ReceiptHelper.formatCurrency(widget.originalSubtotal)),
          if (widget.workerDiscountAmount > 0)
            buildSummaryRow("Diskon worker", "-${ReceiptHelper.formatCurrency(widget.workerDiscountAmount)}"),
          if (widget.voucherDiscountAmount > 0)
            buildSummaryRow("Diskon voucher", "-${ReceiptHelper.formatCurrency(widget.voucherDiscountAmount)}"),
          const SizedBox(height: 4),
          buildSummaryRow(
            "Total bayar",
            ReceiptHelper.formatCurrency(widget.finalTotalPrice),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? primaryRed : Colors.grey[700],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? primaryRed : Colors.green.shade700,
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBackground,
      appBar: AppBar(
        title: const Text("Detail Checkout"),
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildStepItem("1", "Pesanan Dikirim", "Checkout berhasil dibuat dan data pesanan masuk ke koperasi.", isActive: true),
            const SizedBox(height: 16),
            buildStepItem("2", "Menunggu Pesanan Disiapkan", "Kasir akan menyiapkan barang setelah pesanan diproses."),
            const SizedBox(height: 16),
            buildStepItem("3", "Mengambil Pesanan", "Ambil pesanan ke koperasi setelah mendapat notifikasi siap diambil."),
            const SizedBox(height: 24),
            Text(
              "Metode Pembayaran",
              style: TextStyle(
                color: primaryRed,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            buildPaymentOption(
              value: "cash",
              title: "Bayar di Tempat",
              subtitle: "Bayar langsung saat mengambil pesanan",
              icon: Icons.payments_rounded,
              iconColor: Colors.green,
            ),
            const SizedBox(height: 12),
            buildPaymentOption(
              value: "online",
              title: "QRIS",
              subtitle: "Bayar sekarang lewat QRIS",
              icon: Icons.qr_code_2_rounded,
              iconColor: Colors.blue,
            ),
            const SizedBox(height: 24),
            buildVoucherSection(),
            const SizedBox(height: 16),
            buildSummaryCard(),
            const SizedBox(height: 24),
            Text(
              "Produk Checkout",
              style: TextStyle(
                color: primaryRed,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.cartItems.map(buildProductItem),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : handleCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
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
                    : Text(
                        selectedPaymentMethod == "cash"
                            ? "Buat Checkout"
                            : "Lanjut ke QRIS",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

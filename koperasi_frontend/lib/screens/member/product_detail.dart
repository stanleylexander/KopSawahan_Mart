import 'package:flutter/material.dart';
import '../../class/product.dart';
import '../../config/api.dart';
import '../../services/cart_service.dart';
import '../../utils/receipt_helper.dart';

class ProductDetail extends StatelessWidget {
  final Product product;
  final bool isWorker;

  const ProductDetail({
    super.key,
    required this.product,
    this.isWorker = false,
  });

  int getDisplayPrice() {
    if (!isWorker) {
      return product.price;
    }

    return (product.price * 0.9).floor();
  }

  Future<void> showCenteredMessage(BuildContext context) async {
    final overlay = Overlay.of(context);

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (_) {
        return Material(
          color: Colors.black.withOpacity(0.28),
          child: Center(
            child: Container(
              width: 250,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 34,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Masuk ke Keranjang",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);
    await Future.delayed(const Duration(milliseconds: 1200));
    overlayEntry.remove();
  }

  Widget buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      appBar: AppBar(
        title: const Text("Detail Produk"),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 360,
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                      child: product.image != null
                          ? Image.network(
                              "${Api.storageUrl}${product.image}",
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported_outlined,
                                        size: 68, color: Colors.grey[400]),
                                    const SizedBox(height: 10),
                                    Text(
                                      "Gambar tidak tersedia",
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                );
                              },
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_outlined, size: 68, color: Colors.grey[400]),
                                const SizedBox(height: 10),
                                Text(
                                  "Belum ada gambar produk",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.red.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade50,
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Informasi Produk",
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          product.name,
                          style: TextStyle(
                            color: Colors.grey[900],
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (isWorker)
                              buildInfoChip(
                                icon: Icons.workspace_premium_rounded,
                                label: "Diskon Worker 10%",
                                color: Colors.orange.shade800,
                                backgroundColor: Colors.orange.shade50,
                              ),
                            if (isWorker) const SizedBox(width: 8),
                            buildInfoChip(
                              icon: Icons.local_shipping_outlined,
                              label: "Ambil di koperasi",
                              color: Colors.red.shade700,
                              backgroundColor: Colors.red.shade50,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Harga",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (isWorker)
                                    Text(
                                      ReceiptHelper.formatCurrency(product.price),
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 13,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  Text(
                                    ReceiptHelper.formatCurrency(getDisplayPrice()),
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            buildInfoChip(
                              icon: product.stock > 0
                                  ? Icons.inventory_2_rounded
                                  : Icons.remove_shopping_cart_rounded,
                              label: product.stock > 0
                                  ? "Stok ${product.stock}"
                                  : "Stok Habis",
                              color: product.stock > 0
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              backgroundColor: product.stock > 0
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBFA),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Deskripsi",
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                product.description.isNotEmpty
                                    ? product.description
                                    : "Produk ini belum memiliki deskripsi tambahan.",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 6,
                    shadowColor: Colors.red.shade200,
                  ),
                  onPressed: product.stock <= 0
                      ? null
                      : () async {
                          await CartService.addToCart(product);
                          if (context.mounted) {
                            await showCenteredMessage(context);
                          }
                        },
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text(
                    "Masuk ke Keranjang",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

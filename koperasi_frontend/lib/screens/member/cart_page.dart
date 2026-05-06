import 'package:flutter/material.dart';
import '../../class/cart.dart';
import '../../config/api.dart';
import '../../services/cart_service.dart';
import '../../services/product_service.dart';
import '../../services/voucher_service.dart';
import '../../utils/receipt_helper.dart';
import 'checkout_detail.dart';
import 'my_vouchers_page.dart';

class CartPage extends StatefulWidget {
  final bool isWorker;

  const CartPage({
    super.key,
    this.isWorker = false,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Color primaryRed = const Color(0xFFB71C1C);
  final Color creamBackground = const Color(0xFFFFF8F6);
  List<Cart> cartItems = [];
  List<dynamic> myVouchers = [];
  bool isLoading = true;
  int? selectedUserVoucherId;

  @override
  void initState() {
    super.initState();
    loadPageData();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> loadPageData() async {
    setState(() {
      isLoading = true;
    });

    final cartData = await CartService.getCart();
    final products = await ProductService.getProducts();
    final voucherData = await VoucherService.getMyVouchers();

    final productMap = {
      for (final product in products) product.id: product,
    };

    for (final item in cartData) {
      final latestProduct = productMap[item.id];
      if (latestProduct != null) {
        item.stock = latestProduct.stock;
        if (item.quantity > latestProduct.stock) {
          item.quantity = latestProduct.stock;
        }
      }
    }

    cartData.removeWhere((item) => item.quantity <= 0 || item.stock <= 0);

    await CartService.saveCart(cartData);

    setState(() {
      cartItems = cartData;
      myVouchers = voucherData;
      isLoading = false;
    });
  }

  Future<void> loadCart() async {
    final data = await CartService.getCart();
    final products = await ProductService.getProducts();
    final productMap = {
      for (final product in products) product.id: product,
    };

    for (final item in data) {
      final latestProduct = productMap[item.id];
      if (latestProduct != null) {
        item.stock = latestProduct.stock;
        if (item.quantity > latestProduct.stock) {
          item.quantity = latestProduct.stock;
        }
      }
    }

    data.removeWhere((item) => item.quantity <= 0 || item.stock <= 0);

    await CartService.saveCart(data);

    setState(() {
      cartItems = data;
    });
  }

  List<dynamic> getAvailableVouchers() {
    return myVouchers.where((item) => item['status'] == 'unused').toList();
  }

  dynamic getSelectedVoucher() {
    for (final item in getAvailableVouchers()) {
      if (item['id'] == selectedUserVoucherId) {
        return item;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> getOrderItems() {
    return cartItems.map((item) {
      return {
        "product_id": item.id,
        "quantity": item.quantity,
      };
    }).toList();
  }

  int getOriginalSubtotalPrice() {
    int total = 0;

    for (final item in cartItems) {
      total += (item.price * item.quantity).toInt();
    }

    return total;
  }

  int getSubtotalPrice() {
    int total = 0;

    for (final item in cartItems) {
      total += (getDisplayPrice(item.price) * item.quantity).toInt();
    }

    return total;
  }

  int getDisplayPrice(num price) {
    if (!widget.isWorker) {
      return price.toInt();
    }

    return (price * 0.9).floor();
  }

  int getWorkerDiscountAmount() {
    if (!widget.isWorker) {
      return 0;
    }

    return getOriginalSubtotalPrice() - getSubtotalPrice();
  }

  int getDiscountAmount() {
    final selectedVoucher = getSelectedVoucher();

    if (selectedVoucher == null) {
      return 0;
    }

    final voucher = selectedVoucher['voucher'];
    final discountPercent = voucher['discount_amount'] ?? 0;
    final maxDiscountAmount = voucher['max_discount_amount'] ?? 0;

    int discount = (getSubtotalPrice() * discountPercent / 100).floor();

    if (maxDiscountAmount > 0) {
      discount = discount > maxDiscountAmount ? maxDiscountAmount : discount;
    }

    if (discount > getSubtotalPrice()) {
      return getSubtotalPrice();
    }

    return discount;
  }

  int getFinalTotalPrice() {
    return getSubtotalPrice() - getDiscountAmount();
  }

  Future<void> openMyVouchersPage() async {
    final selectedId = await Navigator.push<int?>(
      context,
      MaterialPageRoute(
        builder: (_) => MyVouchersPage(
          selectedUserVoucherId: selectedUserVoucherId,
        ),
      ),
    );

    setState(() {
      selectedUserVoucherId = selectedId;
    });
  }

  Future<void> clearCartAfterCheckout() async {
    await CartService.clearCart();

    setState(() {
      cartItems.clear();
      selectedUserVoucherId = null;
    });
  }

  Future<void> onCheckoutPressed() async {
    if (cartItems.isEmpty) {
      showMessage("Keranjang kosong");
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutDetailPage(
          cartItems: cartItems,
          orderItems: getOrderItems(),
          isWorker: widget.isWorker,
          originalSubtotal: getOriginalSubtotalPrice(),
          workerDiscountAmount: getWorkerDiscountAmount(),
          voucherDiscountAmount: getDiscountAmount(),
          finalTotalPrice: getFinalTotalPrice(),
          userVoucherId: selectedUserVoucherId,
          selectedVoucher: getSelectedVoucher(),
        ),
      ),
    );

    if (result == true) {
      await clearCartAfterCheckout();
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Widget buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 96, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            "Keranjang masih kosong",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Mulai belanja yuk!",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            icon: const Icon(Icons.store),
            label: const Text(
              "Belanja Sekarang",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCartItem(Cart item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade50,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.image != null
                ? Image.network(
                    "${Api.storageUrl}${item.image}",
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[100],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[100],
                    child: Icon(Icons.image, color: Colors.grey[400]),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.isWorker)
                  Text(
                    "Rp ${item.price.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                Text(
                  "Rp ${getDisplayPrice(item.price)}",
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (widget.isWorker)
                  Text(
                    "Diskon worker 10%",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  "Stok tersedia: ${item.stock}",
                  style: TextStyle(
                    fontSize: 12,
                    color: item.stock > 0 ? Colors.grey[600] : Colors.red.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.remove, color: Colors.red.shade700, size: 20),
                        onPressed: () async {
                          await CartService.decreaseQuantity(item.id);
                          await loadCart();
                        },
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.quantity.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.add, color: Colors.red.shade700, size: 20),
                        onPressed: () async {
                          final increased = await CartService.increaseQuantity(
                            item.id,
                            maxStock: item.stock,
                          );

                          if (!increased && mounted) {
                            showMessage("Jumlah barang sudah mencapai stok");
                          }

                          await loadCart();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade500, size: 28),
            onPressed: () async {
              await CartService.removeItem(item.id);
              await loadCart();
            },
          ),
        ],
      ),
    );
  }

  Widget buildVoucherSummary({VoidCallback? onPressed}) {
    final selectedVoucher = getSelectedVoucher();
    final availableVoucherCount = getAvailableVouchers().length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.local_offer, color: primaryRed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Voucher",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedVoucher == null
                      ? availableVoucherCount == 0
                          ? "Belum ada voucher yang bisa dipakai"
                          : "Belum ada voucher yang dipilih"
                      : "${selectedVoucher['voucher']['name']} - Diskon ${selectedVoucher['voucher']['discount_amount']}% maks. ${ReceiptHelper.formatCurrency(selectedVoucher['voucher']['max_discount_amount'] ?? 0)}",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: availableVoucherCount == 0 ? null : (onPressed ?? openMyVouchersPage),
            child: Text(selectedVoucher == null ? "Pilih" : "Ganti"),
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
              fontSize: isTotal ? 15 : 14,
              color: isTotal ? primaryRed : Colors.grey[700],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 14,
              color: isTotal ? primaryRed : Colors.green.shade700,
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
      backgroundColor: creamBackground,
      appBar: AppBar(
        title: const Text(
          "Keranjang Belanja",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade700, Colors.red.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: Colors.red.shade700),
            )
          : cartItems.isEmpty
              ? buildEmptyCart()
              : Stack(
                  children: [
                    ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 170),
                      itemCount: cartItems.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return buildCartItem(cartItems[index]);
                      },
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 18,
                              offset: const Offset(0, -6),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          top: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              buildVoucherSummary(),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF5F2),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Total bayar",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            ReceiptHelper.formatCurrency(getFinalTotalPrice()),
                                            style: TextStyle(
                                              color: primaryRed,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 128,
                                    height: 54,
                                    child: ElevatedButton(
                                      onPressed: onCheckoutPressed,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryRed,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: const Text(
                                        "Lanjut",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

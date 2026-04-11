import 'package:flutter/material.dart';
import '../../class/cart.dart';
import '../../config/api.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import 'qris_member.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Cart> cartItems = [];
  bool isLoading = true;
  String? selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    loadCart();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> loadCart() async {
    setState(() {
      isLoading = true;
    });

    final data = await CartService.getCart();

    setState(() {
      cartItems = data;
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> getOrderItems() {
    return cartItems.map((item) {
      return {
        "product_id": item.id,
        "quantity": item.quantity,
      };
    }).toList();
  }

  double getTotalPrice() {
    double total = 0;

    for (final item in cartItems) {
      total += item.price * item.quantity;
    }

    return total;
  }

  Future<void> clearCartAfterCheckout() async {
    await CartService.clearCart();

    setState(() {
      cartItems.clear();
      selectedPaymentMethod = null;
    });
  }

  Future<void> checkoutCash() async {
    final response = await OrderService.createOrder(
      paymentMethod: "cash",
      items: getOrderItems(),
      totalPrice: getTotalPrice().toInt(),
      status: "pending",
    );

    if (response == null) {
      showMessage("Checkout gagal");
      return;
    }

    await clearCartAfterCheckout();
    showMessage("Checkout berhasil");
    Navigator.pop(context);
  }

  Future<void> checkoutOnline() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QrisMember(
          items: getOrderItems(),
          totalPrice: getTotalPrice().toInt(),
        ),
      ),
    );

    if (result == true) {
      setState(() {
        cartItems.clear();
        selectedPaymentMethod = null;
      });

      Navigator.pop(context);
    }
  }

  Future<void> onCheckoutPressed() async {
    if (selectedPaymentMethod == null) {
      showMessage("Pilih metode pembayaran terlebih dahulu");
      return;
    }

    if (cartItems.isEmpty) {
      showMessage("Keranjang kosong");
      return;
    }

    if (selectedPaymentMethod == "cash") {
      await checkoutCash();
      return;
    }

    await checkoutOnline();
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
                Text(
                  "Rp ${item.price.toStringAsFixed(0)}",
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
                          await CartService.increaseQuantity(item.id);
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

  Widget buildPaymentMethod() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Metode Pembayaran",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          RadioListTile<String>(
            value: "cash",
            groupValue: selectedPaymentMethod,
            title: const Text("Bayar di Tempat"),
            secondary: const Icon(Icons.money, color: Colors.green),
            onChanged: (value) {
              setState(() {
                selectedPaymentMethod = value;
              });
            },
          ),
          RadioListTile<String>(
            value: "online",
            groupValue: selectedPaymentMethod,
            title: const Text("QRIS"),
            secondary: const Icon(Icons.qr_code, color: Colors.blue),
            onChanged: (value) {
              setState(() {
                selectedPaymentMethod = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total Belanja",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                "Rp ${getTotalPrice().toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
            ],
          ),
          SizedBox(
            width: 140,
            height: 52,
            child: ElevatedButton(
              onPressed: onCheckoutPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: const Text(
                "Checkout",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: cartItems.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return buildCartItem(cartItems[index]);
                        },
                      ),
                    ),
                    buildPaymentMethod(),
                    buildCheckoutSection(),
                  ],
                ),
    );
  }
}

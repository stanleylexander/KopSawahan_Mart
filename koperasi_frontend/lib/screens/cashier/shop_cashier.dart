import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../class/product.dart';
import '../../class/cart.dart';
import '../../config/api.dart';
import '../receipt/receipt_detail_page.dart';
import 'qris_cashier.dart';

class ShopCashier extends StatefulWidget {
  const ShopCashier({super.key});

  @override
  State<ShopCashier> createState() => _ShopCashierState();
}

class _ShopCashierState extends State<ShopCashier> {
  List<Product> products = [];
  List<Product> filteredProducts = [];
  List<Cart> cartItems = [];

  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  TextEditingController customerNameController = TextEditingController();
  String? selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    fetchProducts();
    loadCart();
  }

  @override
  void dispose() {
    searchController.dispose();
    customerNameController.dispose();
    super.dispose();
  }

  // 🔥 GET PRODUCT
  void fetchProducts() async {
    List<Product> data = await ProductService.getProducts();
    setState(() {
      products = data;
      filteredProducts = data;
      isLoading = false;
    });
  }

  // 🔥 LOAD CART
  Future<void> loadCart() async {
    List<Cart> data = await CartService.getCart();
    setState(() {
      cartItems = data;
    });
  }

  // 🔍 SEARCH
  void searchProduct(String keyword) {
    final results = products.where((product) {
      return product.name.toLowerCase().contains(keyword.toLowerCase());
    }).toList();

    setState(() {
      filteredProducts = results;
    });
  }

  // 🛒 OPEN CART
  void openCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => buildCartSheet(),
    );
  }

  // 🧾 CART UI
  Widget buildCartSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {

        double total = 0;
        for (var item in cartItems) {
          total += item.price * item.quantity;
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              const Text(
                "Keranjang",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              // 🔥 LIST ITEM
              Expanded(
                child: cartItems.isEmpty
                    ? const Center(child: Text("Keranjang kosong"))
                    : ListView.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.name),
                            subtitle: Text("Rp ${item.price}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [

                                // ➖
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () async {
                                    await CartService.decreaseQuantity(item.id);
                                    await loadCart();
                                    setModalState(() {});
                                  },
                                ),

                                Text("${item.quantity}"),

                                // ➕
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () async {
                                    await CartService.increaseQuantity(item.id);
                                    await loadCart();
                                    setModalState(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 10),

              // 🔥 TOTAL
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    "Rp ${total.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 🔥 METODE PEMBAYARAN
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: customerNameController,
                    decoration: const InputDecoration(
                      labelText: "Nama pelanggan (opsional)",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Metode Pembayaran",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  RadioListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Cash"),
                    value: "cash",
                    groupValue: selectedPaymentMethod,
                    onChanged: (value) {
                      setModalState(() {
                        selectedPaymentMethod = value.toString();
                      });
                    },
                  ),

                  RadioListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("QRIS"),
                    value: "online",
                    groupValue: selectedPaymentMethod,
                    onChanged: (value) {
                      setModalState(() {
                        selectedPaymentMethod = value.toString();
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 🔥 BUTTON CHECKOUT
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {

                    if (cartItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Keranjang kosong")),
                      );
                      return;
                    }

                    if (selectedPaymentMethod == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Pilih metode pembayaran terlebih dahulu"),
                        ),
                      );
                      return;
                    }

                    final items = cartItems.map((item) {
                      return {
                        "product_id": item.id,
                        "quantity": item.quantity,
                      };
                    }).toList();

                    double total = 0;
                    for (var item in cartItems) {
                      total += item.price * item.quantity;
                    }

                    if (selectedPaymentMethod == "cash") {

                      final response = await OrderService.createOrder(
                        paymentMethod: "cash",
                        items: items,
                        totalPrice: total.toInt(),
                        status: "diambil",
                        orderSource: "offline",
                        customerName: customerNameController.text.trim(),
                      );

                      if (response != null) {
                        await CartService.clearCart();

                        setState(() {
                          cartItems.clear();
                          selectedPaymentMethod = null;
                        });

                        customerNameController.clear();
                        Navigator.pop(context);

                        final receipt = response["receipt"];

                        if (receipt is Map<String, dynamic> && mounted) {
                          await Navigator.push(
                            this.context,
                            MaterialPageRoute(
                              builder: (_) => ReceiptDetailPage(
                                initialReceipt: receipt,
                                showPrintButton: true,
                                autoPrintOnOpen: true,
                              ),
                            ),
                          );
                        }

                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text("Checkout berhasil (Cash)")),
                        );
                      } else {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text("Checkout gagal")),
                        );
                      }

                    }

                    else if (selectedPaymentMethod == "online") {

                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QrisCashier(
                            items: items,
                            totalPrice: total.toInt(),
                            customerName: customerNameController.text.trim(),
                          ),
                        ),
                      );

                      if (result == true) {
                        setState(() {
                          cartItems.clear();
                          selectedPaymentMethod = null;
                        });

                        customerNameController.clear();
                        Navigator.pop(context);
                      }
                    }

                  },

                  // 🔥 STYLE HARUS DI SINI
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),

                  // 🔥 CHILD HANYA SEKALI
                  child: const Text("Checkout"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🧱 PRODUCT CARD
  Widget productCard(Product product) {
    return InkWell(
      onTap: () async {
        await CartService.addToCart(product);
        loadCart();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ditambahkan ke keranjang")),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade50,
              blurRadius: 6,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: product.image != null
                    ? Image.network(
                        "${Api.storageUrl}${product.image}",
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image),
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Rp ${product.price.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Stok: ${product.stock}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // 🧩 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("POS Kasir"),
        backgroundColor: Colors.red.shade700,
      ),

      body: Column(
        children: [

          // 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: searchProduct,
              decoration: InputDecoration(
                hintText: "Cari produk...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 🛍 LIST PRODUCT
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Colors.red.shade700,
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredProducts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.8,
                    ),
                    itemBuilder: (context, index) {
                      return productCard(filteredProducts[index]);
                    },
                  ),
          ),
        ],
      ),

      // 🛒 FLOATING BUTTON
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openCart,
        label: Text("Cart (${cartItems.length})"),
        icon: const Icon(Icons.shopping_cart),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }
}

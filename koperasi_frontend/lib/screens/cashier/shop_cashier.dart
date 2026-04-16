import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../class/product.dart';
import '../../class/cart.dart';
import '../../config/api.dart';
import '../receipt/receipt_detail_page.dart';
import 'barcode_scanner_page.dart';
import 'qris_cashier.dart';
import '../../utils/permission_helper.dart';

class ShopCashier extends StatefulWidget {
  const ShopCashier({super.key});

  @override
  State<ShopCashier> createState() => _ShopCashierState();
}

class _ShopCashierState extends State<ShopCashier> with TickerProviderStateMixin {
  final GlobalKey _cartButtonKey = GlobalKey();
  List<Product> products = [];
  List<Product> filteredProducts = [];
  List<Cart> cartItems = [];

  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  TextEditingController amountPaidController = TextEditingController();
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
    amountPaidController.dispose();
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

  Product? findProductByBarcode(String barcode) {
    try {
      return products.firstWhere(
        (product) => product.barcode.trim() == barcode.trim(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> openBarcodeScanner() async {
    final isGranted = await PermissionHelper.requestCameraPermission();

    if (!isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Izin kamera diperlukan")),
      );
      return;
    }

    final scannedBarcode = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerPage(),
      ),
    );

    if (scannedBarcode == null || scannedBarcode.isEmpty) return;

    final product = findProductByBarcode(scannedBarcode);

    if (product == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Barcode $scannedBarcode belum terdaftar di produk"),
        ),
      );
      return;
    }

    await Future.wait([
      CartService.addToCart(product),
      animateProductToCartFromCenter(),
    ]);
    await loadCart();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${product.name} masuk ke keranjang"),
      ),
    );
  }

  // 🛒 OPEN CART
  void openCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => buildCartSheet(),
    );
  }

  Future<void> animateProductToCart(BuildContext sourceContext) async {
    final overlay = Overlay.of(context);
    final sourceRenderBox = sourceContext.findRenderObject() as RenderBox?;
    final targetRenderBox = _cartButtonKey.currentContext?.findRenderObject() as RenderBox?;

    if (sourceRenderBox == null || targetRenderBox == null) {
      return;
    }

    final sourcePosition = sourceRenderBox.localToGlobal(Offset.zero);
    final targetPosition = targetRenderBox.localToGlobal(Offset.zero);
    final sourceSize = sourceRenderBox.size;
    final targetSize = targetRenderBox.size;

    final startOffset = Offset(
      sourcePosition.dx + (sourceSize.width / 2) - 12,
      sourcePosition.dy + (sourceSize.height / 2) - 12,
    );
    final endOffset = Offset(
      targetPosition.dx + (targetSize.width / 2) - 12,
      targetPosition.dy + (targetSize.height / 2) - 12,
    );

    await animateFlyingIcon(startOffset, endOffset);
  }

  Future<void> animateProductToCartFromCenter() async {
    final overlay = Overlay.of(context);
    final targetRenderBox = _cartButtonKey.currentContext?.findRenderObject() as RenderBox?;

    if (overlay == null || targetRenderBox == null) {
      return;
    }

    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (overlayBox == null) {
      return;
    }

    final targetPosition = targetRenderBox.localToGlobal(Offset.zero);
    final targetSize = targetRenderBox.size;
    final startOffset = Offset(
      overlayBox.size.width / 2 - 12,
      overlayBox.size.height / 2 - 40,
    );
    final endOffset = Offset(
      targetPosition.dx + (targetSize.width / 2) - 12,
      targetPosition.dy + (targetSize.height / 2) - 12,
    );

    await animateFlyingIcon(startOffset, endOffset);
  }

  Future<void> animateFlyingIcon(Offset startOffset, Offset endOffset) async {
    final overlay = Overlay.of(context);
    if (overlay == null) {
      return;
    }

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    final curvedAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: curvedAnimation,
          builder: (context, child) {
            final value = curvedAnimation.value;
            final dx = startOffset.dx + ((endOffset.dx - startOffset.dx) * value);
            final dyBase = startOffset.dy + ((endOffset.dy - startOffset.dy) * value);
            final arcHeight = 60 * (1 - ((value - 0.5) * (value - 0.5) * 4));
            final scale = 1 - (0.35 * value);
            final opacity = value > 0.9 ? (1 - value) * 10 : 1.0;

            return Positioned(
              left: dx,
              top: dyBase - arcHeight,
              child: IgnorePointer(
                child: Opacity(
                  opacity: opacity.clamp(0, 1),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.shade100,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.shopping_bag_rounded,
                        size: 16,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    overlay.insert(overlayEntry);
    await controller.forward();
    overlayEntry.remove();
    controller.dispose();
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

                  if (selectedPaymentMethod == "cash") ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountPaidController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Uang yang diberikan customer",
                        border: OutlineInputBorder(),
                        prefixText: "Rp ",
                      ),
                    ),
                  ],
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

                    if (selectedPaymentMethod == "cash" &&
                        amountPaidController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Masukkan uang yang diberikan customer"),
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
                      final amountPaid = int.tryParse(amountPaidController.text.trim());

                      if (amountPaid == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Nominal uang tidak valid")),
                        );
                        return;
                      }

                      final response = await OrderService.createOrder(
                        paymentMethod: "cash",
                        items: items,
                        totalPrice: total.toInt(),
                        status: "diambil",
                        orderSource: "offline",
                        amountPaid: amountPaid,
                      );

                      if (response != null) {
                        await CartService.clearCart();

                        setState(() {
                          cartItems.clear();
                          selectedPaymentMethod = null;
                        });

                        amountPaidController.clear();
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
                          ),
                        ),
                      );

                      if (result == true) {
                        setState(() {
                          cartItems.clear();
                          selectedPaymentMethod = null;
                        });

                        amountPaidController.clear();
                        Navigator.pop(context);
                      }
                    }

                  },

                  // 🔥 STYLE HARUS DI SINI
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),

                  // 🔥 CHILD HANYA SEKALI
                  child: const Text(
                    "Checkout",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
    return Container(
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

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: Builder(
                      builder: (buttonContext) {
                        return ElevatedButton.icon(
                          onPressed: () async {
                            await Future.wait([
                              CartService.addToCart(product),
                              animateProductToCart(buttonContext),
                            ]);
                            await loadCart();

                            if (!mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("${product.name} masuk ke keranjang")),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                          label: const Text(
                            "Tambah",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          ],
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
        actions: [
          IconButton(
            onPressed: openBarcodeScanner,
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: "Scan Barcode",
          ),
        ],
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
        key: _cartButtonKey,
        onPressed: openCart,
        label: Text(
          "Cart (${cartItems.length})",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        icon: const Icon(Icons.shopping_cart, color: Colors.white),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }
}

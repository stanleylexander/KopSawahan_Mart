import 'package:flutter/material.dart';
import '../../class/product.dart';
import '../../config/api.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/product_service.dart';
import '../../services/user_service.dart';
import 'cart_page.dart';
import 'notification_page.dart';
import 'product_detail.dart';
import 'voucher_page.dart';

class Home extends StatefulWidget {
  final bool isWorkerAccount;

  const Home({
    super.key,
    this.isWorkerAccount = false,
  });

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final Color primaryRed = const Color(0xFFB71C1C);
  final Color softRed = const Color(0xFFD32F2F);
  final Color creamBackground = const Color(0xFFFFF8F6);
  final GlobalKey _cartButtonKey = GlobalKey();
  List<Product> products = [];
  List<Product> filteredProducts = [];
  int userPoints = 0;
  bool isLoading = true;
  bool isWorker = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isWorker = widget.isWorkerAccount;
    loadHomeData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchProducts() async {
    final data = await ProductService.getProducts();

    products = data;
    applySearch(searchController.text);
  }

  int getDisplayPrice(int price) {
    if (!isWorker) {
      return price;
    }

    return (price * 0.9).floor();
  }

  String getRoleLabel() {
    return isWorker ? "Worker" : "Member";
  }

  Future<void> fetchUserData() async {
    final token = await AuthService.getToken();
    final role = await AuthService.getRole();
    final currentIsWorker = role == 'worker';

    if (token == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        userPoints = 0;
        isWorker = currentIsWorker || widget.isWorkerAccount;
      });
      return;
    }

    final user = await UserService.getProfile(token);

    if (!mounted) {
      return;
    }

    setState(() {
      userPoints = user?.points ?? 0;
      isWorker = user?.role == 'worker' || currentIsWorker || widget.isWorkerAccount;
    });
  }

  void applySearch(String keyword) {
    if (keyword.isEmpty) {
      filteredProducts = List<Product>.from(products);
      return;
    }

    filteredProducts = products.where((product) {
      return product.name.toLowerCase().contains(keyword.toLowerCase());
    }).toList();
  }

  Future<void> loadHomeData() async {
    setState(() {
      isLoading = true;
    });

    await Future.wait([
      fetchProducts(),
      fetchUserData(),
    ]);

    setState(() {
      isLoading = false;
    });
  }

  Future<void> openVoucherPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VoucherPage(),
      ),
    );

    await loadHomeData();
  }

  Future<void> openCartPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartPage(isWorker: isWorker),
      ),
    );

    await loadHomeData();
  }

  Future<void> openProductDetail(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetail(
          product: product,
          isWorker: isWorker,
        ),
      ),
    );

    await loadHomeData();
  }

  Future<void> openNotificationPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationPage(),
      ),
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
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.shopping_bag_rounded,
                        color: primaryRed,
                        size: 16,
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

    try {
      await controller.forward();
    } finally {
      overlayEntry.remove();
      controller.dispose();
    }
  }

  Future<void> handleAddToCart(Product product, BuildContext sourceContext) async {
    await Future.wait([
      CartService.addToCart(product),
      animateProductToCart(sourceContext),
    ]);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Produk ditambahkan ke keranjang"),
      ),
    );
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            applySearch(value);
          });
        },
        decoration: InputDecoration(
          hintText: "Cari produk...",
          prefixIcon: Icon(Icons.search, color: primaryRed),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.red.shade100),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: softRed, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.red.shade100),
          ),
        ),
      ),
    );
  }

  Widget buildWelcomeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryRed, softRed, const Color(0xFFFF8A65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade100,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  getRoleLabel(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isWorker) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    "Diskon 10%",
                    style: TextStyle(
                      color: primaryRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Belanja kebutuhan koperasi jadi lebih mudah",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isWorker
                ? "Semua produk langsung dapat potongan 10% sebelum voucher dipakai."
                : "Cari produk favoritmu, kumpulkan poin, lalu tukarkan voucher dengan cepat.",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPointCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: openVoucherPage,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, const Color(0xFFFFEBEE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade50,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.stars, color: primaryRed, size: 26),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Poin Anda",
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                    Text(
                      userPoints.toString(),
                      style: TextStyle(
                        color: primaryRed,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  "Lihat voucher",
                  style: TextStyle(
                    color: primaryRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios, color: primaryRed, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Daftar Produk",
                style: TextStyle(
                  color: primaryRed,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Pilih produk yang kamu butuhkan",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Text(
              "${filteredProducts.length} item",
              style: TextStyle(
                color: primaryRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProductGrid() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Colors.red.shade700),
      );
    }

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "Produk tidak ditemukan",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredProducts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.73,
      ),
      itemBuilder: (context, index) {
        return productCard(filteredProducts[index]);
      },
    );
  }

  Widget productCard(Product product) {
    return InkWell(
      onTap: () => openProductDetail(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.red.shade100, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade50,
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: product.image != null
                    ? Image.network(
                        "${Api.storageUrl}${product.image}",
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[100],
                            child: const Icon(Icons.image_not_supported, size: 50),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[100],
                        child: const Icon(Icons.image, size: 50),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      "Stok ${product.stock}",
                      style: TextStyle(
                        fontSize: 11,
                        color: primaryRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isWorker)
                    Text(
                      "Rp ${product.price.toStringAsFixed(0)}",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    "Rp ${getDisplayPrice(product.price)}",
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (isWorker)
                    Text(
                      "Diskon worker 10%",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.stock > 0 ? "Siap dibeli" : "Stok habis",
                          style: TextStyle(
                            fontSize: 12,
                            color: product.stock > 0 ? Colors.green.shade700 : Colors.red.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Builder(
                        builder: (buttonContext) {
                          return InkWell(
                            onTap: () => handleAddToCart(product, buttonContext),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: primaryRed,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.add_shopping_cart,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildScrollableContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          buildSearchBar(),
          buildWelcomeCard(),
          buildPointCard(),
          buildSectionHeader(),
          buildProductGrid(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "KopSawahan Mart",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              isWorker ? "Harga khusus worker aktif" : "Belanja cepat dan nyaman",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: primaryRed,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryRed, softRed],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: openNotificationPage,
          ),
          IconButton(
            key: _cartButtonKey,
            icon: const Icon(Icons.shopping_cart),
            onPressed: openCartPage,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadHomeData,
        child: buildScrollableContent(),
      ),
    );
  }
}

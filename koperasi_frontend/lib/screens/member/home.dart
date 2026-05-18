import 'package:flutter/material.dart';
import '../../class/product.dart';
import '../../config/api.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/product_service.dart';
import '../../services/user_service.dart';
import '../../services/voucher_service.dart';
import 'cart_page.dart';
import 'my_vouchers_page.dart';
import 'notification_page.dart';
import 'my_level_page.dart';
import 'product_page.dart';
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
  int? _userPoints = 0;
  int? _availableVoucherCount = 0;
  int? _annualSpend = 0;
  String? _membershipLevel = "Bronze";
  bool isLoading = true;
  bool isWorker = false;
  TextEditingController searchController = TextEditingController();
  static const int productsPerPage = 10;
  int currentProductPage = 0;

  int get userPointsValue => _userPoints ?? 0;
  int get availableVoucherCountValue => _availableVoucherCount ?? 0;
  int get annualSpendValue => _annualSpend ?? 0;
  String get membershipLevelValue {
    final value = _membershipLevel;
    if (value == null || value.isEmpty || value == 'undefined' || value == 'null') {
      return "Bronze";
    }
    return value;
  }

  int get totalProductPages {
    if (filteredProducts.isEmpty) {
      return 1;
    }

    return (filteredProducts.length / productsPerPage).ceil();
  }

  List<Product> get pagedProducts {
    final startIndex = currentProductPage * productsPerPage;

    if (startIndex >= filteredProducts.length) {
      return [];
    }

    final endIndex = (startIndex + productsPerPage) > filteredProducts.length
        ? filteredProducts.length
        : startIndex + productsPerPage;

    return filteredProducts.sublist(startIndex, endIndex);
  }

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

  Future<void> showAllProducts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductPage(isWorker: isWorker),
      ),
    );

    await loadHomeData();
  }

  Color getLevelColor() {
    switch (membershipLevelValue.toLowerCase()) {
      case "platinum":
        return const Color(0xFF455A64);
      case "gold":
        return const Color(0xFFC69214);
      case "silver":
        return const Color(0xFF78909C);
      default:
        return const Color(0xFF8D5A3B);
    }
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
        _userPoints = 0;
        isWorker = currentIsWorker || widget.isWorkerAccount;
      });
      return;
    }

    final user = await UserService.getProfile(token);
    final vouchers = await VoucherService.getMyVouchers();
    if (!mounted) {
      return;
    }

    setState(() {
      _userPoints = user?.points ?? 0;
      _availableVoucherCount = vouchers.where((item) {
        return item is Map && item['status'] == 'unused' && item['voucher'] is Map;
      }).length;
      _annualSpend = user?.annualSpend ?? 0;
      _membershipLevel = user?.membershipLevel ?? "Bronze";
      isWorker = user?.role == 'worker' || currentIsWorker || widget.isWorkerAccount;
    });
  }

  void applySearch(String keyword) {
    if (keyword.isEmpty) {
      filteredProducts = List<Product>.from(products);
      currentProductPage = 0;
      return;
    }

    filteredProducts = products.where((product) {
      return product.name.toLowerCase().contains(keyword.toLowerCase());
    }).toList();
    currentProductPage = 0;
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

  Future<void> openMyVouchersPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyVouchersPage(
          selectedUserVoucherId: null,
          allowSelection: false,
        ),
      ),
    );

    await loadHomeData();
  }

  Future<void> openMyLevelPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyLevelPage(
          annualSpend: annualSpendValue,
          membershipLevel: membershipLevelValue,
        ),
      ),
    );
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
    final currentQuantity = await CartService.getProductQuantity(product.id);

    if (product.stock <= 0 || currentQuantity >= product.stock) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Jumlah produk di keranjang sudah mencapai stok"),
        ),
      );
      return;
    }

    final added = await CartService.addToCart(product);

    if (!added) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Produk tidak bisa ditambahkan lagi"),
        ),
      );
      return;
    }

    if (!sourceContext.mounted) {
      return;
    }

    await animateProductToCart(sourceContext);

    if (!mounted) {
      return;
    }
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
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryRed, softRed, const Color(0xFFFF8A65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade100,
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                getRoleLabel(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
          const SizedBox(height: 10),
          const Text(
            "Belanja kebutuhan koperasi jadi lebih mudah",
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isWorker
                ? "Semua produk langsung dapat potongan 10% sebelum voucher dipakai."
                : "Cari produk favoritmu, kumpulkan poin, lalu tukarkan voucher dengan cepat.",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPointCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade50,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryRed, softRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: const Text(
              "KOPBENEFIT",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: buildPointSection(
                    title: "Points",
                    value: userPointsValue.toString(),
                    subtitle: "Tukar voucher >",
                    onTap: openVoucherPage,
                  ),
                ),
                buildDivider(),
                Expanded(
                  child: buildPointSection(
                    title: "Voucher",
                    value: availableVoucherCountValue.toString(),
                    subtitle: "Voucher saya >",
                    onTap: openMyVouchersPage,
                  ),
                ),
                buildDivider(),
                Expanded(
                  child: buildPointSection(
                    title: "Level",
                    value: membershipLevelValue,
                    subtitle: "Lihat level >",
                    valueColor: getLevelColor(),
                    onTap: openMyLevelPage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDivider() {
    return Container(
      width: 1,
      height: 62,
      color: Colors.grey.shade200,
    );
  }

  Widget buildPointSection({
    required String title,
    required String value,
    required String subtitle,
    VoidCallback? onTap,
    Color? valueColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: valueColor ?? primaryRed,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
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
          TextButton(
            onPressed: showAllProducts,
            child: Text(
              "Lihat semua",
              style: TextStyle(
                color: primaryRed,
                fontWeight: FontWeight.bold,
                fontSize: 14,
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
      itemCount: pagedProducts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.73,
      ),
      itemBuilder: (context, index) {
        return productCard(pagedProducts[index]);
      },
    );
  }

  Widget buildProductPagination() {
    if (filteredProducts.length <= productsPerPage) {
      return const SizedBox.shrink();
    }

    final pageNumber = currentProductPage + 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: currentProductPage == 0
                  ? null
                  : () {
                      setState(() {
                        currentProductPage--;
                      });
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryRed,
                side: BorderSide(color: Colors.red.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.chevron_left),
              label: const Text("Sebelumnya"),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "$pageNumber / $totalProductPages",
            style: TextStyle(
              color: primaryRed,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: currentProductPage >= totalProductPages - 1
                  ? null
                  : () {
                      setState(() {
                        currentProductPage++;
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.chevron_right),
              label: const Text("Berikutnya"),
            ),
          ),
        ],
      ),
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
                            onTap: product.stock > 0
                                ? () => handleAddToCart(product, buttonContext)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: product.stock > 0 ? primaryRed : Colors.grey.shade400,
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
          buildPointCard(),
          buildWelcomeCard(),
          buildSectionHeader(),
          buildProductGrid(),
          buildProductPagination(),
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

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

class _HomeState extends State<Home> {
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

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            applySearch(value);
          });
        },
        decoration: InputDecoration(
          hintText: "Cari produk...",
          prefixIcon: Icon(Icons.search, color: Colors.red.shade700),
          filled: true,
          fillColor: Colors.red.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade700, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade200),
          ),
        ),
      ),
    );
  }

  Widget buildPointCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: openVoucherPage,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade700, Colors.red.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade200,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.stars, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Poin Anda",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      userPoints.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
          ],
        ),
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredProducts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade50,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                      Text(
                        "Stok: ${product.stock}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          await CartService.addToCart(product);

                          if (!context.mounted) {
                            return;
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Produk ditambahkan ke keranjang"),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.add_shopping_cart,
                            size: 16,
                            color: Colors.red.shade700,
                          ),
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "KopSawahan Mart",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: openNotificationPage,
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: openCartPage,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadHomeData,
        child: Column(
          children: [
            buildSearchBar(),
            buildPointCard(),
            const SizedBox(height: 16),
            Expanded(
              child: buildProductGrid(),
            ),
          ],
        ),
      ),
    );
  }
}

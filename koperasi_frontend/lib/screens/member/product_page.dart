import 'package:flutter/material.dart';
import '../../class/product.dart';
import '../../config/api.dart';
import '../../services/product_service.dart';
import '../../utils/receipt_helper.dart';
import 'product_detail.dart';

class ProductPage extends StatefulWidget {
  final bool isWorker;

  const ProductPage({
    super.key,
    this.isWorker = false,
  });

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final Color primaryRed = const Color(0xFFB71C1C);
  final Color softBackground = const Color(0xFFFFF8F6);
  final TextEditingController searchController = TextEditingController();
  List<Product> products = [];
  List<Product> filteredProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadProducts() async {
    final data = await ProductService.getProducts();

    if (!mounted) {
      return;
    }

    setState(() {
      products = data;
      filteredProducts = data;
      isLoading = false;
    });
  }

  void applySearch(String keyword) {
    final search = keyword.toLowerCase();

    setState(() {
      filteredProducts = products.where((product) {
        return product.name.toLowerCase().contains(search);
      }).toList();
    });
  }

  int getDisplayPrice(Product product) {
    if (!widget.isWorker) {
      return product.price;
    }

    return (product.price * 0.9).floor();
  }

  Future<void> openProductDetail(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetail(
          product: product,
          isWorker: widget.isWorker,
        ),
      ),
    );

    await loadProducts();
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: TextField(
        controller: searchController,
        onChanged: applySearch,
        decoration: InputDecoration(
          hintText: "Cari semua produk...",
          prefixIcon: Icon(Icons.search, color: primaryRed),
          suffixIcon: searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    searchController.clear();
                    applySearch("");
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.red.shade100),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.red.shade100),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.red.shade700, width: 2),
          ),
        ),
      ),
    );
  }

  Widget buildProductCard(Product product) {
    return InkWell(
      onTap: () => openProductDetail(product),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.red.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade50,
              blurRadius: 12,
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
                      )
                    : Container(
                        color: Colors.grey[100],
                        child: Icon(Icons.image_outlined, color: Colors.grey[400], size: 40),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.isWorker)
                    Text(
                      ReceiptHelper.formatCurrency(product.price),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    ReceiptHelper.formatCurrency(getDisplayPrice(product)),
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: product.stock > 0 ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Stok ${product.stock}",
                        style: TextStyle(
                          color: product.stock > 0 ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
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

  Widget buildBody() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryRed));
    }

    if (filteredProducts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Icon(Icons.search_off_rounded, size: 76, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "Produk tidak ditemukan",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Coba kata kunci lain supaya produk lebih mudah ditemukan.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: filteredProducts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.66,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemBuilder: (context, index) {
        return buildProductCard(filteredProducts[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        title: const Text("Semua Produk"),
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: loadProducts,
        child: Column(
          children: [
            buildSearchBar(),
            Expanded(child: buildBody()),
          ],
        ),
      ),
    );
  }
}

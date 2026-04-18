import 'package:flutter/material.dart';
import '../../class/product.dart';
import '../../services/product_service.dart';
import 'product_detail_admin.dart';
import 'add_product_admin.dart';
import '../drawer/drawer_admin.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {

  late Future<List<Product>> futureProducts;
  TextEditingController? _searchController;

  TextEditingController get searchController {
    _searchController ??= TextEditingController();
    return _searchController!;
  }

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  @override
  void dispose() {
    _searchController?.dispose();
    super.dispose();
  }

  void loadProducts() {
    futureProducts = ProductService.getProducts();
  }

  Future<void> refreshData() async {
    setState(() {
      loadProducts();
    });
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AdminDrawer(),
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Daftar Produk",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red.shade700,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
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

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: searchController,
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: "Cari produk...",
                prefixIcon: Icon(Icons.search, color: Colors.red.shade700),
                filled: true,
                fillColor: Colors.red.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.red.shade100),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.red.shade100),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.red.shade700, width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: Colors.red.shade700,
              backgroundColor: Colors.white,
              onRefresh: refreshData,
              child: buildProductList(),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductPage()),
          );
        },
        backgroundColor: Colors.red.shade700,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ================= PRODUCT LIST =================
  Widget buildProductList() {
    return FutureBuilder<List<Product>>(
      future: futureProducts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.red.shade700),
                SizedBox(height: 16),
                Text(
                  "Memuat produk...",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final allProducts = snapshot.data ?? [];
        final keyword = searchController.text.toLowerCase();
        final products = allProducts.where((product) {
          return product.name.toLowerCase().contains(keyword);
        }).toList();

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  "Tidak ada produk",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: products.length,
          separatorBuilder: (context, index) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductCard(product);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => DetailProductPage(product: product),
          ),
        );

        if (result == true && mounted) {
          refreshData();
        }
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade100, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade50,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.image != null && product.image!.isNotEmpty
                  ? Image.network(
                      ProductService.getImageUrl(product.image),
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 88,
                        height: 88,
                        color: Colors.grey[100],
                        child: Icon(Icons.image_not_supported,
                            color: Colors.grey[400]),
                      ),
                    )
                  : Container(
                      width: 88,
                      height: 88,
                      color: Colors.grey[100],
                      child: Icon(Icons.image, color: Colors.grey[400]),
                    ),
            ),

            SizedBox(width: 16),

            // INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(Icons.price_change,
                          size: 16, color: Colors.red.shade700),
                      SizedBox(width: 4),
                      Text(
                        "Rp ${product.price.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(Icons.inventory_2,
                          size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        "Stok: ${product.stock}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4),

                  Text(
                    product.description ?? "Tidak ada deskripsi",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // 🔥 ACTION BUTTON (BARU)
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailProductPage(product: product),
                      ),
                    );

                    if (result == true && mounted) {
                      refreshData();
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // TODO: DELETE PRODUCT
                    showDeleteDialog(product.id);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= DIALOG DELETE PRODUCT =================
  void showDeleteDialog(int productId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Hapus Produk"),
          content: Text("Apakah kamu yakin ingin menghapus produk ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                print("Delete product $productId");
              },
              child: Text("Hapus"),
            ),
          ],
        );
      },
    );
  }
}

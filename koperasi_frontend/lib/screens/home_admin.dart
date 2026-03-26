import 'package:flutter/material.dart';
import '../class/product.dart';
import '../services/product_service.dart';
import 'product_detail_admin.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {

  late Future<List<Product>> futureProducts;

  @override
  void initState() {
    super.initState();
    loadProducts();
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
      appBar: AppBar(
        title: const Text("Dashboard Admin"),
        centerTitle: true,
      ),

      body: RefreshIndicator(
        onRefresh: refreshData,
        child: FutureBuilder<List<Product>>(
          future: futureProducts,
          builder: (context, snapshot) {

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final products = snapshot.data ?? [];

            if (products.isEmpty) {
              return const Center(
                child: Text("Tidak ada produk"),
              );
            }

            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {

                final product = products[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailProductPage(product: product),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 4,
                          color: Colors.black12,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),

                    child: Row(
                      children: [

                        // IMAGE
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: product.image != null &&
                                  product.image!.isNotEmpty
                              ? Image.network(
                                  ProductService.getImageUrl(product.image),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image),
                                ),
                        ),

                        const SizedBox(width: 12),

                        // INFO
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text("Harga: Rp ${product.price}"),
                              Text("Stok: ${product.stock}"),
                              Text(
                                product.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // ACTION BUTTON
                        Column(
                          children: [

                            IconButton(
                              onPressed: () {
                                // TODO: Edit
                              },
                              icon: const Icon(Icons.edit, color: Colors.blue),
                            ),

                            IconButton(
                              onPressed: () {
                                // TODO: Delete
                              },
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),

                          ],
                        )

                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
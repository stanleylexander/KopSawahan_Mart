import 'package:flutter/material.dart';
import '../config/api.dart';
import '../class/product.dart';
import '../class/point.dart';
import '../services/product_service.dart';
import '../services/point_service.dart';
import '../services/cart_service.dart';
import 'product_detail.dart';
import 'cart_page.dart';

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Product> products = [];
  List<Product> filteredProducts = [];
  Point? userPoint;
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProducts();
    fetchPoint();
  }

  void fetchProducts() async {
    List<Product> data = await ProductService.getProducts();
    setState(() {
      products = data;
      filteredProducts = data;
      isLoading = false;
    });
  }

  void fetchPoint() async {
    Point? point = await PointService.getUserPoint(1);
    setState(() {
      userPoint = point;
    });
  }

  void searchProduct(String keyword) {
    final results = products.where((product) {
      final name = product.name.toLowerCase();
      final search = keyword.toLowerCase();
      return name.contains(search);
    }).toList();
    setState(() {
      filteredProducts = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "KopSawahan Mart",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red.shade700,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartPage()
                )
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: searchProduct,
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
          ),

          // POINT CARD
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(16),
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
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Poin Anda",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        Text(
                          userPoint == null ? "0" : userPoint!.point.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
              ],
            ),
          ),
          SizedBox(height: 16),

          // LIST PRODUCT
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Colors.red.shade700,
                    ),
                  )
                : filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              "Produk tidak ditemukan",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredProducts.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return productCard(product);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget productCard(Product product) {
    return InkWell(

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetail(product: product),
          ),
        );
      },

      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade50,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // IMAGE
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: product.image != null
                    ? Image.network(
                        "${Api.storageUrl}${product.image}",
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[100],
                          child: Icon(Icons.image_not_supported, size: 50),
                        ),
                      )
                    : Container(
                        color: Colors.grey[100],
                        child: Icon(Icons.image, size: 50),
                      ),
              ),
            ),

            // INFO
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.red.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 4),

                  Text(
                    "Rp ${product.price.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  SizedBox(height: 4),

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

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Produk ditambahkan ke keranjang"),
                            ),
                          );

                        },

                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
}

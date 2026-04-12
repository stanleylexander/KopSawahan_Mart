import 'package:flutter/material.dart';
import '../../class/product.dart';
import '../../config/api.dart';
import '../../services/cart_service.dart';

class ProductDetail extends StatelessWidget {
  final Product product;
  final bool isWorker;

  const ProductDetail({
    super.key,
    required this.product,
    this.isWorker = false,
  });

  int getDisplayPrice() {
    if (!isWorker) {
      return product.price;
    }

    return (product.price * 0.9).floor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          product.name,
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
          // IMAGE HERO
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // IMAGE PRODUCT
                  Container(
                    width: double.infinity,
                    height: 300,
                    margin: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: product.image != null
                          ? Image.network(
                              "${Api.storageUrl}${product.image}",
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported, size: 64, color: Colors.grey[400]),
                                    Text("Gambar tidak tersedia", style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(child: CircularProgressIndicator(color: Colors.red.shade700));
                              },
                            )
                          : Icon(Icons.image, size: 80, color: Colors.grey[400]),
                    ),
                  ),

                  // PRODUCT INFO CARD
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.shade100, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade50,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // NAME
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                        SizedBox(height: 12),

                        // PRICE & STOCK ROW
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isWorker)
                                  Text(
                                    "Rp ${product.price.toStringAsFixed(0)}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                Text(
                                  "Rp ${getDisplayPrice()}",
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (isWorker)
                                  Text(
                                    "Diskon worker 10%",
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: product.stock > 0 ? Colors.green.shade100 : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    product.stock > 0 ? Icons.inventory_2 : Icons.inventory,
                                    size: 18,
                                    color: product.stock > 0 ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "${product.stock}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: product.stock > 0 ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  // DESCRIPTION CARD
                  if (product.description.isNotEmpty)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.shade100, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.shade50,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description_outlined, color: Colors.red.shade700, size: 24),
                              SizedBox(width: 12),
                              Text(
                                "Deskripsi",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade800,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            product.description,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // BOTTOM BUTTON ADD TO CART
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  shadowColor: Colors.red.shade300,
                ),
                onPressed: () async {
                  await CartService.addToCart(product);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Ditambahkan ke keranjang!"),
                        backgroundColor: Colors.green.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                icon: Icon(Icons.add_shopping_cart),
                label: Text(
                  "Tambah ke Keranjang",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

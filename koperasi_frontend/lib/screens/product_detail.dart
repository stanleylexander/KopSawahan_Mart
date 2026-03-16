import 'package:flutter/material.dart';
import '../class/product.dart';
import '../config/api.dart';
import '../services/cart_service.dart';

class ProductDetail extends StatelessWidget {

  final Product product;

  const ProductDetail({super.key, required this.product});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: Text(product.name),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),

      body: Column(
        children: [

          Expanded(
            child: SingleChildScrollView(

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // IMAGE PRODUCT
                  product.image != null
                      ? Image.network(
                          "${Api.storageUrl}${product.image}",
                          width: double.infinity,
                          height: 280,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 280,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.image, size: 80),
                          ),
                        ),

                  const SizedBox(height: 12),

                  // PRODUCT INFO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // NAME
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // PRICE
                        Text(
                          "Rp ${product.price.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // STOCK
                        Text(
                          "Stok tersedia: ${product.stock}",
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),

                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // DESCRIPTION
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Text(
                          "Deskripsi Produk",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          product.description ?? "Tidak ada deskripsi",
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),

                      ],
                    ),
                  ),

                  const SizedBox(height: 80),

                ],
              ),
            ),
          ),

          // BUTTON ADD TO CART
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,

            child: SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                onPressed: () async {

                  await CartService.addToCart(product);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Produk ditambahkan ke keranjang"),
                    ),
                  );

                },

                child: const Text(
                  "Tambah ke Keranjang",
                  style: TextStyle(fontSize: 16),
                ),

              ),
            ),
          )

        ],
      ),
    );
  }
}
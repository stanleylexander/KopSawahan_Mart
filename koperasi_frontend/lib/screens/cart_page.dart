import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../class/cart.dart';
import '../config/api.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {

  List<Cart> cartItems = [];

  @override
  void initState() {
    super.initState();
    loadCart();
  }

  void loadCart() async {
    List<Cart> data = await CartService.getCart();

    setState(() {
      cartItems = data;
    });
  }

  double getTotalPrice(){
    double total = 0;

    for(var item in cartItems){
      total += item.price * item.quantity;
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Keranjang"),
        backgroundColor: Colors.red,
      ),

      body: cartItems.isEmpty
          ? const Center(
              child: Text("Keranjang masih kosong"),
            )
          : Column(
              children: [

                /// LIST PRODUCT
                Expanded(
                  child: ListView.builder(

                    itemCount: cartItems.length,

                    itemBuilder: (context,index){

                      final item = cartItems[index];

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                            )
                          ],
                        ),

                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [

                            /// IMAGE
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.image != null
                                  ? Image.network(
                                      "${Api.storageUrl}${item.image}",
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 70,
                                      height: 70,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image),
                                    ),
                            ),

                            const SizedBox(width: 12),

                            /// INFO PRODUK
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    "Rp ${item.price.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                ],
                              ),
                            ),

                            /// QUANTITY + DELETE
                            Column(
                              children: [

                                Row(
                                  children: [

                                    /// MINUS
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () async {

                                        await CartService.decreaseQuantity(item.id);
                                        loadCart();

                                      },
                                    ),

                                    Text(
                                      item.quantity.toString(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    /// PLUS
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () async {

                                        await CartService.increaseQuantity(item.id);
                                        loadCart();

                                      },
                                    ),

                                    /// DELETE
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {

                                        await CartService.removeItem(item.id);
                                        loadCart();

                                      },
                                    )

                                  ],
                                ),
                              ],
                            )

                          ],
                        ),
                      );

                    },
                  ),
                ),

                /// TOTAL PRICE + CHECKOUT
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 5,
                        color: Colors.black12
                      )
                    ]
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      Text(
                        "Total: Rp ${getTotalPrice().toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                        ),
                      ),

                      ElevatedButton(
                        onPressed: () {

                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red
                        ),
                        child: const Text("Checkout"),
                      )

                    ],
                  ),
                )

              ],
            ),

    );
  }
}
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

                Expanded(
                  child: ListView.builder(

                    itemCount: cartItems.length,

                    itemBuilder: (context,index){

                      final item = cartItems[index];

                      return ListTile(

                        leading: item.image != null
                            ? Image.network(
                                "${Api.storageUrl}${item.image}",
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image),

                        title: Text(item.name),

                        subtitle: Text(
                            "Rp ${item.price.toStringAsFixed(0)}"),

                        trailing: Text("x${item.quantity}"),

                      );
                    },
                  ),
                ),

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
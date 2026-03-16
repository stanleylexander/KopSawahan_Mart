import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../class/cart.dart';
import '../class/product.dart';

class CartService {

  static const String cartKey = "cart";

  // GET CART
  static Future<List<Cart>> getCart() async {

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(cartKey);

    if(data == null) return [];

    List decoded = jsonDecode(data);

    return decoded.map((e) => Cart.fromJson(e)).toList();
  }

  // ADD TO CART
  static Future<void> addToCart(Product product) async {

    final prefs = await SharedPreferences.getInstance();

    List<Cart> cart = await getCart();

    int index = cart.indexWhere((item) => item.id == product.id);

    if(index != -1){
      cart[index].quantity += 1;
    }else{
      cart.add(
        Cart(
          id: product.id,
          name: product.name,
          price: product.price,
          image: product.image,
          quantity: 1,
        )
      );
    }

    String encoded =
        jsonEncode(cart.map((e) => e.toJson()).toList());

    await prefs.setString(cartKey, encoded);
  }

  // CLEAR CART
  static Future<void> clearCart() async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(cartKey);

  }

}
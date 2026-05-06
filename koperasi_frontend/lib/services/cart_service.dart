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

  // SAVE CART
  static Future<void> saveCart(List<Cart> cart) async {

    final prefs = await SharedPreferences.getInstance();
    String encoded = jsonEncode(cart.map((e) => e.toJson()).toList());
    await prefs.setString(cartKey, encoded);
  }

  static Future<int> getProductQuantity(int productId) async {
    final cart = await getCart();
    final index = cart.indexWhere((item) => item.id == productId);

    if (index == -1) {
      return 0;
    }

    return cart[index].quantity;
  }

  // ADD TO CART
  static Future<bool> addToCart(Product product) async {

    final prefs = await SharedPreferences.getInstance();
    List<Cart> cart = await getCart();
    int index = cart.indexWhere((item) => item.id == product.id);

    if(index != -1){
      cart[index].stock = product.stock;

      if (cart[index].quantity >= product.stock) {
        return false;
      }

      cart[index].quantity += 1;
    }else{
      if (product.stock <= 0) {
        return false;
      }

      cart.add(
        Cart(
          id: product.id,
          name: product.name,
          price: product.price,
          image: product.image,
          stock: product.stock,
          quantity: 1,
        )
      );
    }

    String encoded =
        jsonEncode(cart.map((e) => e.toJson()).toList());

    await prefs.setString(cartKey, encoded);
    return true;
  }

  // INCREASE QTY
  static Future<bool> increaseQuantity(int productId, {int? maxStock}) async {

    List<Cart> cart = await getCart();
    int index = cart.indexWhere((item) => item.id == productId);

    if(index != -1){
      final stockLimit = maxStock ?? cart[index].stock;

      if (stockLimit > 0) {
        cart[index].stock = stockLimit;
      }

      if (stockLimit > 0 && cart[index].quantity >= stockLimit) {
        return false;
      }

      cart[index].quantity += 1;
    }

    await saveCart(cart);
    return true;
  }

  // DECREASE QTY
  static Future<void> decreaseQuantity(int productId) async {

    List<Cart> cart = await getCart();
    int index = cart.indexWhere((item) => item.id == productId);

    if(index != -1){

      if(cart[index].quantity > 1){
        cart[index].quantity -= 1;
      }else{
        cart.removeAt(index);
      }

    }

    await saveCart(cart);
  }

  // REMOVE ITEM
  static Future<void> removeItem(int productId) async {

    List<Cart> cart = await getCart();
    cart.removeWhere((item) => item.id == productId);
    await saveCart(cart);
  }

  // CLEAR CART
  static Future<void> clearCart() async {

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cartKey);

  }

}

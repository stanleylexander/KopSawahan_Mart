import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api.dart';

class OrderService {

  // CREATE ORDER 
  static Future<Map<String, dynamic>?> createOrder({
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    required int totalPrice,
    required String status,
  }) async {

    String? token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse("${Api.baseUrl}/orders"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "payment_method": paymentMethod,
        "items": items,
        "total_price": totalPrice,
        "status": status,
      }),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body); // 🔥 selalu return data
    } else {
      return null;
    }
  }

  // GET ORDERS 
  static Future<List<dynamic>> getOrders() async {
    String? token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse("${Api.baseUrl}/orders"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  // COMPLETE ORDER
  static Future<bool> completeOrder(int orderId) async {
    String? token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse("${Api.baseUrl}/orders/$orderId/complete"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    return response.statusCode == 200;
  }
}
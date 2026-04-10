import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api.dart';

class OrderService {

  // CREATE ORDER 
  static Future<bool> createOrder({required String paymentMethod, required List<Map<String, dynamic>> items,}) async {
    
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
      }),
    );

    return response.statusCode == 200;
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
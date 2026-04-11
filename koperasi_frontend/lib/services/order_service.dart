import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api.dart';

class OrderService {
  static Future<Map<String, String>> _getHeaders({bool withJson = false}) async {
    final token = await AuthService.getToken();

    return {
      if (withJson) "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Future<Map<String, dynamic>?> createOrder({
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    required int totalPrice,
    required String status,
  }) async {
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/orders"),
      headers: await _getHeaders(withJson: true),
      body: jsonEncode({
        "payment_method": paymentMethod,
        "items": items,
        "total_price": totalPrice,
        "status": status,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    return null;
  }

  static Future<List<dynamic>> getOrders() async {
    final response = await http.get(
      Uri.parse("${Api.baseUrl}/orders"),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<bool> completeOrder(int orderId) async {
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/orders/$orderId/complete"),
      headers: await _getHeaders(),
    );

    return response.statusCode == 200;
  }
}

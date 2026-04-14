import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api.dart';

class ReceiptService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();

    return {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    };
  }

  static Future<List<dynamic>> getMyReceipts() async {
    final response = await http.get(
      Uri.parse("${Api.baseUrl}/receipts"),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<Map<String, dynamic>?> getReceiptDetail(int receiptId) async {
    final response = await http.get(
      Uri.parse("${Api.baseUrl}/receipts/$receiptId"),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  static Future<bool> markAsPrinted(int receiptId) async {
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/receipts/$receiptId/printed"),
      headers: await _getHeaders(),
    );

    return response.statusCode == 200;
  }
}

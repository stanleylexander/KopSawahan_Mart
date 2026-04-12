import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api.dart';

class NotificationService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();

    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  static Future<List<dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse("${Api.baseUrl}/notifications"),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<bool> markAsRead(int notificationId) async {
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/notifications/$notificationId/read"),
      headers: await _getHeaders(),
    );

    return response.statusCode == 200;
  }
}

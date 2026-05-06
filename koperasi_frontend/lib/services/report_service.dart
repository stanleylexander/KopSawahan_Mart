import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';

class ReportService {
  static Future<Map<String, dynamic>> getSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse("${Api.baseUrl}/reports/summary"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        }
      } else {
        debugPrint("ERROR getSummary: ${response.body}");
      }

      return {};
    } catch (e) {
      debugPrint("Error getSummary: $e");
      return {};
    }
  }
}

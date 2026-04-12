import 'dart:convert';
import 'package:http/http.dart' as http;
import '../class/voucher.dart';
import '../config/api.dart';
import 'auth_service.dart';

class VoucherService {
  static Future<Map<String, String>> _getHeaders({bool withJson = false}) async {
    final token = await AuthService.getToken();

    return {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
      if (withJson) "Content-Type": "application/json",
    };
  }

  static Future<List<Voucher>> getVouchers() async {
    try {
      final response = await http.get(
        Uri.parse("${Api.baseUrl}/vouchers"),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((e) => Voucher.fromJson(e)).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> createVoucher({
    required String name,
    required String description,
    required int requiredPoints,
    required int discountPercent,
    required int maxDiscountAmount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${Api.baseUrl}/vouchers"),
        headers: await _getHeaders(withJson: true),
        body: jsonEncode({
          "name": name,
          "description": description,
          "required_points": requiredPoints,
          "discount_amount": discountPercent,
          "max_discount_amount": maxDiscountAmount,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateVoucher({
    required int id,
    required String name,
    required String description,
    required int requiredPoints,
    required int discountPercent,
    required int maxDiscountAmount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${Api.baseUrl}/vouchers/$id"),
        headers: await _getHeaders(withJson: true),
        body: jsonEncode({
          "name": name,
          "description": description,
          "required_points": requiredPoints,
          "discount_amount": discountPercent,
          "max_discount_amount": maxDiscountAmount,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteVoucher(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("${Api.baseUrl}/vouchers/$id"),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> redeemVoucher(int voucherId) async {
    try {
      final response = await http.post(
        Uri.parse("${Api.baseUrl}/vouchers/$voucherId/redeem"),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> getMyVouchers() async {
    try {
      final response = await http.get(
        Uri.parse("${Api.baseUrl}/my-vouchers"),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}

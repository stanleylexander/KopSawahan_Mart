import 'dart:convert';
import 'dart:io';
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
    required int minimumPurchaseAmount,
    required String expiresAt,
    File? imageFile,
  }) async {
    try {
      final token = await AuthService.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("${Api.baseUrl}/vouchers"),
      );

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      request.fields.addAll({
        "name": name,
        "description": description,
        "required_points": requiredPoints.toString(),
        "discount_amount": discountPercent.toString(),
        "max_discount_amount": maxDiscountAmount.toString(),
        "minimum_purchase_amount": minimumPurchaseAmount.toString(),
      });

      if (expiresAt.isNotEmpty) {
        request.fields["expired_at"] = expiresAt;
      }

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      final response = await request.send();

      return response.statusCode == 200 || response.statusCode == 201;
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
    required int minimumPurchaseAmount,
    required String expiresAt,
    File? imageFile,
  }) async {
    try {
      final token = await AuthService.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("${Api.baseUrl}/vouchers/$id"),
      );

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      request.fields.addAll({
        "name": name,
        "description": description,
        "required_points": requiredPoints.toString(),
        "discount_amount": discountPercent.toString(),
        "max_discount_amount": maxDiscountAmount.toString(),
        "minimum_purchase_amount": minimumPurchaseAmount.toString(),
      });

      if (expiresAt.isNotEmpty) {
        request.fields["expired_at"] = expiresAt;
      }

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      final response = await request.send();

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static String getImageUrl(String? image) {
    if (image == null || image.isEmpty) {
      return "";
    }

    return "${Api.storageUrl}$image";
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
        final data = jsonDecode(response.body);

        if (data is! List) {
          return [];
        }

        return data.whereType<Map>().map((item) {
          final normalized = Map<String, dynamic>.from(item);
          final voucher = normalized['voucher'];

          if (voucher is Map) {
            normalized['voucher'] = Map<String, dynamic>.from(voucher);
          } else {
            normalized['voucher'] = <String, dynamic>{};
          }

          return normalized;
        }).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}

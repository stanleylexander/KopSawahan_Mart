import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import '../class/voucher.dart';
import 'auth_service.dart';

class VoucherService {

  // GET ALL VOUCHERS
  static Future<List<Voucher>> getVouchers() async {
    try {
      String? token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse("${Api.baseUrl}/vouchers"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => Voucher.fromJson(e)).toList();
      } else {
        print("ERROR getVouchers: ${response.body}");
        return [];
      }

    } catch (e) {
      print("Error getVouchers: $e");
      return [];
    }
  }

  // REDEEM VOUCHER
  static Future<bool> redeemVoucher(int voucherId) async {
    try {
      String? token = await AuthService.getToken();

      final response = await http.post(
        Uri.parse("${Api.baseUrl}/vouchers/$voucherId/redeem"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("ERROR redeem: ${response.body}");
        return false;
      }

    } catch (e) {
      print("Error redeemVoucher: $e");
      return false;
    }
  }

  // GET MY VOUCHERS
  static Future<List<dynamic>> getMyVouchers() async {
    try {
      String? token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse("${Api.baseUrl}/my-vouchers"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("ERROR myVouchers: ${response.body}");
        return [];
      }

    } catch (e) {
      print("Error getMyVouchers: $e");
      return [];
    }
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:koperasi_frontend/class/user.dart';
import '../config/api.dart';

class UserService {

  // USER
  static Future<List<User>> getUsers(String token) async {
    try {
      final response = await http.get(
        Uri.parse("${Api.baseUrl}/users"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => User.fromJson(e)).toList();
      } else {
        print("ERROR getUsers: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error getUsers: $e");
      return [];
    }
  }

  // UPDATE ROLE
  static Future<bool> updateUserRole(int userId, String role, String token) async {
    try {
      final response = await http.post(
        Uri.parse("${Api.baseUrl}/users/$userId/role"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "role": role,
        }),
      );

      print("STATUS updateRole: ${response.statusCode}");

      if (response.statusCode == 200) {
        return true;
      } else {
        print("ERROR updateRole: ${response.body}");
        return false;
      }

    } catch (e) {
      print("EXCEPTION updateRole: $e");
      return false;
    }
  }
}
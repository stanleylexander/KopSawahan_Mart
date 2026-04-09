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


  // PROFILE
  static Future<User?> getProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse("${Api.baseUrl}/profile"), 
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        print("ERROR getProfile: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error getProfile: $e");
      return null;
    }
  }


  // UPDATE PROFILE
  static Future<bool> updateProfile(
    String token,
    String name,
    String email,
    String phone,
    String dateOfBirth,
    String gender,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("${Api.baseUrl}/profile"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name": name,
          "email": email,
          "phone_number": phone,
          "date_of_birth": dateOfBirth,
          "gender": gender,
        }),
      );

      print("STATUS updateProfile: ${response.statusCode}");
      print("BODY updateProfile: ${response.body}");

      if (response.statusCode == 200) {
        return true;
      } else {
        print("ERROR updateProfile: ${response.body}");
        return false;
      }
    } catch (e) {
      print("EXCEPTION updateProfile: $e");
      return false;
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
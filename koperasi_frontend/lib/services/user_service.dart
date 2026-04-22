import 'dart:convert';
import 'dart:io';
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
    File? imageFile,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("${Api.baseUrl}/profile"),
      );

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      request.fields.addAll({
        "name": name,
        "email": email,
        "phone_number": phone,
        "gender": gender,
      });

      if (dateOfBirth.isNotEmpty) {
        request.fields["date_of_birth"] = dateOfBirth;
      }

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
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

  static Future<bool> saveDeviceToken(String token, String? deviceToken) async {
    try {
      final response = await http.post(
        Uri.parse("${Api.baseUrl}/device-token"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "device_token": deviceToken,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error saveDeviceToken: $e");
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

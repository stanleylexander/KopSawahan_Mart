import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';
import 'push_notification_service.dart';

class AuthService {

  // REGISTER
  static Future<bool> register(
    String name,
    String email,
    String password,
    String phone,
    String birthDate,
    String gender,
  ) async {

    try{

      final response = await http.post(
        Uri.parse("${Api.baseUrl}/register"),
        headers: {
          "Accept": "application/json"
        },
        body: {
          "name": name,
          "email": email,
          "password": password,
          "phone_number": phone,
          "date_of_birth": birthDate,
          "gender": gender
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("Register gagal: ${response.body}");
        return false;
      }

    } catch (e) {
      print("Error register: $e");
      return false;
    }
  } 

    


  // LOGIN
  static Future<bool> login(String email, String password) async {

    try {

      final response = await http.post(
        Uri.parse("${Api.baseUrl}/login"),
        headers: {
          "Accept": "application/json"
        },
        body: {
          "email": email,
          "password": password
        },
      );

      print("Response API:");
      print(response.body);

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        String token = data['token'];
        String role = data['user']['role'];
        int userId = data['user']['id'];

        SharedPreferences prefs =
            await SharedPreferences.getInstance();

        await prefs.setString("token", token);
        await prefs.setString("role", role);
        await prefs.setInt("userId", userId);
        await PushNotificationService.syncDeviceTokenWithServer(apiToken: token);

        return true;

      } else {
        return false;
      }

    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }


  // GET TOKEN
  static Future<String?> getToken() async {
    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // GET ROLE
  static Future<String?> getRole() async {
    SharedPreferences prefs =
        await SharedPreferences.getInstance();
    return prefs.getString("role");
  }

  // LOGOUT
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';

    try {
      await PushNotificationService.clearDeviceTokenFromServer(apiToken: token);
      await http.post(
        Uri.parse("${Api.baseUrl}/logout"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );
    } catch (e) {
      print("Logout error: $e");
    }

    await prefs.clear(); 
  }
  
}

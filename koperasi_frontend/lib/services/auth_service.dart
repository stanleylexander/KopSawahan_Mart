import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  // GANTI dengan IP Laravel Anda
  static const String baseUrl = "http://192.168.1.10:8000/api";

  // LOGIN
  static Future<bool> login(String email, String password) async {

    final response = await http.post(

      Uri.parse("$baseUrl/login"),

      headers: {
        "Accept": "application/json"
      },

      body: {
        "email": email,
        "password": password
      },

    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      String token = data['token'];

      SharedPreferences prefs =
      await SharedPreferences.getInstance();

      await prefs.setString("token", token);

      return true;

    } else {

      return false;

    }

  }


  // GET TOKEN
  static Future<String?> getToken() async {

    SharedPreferences prefs =
    await SharedPreferences.getInstance();

    return prefs.getString("token");

  }


  // LOGOUT
  static Future<void> logout() async {

    SharedPreferences prefs =
    await SharedPreferences.getInstance();

    await prefs.remove("token");

  }

}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';

class AuthService {

  //REGISTER
  static Future<bool> register(
    String name,
    String email,
    String password,
    String phone,
    String birthDate,
    String gender,
  ) async {

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

    print("REGISTER RESPONSE:");
    print(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      return false;
    }
  }


  // LOGIN
  static Future<bool> login(
    String email, 
    String password
  ) async {

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
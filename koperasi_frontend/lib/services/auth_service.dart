import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';
import 'push_notification_service.dart';

class AuthService {
  static const Duration sessionTimeout = Duration(days: 7);
  static const String _tokenKey = "token";
  static const String _roleKey = "role";
  static const String _userIdKey = "userId";
  static const String _sessionExpiresAtKey = "session_expires_at";

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  static String _errorMessage(Map<String, dynamic> data, String fallback) {
    final message = data["message"];

    if (message is String && message.isNotEmpty) {
      return message;
    }

    final errors = data["errors"];

    if (errors is Map && errors.isNotEmpty) {
      final firstError = errors.values.first;

      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
    }

    return fallback;
  }

  static Future<void> _saveSession({
    required String token,
    required String role,
    required int userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAt = DateTime.now().add(sessionTimeout);

    await prefs.setString(_tokenKey, token);
    await prefs.setString(_roleKey, role);
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_sessionExpiresAtKey, expiresAt.toIso8601String());
  }

  static Future<void> clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_sessionExpiresAtKey);
  }

  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final role = prefs.getString(_roleKey);
    final expiresAtText = prefs.getString(_sessionExpiresAtKey);

    if (token == null || token.isEmpty || role == null || role.isEmpty) {
      return false;
    }

    if (expiresAtText == null || expiresAtText.isEmpty) {
      await clearLocalSession();
      return false;
    }

    final expiresAt = DateTime.tryParse(expiresAtText);

    if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
      await clearLocalSession();
      return false;
    }

    return true;
  }

  static Future<String?> getValidRole() async {
    final valid = await isSessionValid();

    if (!valid) {
      return null;
    }

    return getRole();
  }

  static Future<DateTime?> getSessionExpiresAt() async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAtText = prefs.getString(_sessionExpiresAtKey);

    if (expiresAtText == null || expiresAtText.isEmpty) {
      return null;
    }

    return DateTime.tryParse(expiresAtText);
  }

  static Future<Map<String, dynamic>> requestRegisterOtp(
    String name,
    String email,
    String password,
    String phone,
    String birthDate,
    String gender,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("${Api.baseUrl}/register/request-otp"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "phone_number": phone,
          "date_of_birth": birthDate,
          "gender": gender,
        }),
      );

      final data = _decodeResponse(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "message": _errorMessage(data, "Kode OTP berhasil dikirim"),
        };
      } else {
        return {
          "success": false,
          "message": _errorMessage(data, "Gagal mengirim OTP"),
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Terjadi error saat mengirim OTP",
      };
    }
  }

  static Future<Map<String, dynamic>> verifyRegisterOtp(
    String email,
    String otpCode,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("${Api.baseUrl}/register/verify-otp"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "otp_code": otpCode,
        }),
      );

      final data = _decodeResponse(response);

      if (response.statusCode == 200) {
        final token = data['token'];
        final role = data['user']['role'];
        final userId = data['user']['id'];

        await _saveSession(token: token, role: role, userId: userId);
        await PushNotificationService.syncDeviceTokenWithServer(apiToken: token);

        return {
          "success": true,
          "message": _errorMessage(data, "Register berhasil"),
        };
      }

      return {
        "success": false,
        "message": _errorMessage(data, "Verifikasi OTP gagal"),
      };
    } catch (e) {
      return {
        "success": false,
        "message": "Terjadi error saat verifikasi OTP",
      };
    }
  }

  static Future<Map<String, dynamic>> requestForgotPasswordOtp(
    String email,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("${Api.baseUrl}/forgot-password/request-otp"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
        }),
      );

      final data = _decodeResponse(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "message": _errorMessage(data, "Kode OTP berhasil dikirim"),
        };
      }

      return {
        "success": false,
        "message": _errorMessage(data, "Gagal mengirim OTP"),
      };
    } catch (e) {
      return {
        "success": false,
        "message": "Terjadi error saat mengirim OTP",
      };
    }
  }

  static Future<Map<String, dynamic>> resetPasswordWithOtp(
    String email,
    String otpCode,
    String password,
    String passwordConfirmation,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("${Api.baseUrl}/forgot-password/reset"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "otp_code": otpCode,
          "password": password,
          "password_confirmation": passwordConfirmation,
        }),
      );

      final data = _decodeResponse(response);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": _errorMessage(data, "Password berhasil diubah"),
        };
      }

      return {
        "success": false,
        "message": _errorMessage(data, "Gagal mengubah password"),
      };
    } catch (e) {
      return {
        "success": false,
        "message": "Terjadi error saat mengubah password",
      };
    }
  }

  // LOGIN
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("${Api.baseUrl}/login"),
        headers: {"Accept": "application/json"},
        body: {"email": email, "password": password},
      );

      print("Response API:");
      print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        String token = data['token'];
        String role = data['user']['role'];
        int userId = data['user']['id'];

        await _saveSession(token: token, role: role, userId: userId);
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // GET ROLE
  static Future<String?> getRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  // LOGOUT
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    String token = prefs.getString(_tokenKey) ?? '';

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

    await clearLocalSession();
  }
}

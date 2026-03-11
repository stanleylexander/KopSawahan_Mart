import 'dart:convert';
import 'package:http/http.dart' as http;
import '../class/point.dart';

class PointService {

  static const String baseUrl = "http://192.168.1.10:8000/api";

  //POINT
  static Future<Point?> getUserPoint(int userId) async {

    final response =await http.get(Uri.parse("$baseUrl/points/$userId"));

    if(response.statusCode == 200){
      final data = jsonDecode(response.body);
      return Point.fromJson(data);
    }else{
      return null;
    }
  }

}
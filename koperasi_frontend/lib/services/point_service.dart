import 'dart:convert';
import 'package:http/http.dart' as http;
import '../class/point.dart';
import '../config/api.dart';

class PointService {

  //POINT
  static Future<Point?> getUserPoint(int userId) async {

    final response =await http.get(Uri.parse("${Api.baseUrl}/points/$userId"));

    if(response.statusCode == 200){
      final data = jsonDecode(response.body);
      return Point.fromJson(data);
    }else{
      return null;
    }
  }

}
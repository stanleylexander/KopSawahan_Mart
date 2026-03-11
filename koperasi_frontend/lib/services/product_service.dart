import 'dart:convert';
import 'package:http/http.dart' as http;
import '../class/product.dart';

class ProductService {

  static const String baseUrl = "http://192.168.1.10:8000/api";


  //PRODUCT
  static Future<List<Product>> getProducts() async {

    final response = await http.get(Uri.parse("$baseUrl/products"));

    if(response.statusCode == 200){
      List data = jsonDecode(response.body);
      return data.map((e) => Product.fromJson(e)).toList();
    }else{
      return [];
    }
  }

}
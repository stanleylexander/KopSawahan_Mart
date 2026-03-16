import 'dart:convert';
import 'package:http/http.dart' as http;
import '../class/product.dart';
import '../config/api.dart';

class ProductService {

  //PRODUCT
  static Future<List<Product>> getProducts() async {

    try{

      final response = await http.get(Uri.parse("${Api.baseUrl}/products"));

      if(response.statusCode == 200){
        List data = jsonDecode(response.body);
        return data.map((e) => Product.fromJson(e)).toList();
      } else{
        return [];
      }

    } catch(e){
      print("Error getProducts: $e");
      return [];
    }
    
  }

  //AMBIL GAMBAR
  static String getImageUrl(String? image){

    if(image == null){
      return "";
    }
    return "${Api.storageUrl}$image";

  }

  //PRODUK DETAIL
  static Future<Product?> getProductDetail(int id) async {
    
    try{

      final response = await http.get(Uri.parse("${Api.baseUrl}/products/$id"));

      if(response.statusCode == 200){
        final data = jsonDecode(response.body);
        return Product.fromJson(data);
      } else{
        return null;
      }

    } catch(e){
      print("Error getProducts: $e");
      return null;
    }
    
  }

}
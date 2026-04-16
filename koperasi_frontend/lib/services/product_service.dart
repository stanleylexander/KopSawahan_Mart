import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;
import '../class/product.dart';
import '../config/api.dart';
import 'auth_service.dart';

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
      print("Error getProductDetail: $e");
      return null;
    }
    
  }


  // TAMBAH PRODUK
  static Future<bool> addProduct(
    String name,
    String barcode,
    String price,
    String stock,
    String description,
    File? image,
  ) async {
    try {
      String? token = await AuthService.getToken();

      var request = http.MultipartRequest('POST', Uri.parse("${Api.baseUrl}/products"),);

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      request.fields.addAll({
        "name": name,
        "barcode": barcode,
        "price": price,
        "stock": stock,
        "description": description,
      });

      if (image != null) {
        final mimeTypeData = lookupMimeType(image.path)?.split('/');

        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            image.path,
            contentType: MediaType(
              mimeTypeData![0],
              mimeTypeData[1],
            ),
          ),
        );
      }

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final responseFinal = await response.stream.bytesToString();
        print("addProduct failed: $responseFinal");
        return false;
      }

    } catch (e) {
      print("Error addProduct: $e");
      return false;
    }
  }


  //UPDATE PRODUK
  static Future<bool> updateProduct(
    int id,
    String name,
    String barcode,
    String price,
    String stock,
    String description,
    File? image,
  ) async {
    try {
      String? token = await AuthService.getToken();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${Api.baseUrl}/products/$id"),
      );

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      request.fields.addAll({
        "name": name,
        "barcode": barcode,
        "price": price,
        "stock": stock,
        "description": description,
      });

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final respStr = await response.stream.bytesToString();
        print("Update failed: $respStr");
        return false;
      }

    } catch (e) {
      print("Error updateProduct: $e");
      return false;
    }
  }
}

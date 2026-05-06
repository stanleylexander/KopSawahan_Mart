class Cart {

  final int id;
  final String name;
  final int price;
  final String? image;
  int stock;
  int quantity;

  Cart({
    required this.id,
    required this.name,
    required this.price,
    this.image,
    required this.stock,
    required this.quantity,
  });

  Map<String,dynamic> toJson(){
    return {
      "id":id,
      "name":name,
      "price":price,
      "image":image,
      "stock":stock,
      "quantity":quantity
    };
  }

  factory Cart.fromJson(Map<String,dynamic> json){
    return Cart(
      id: json["id"],
      name: json["name"],
      price: (json["price"] as num).toInt(),
      image: json["image"],
      stock: (json["stock"] as num?)?.toInt() ?? 0,
      quantity: json["quantity"],
    );
  }

}

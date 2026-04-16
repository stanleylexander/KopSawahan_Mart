class Product {

  final int id;
  final String name;
  final String barcode;
  final String description;
  final int price;
  final int stock;
  final String? image;

  Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.description,
    required this.price,
    required this.stock,
    this.image
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      barcode: json['barcode'] ?? "",
      description: json['description'] ?? "",
      price: json['price'],
      stock: json['stock'],
      image: json['image']
    );
  }

}

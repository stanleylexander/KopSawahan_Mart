import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../class/product.dart';
import '../../services/product_service.dart';

class DetailProductPage extends StatefulWidget {
  final Product product;

  const DetailProductPage({super.key, required this.product});

  @override
  State<DetailProductPage> createState() => _DetailProductPageState();
}

class _DetailProductPageState extends State<DetailProductPage> {

  late TextEditingController nameController;
  late TextEditingController barcodeController;
  late TextEditingController priceController;
  late TextEditingController stockController;
  late TextEditingController descController;

  File? imageFile;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.product.name);
    barcodeController = TextEditingController(text: widget.product.barcode);
    priceController = TextEditingController(text: widget.product.price.toString());
    stockController = TextEditingController(text: widget.product.stock.toString());
    descController = TextEditingController(text: widget.product.description);
  }

  // PICK IMAGE
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  // UPDATE PRODUCT
  Future<void> updateProduct() async {
    bool success = await ProductService.updateProduct(
      widget.product.id,
      nameController.text,
      barcodeController.text,
      priceController.text,
      stockController.text,
      descController.text,
      imageFile,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Produk berhasil diupdate")),
      );
      Navigator.pop(context, true); // kembali + refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal update produk")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detail Produk")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // IMAGE
            GestureDetector(
              onTap: pickImage,
              child: imageFile != null
                  ? Image.file(imageFile!, height: 150)
                  : Image.network(
                      ProductService.getImageUrl(widget.product.image),
                      height: 150,
                    ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nama"),
            ),

            TextField(
              controller: barcodeController,
              decoration: const InputDecoration(labelText: "Barcode"),
            ),

            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "Harga"),
            ),

            TextField(
              controller: stockController,
              decoration: const InputDecoration(labelText: "Stok"),
            ),

            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Deskripsi"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: updateProduct,
              child: const Text("Update Produk"),
            )

          ],
        ),
      ),
    );
  }
}

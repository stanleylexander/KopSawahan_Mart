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
  final Color primaryRed = const Color(0xFFB71C1C);
  final Color softBackground = const Color(0xFFFFF8F6);

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

  @override
  void dispose() {
    nameController.dispose();
    barcodeController.dispose();
    priceController.dispose();
    stockController.dispose();
    descController.dispose();
    super.dispose();
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

  InputDecoration buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade100),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primaryRed, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        title: const Text("Edit Produk"),
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade50,
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Data Produk",
                    style: TextStyle(
                      color: primaryRed,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: GestureDetector(
                      onTap: pickImage,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 150,
                          height: 150,
                          color: Colors.grey[100],
                          child: imageFile != null
                              ? Image.file(imageFile!, fit: BoxFit.cover)
                              : Image.network(
                                  ProductService.getImageUrl(widget.product.image),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      "Ketuk gambar untuk mengganti",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nameController,
                    decoration: buildInputDecoration("Nama Produk"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: barcodeController,
                    decoration: buildInputDecoration("Barcode"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: buildInputDecoration("Harga"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: buildInputDecoration("Stok"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 4,
                    decoration: buildInputDecoration("Deskripsi"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: updateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Simpan Perubahan",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

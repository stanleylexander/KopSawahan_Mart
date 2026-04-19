import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/voucher_service.dart';

class AddVoucherAdminPage extends StatefulWidget {
  const AddVoucherAdminPage({super.key});

  @override
  State<AddVoucherAdminPage> createState() => _AddVoucherAdminPageState();
}

class _AddVoucherAdminPageState extends State<AddVoucherAdminPage> {
  final Color primaryRed = const Color(0xFFB71C1C);
  final Color softBackground = const Color(0xFFFFF8F6);

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final pointController = TextEditingController();
  final discountPercentController = TextEditingController();
  final maxDiscountController = TextEditingController();
  final minimumPurchaseController = TextEditingController();
  final expiredAtController = TextEditingController();
  File? imageFile;

  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    pointController.dispose();
    discountPercentController.dispose();
    maxDiscountController.dispose();
    minimumPurchaseController.dispose();
    expiredAtController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) {
      return;
    }

    setState(() {
      imageFile = File(picked.path);
    });
  }

  Future<void> save() async {
    setState(() => isLoading = true);

    final success = await VoucherService.createVoucher(
      name: nameController.text,
      description: descriptionController.text,
      requiredPoints: int.tryParse(pointController.text) ?? 0,
      discountPercent: int.tryParse(discountPercentController.text) ?? 0,
      maxDiscountAmount: int.tryParse(maxDiscountController.text) ?? 0,
      minimumPurchaseAmount: int.tryParse(minimumPurchaseController.text) ?? 0,
      expiresAt: expiredAtController.text,
      imageFile: imageFile,
    );

    setState(() => isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Voucher berhasil dibuat")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal membuat voucher")),
      );
    }
  }

  Future<void> pickExpiredDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) {
      return;
    }

    expiredAtController.text = pickedDate.toIso8601String().split('T').first;
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
        title: const Text("Tambah Voucher"),
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
                    "Voucher Baru",
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
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.image_outlined, size: 38, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text("Upload Gambar"),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      "Ketuk gambar untuk menambahkan foto voucher",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nameController,
                    decoration: buildInputDecoration("Nama Voucher"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: buildInputDecoration("Deskripsi Voucher"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pointController,
                    keyboardType: TextInputType.number,
                    decoration: buildInputDecoration("Required Points"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: discountPercentController,
                    keyboardType: TextInputType.number,
                    decoration: buildInputDecoration("Diskon (%)"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: maxDiscountController,
                    keyboardType: TextInputType.number,
                    decoration: buildInputDecoration("Maksimal Diskon (Rp)"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: minimumPurchaseController,
                    keyboardType: TextInputType.number,
                    decoration: buildInputDecoration("Minimal Belanja (Rp)"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: expiredAtController,
                    readOnly: true,
                    onTap: pickExpiredDate,
                    decoration: buildInputDecoration("Expired Date").copyWith(
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        "Simpan Voucher",
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

import 'package:flutter/material.dart';
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

  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    pointController.dispose();
    discountPercentController.dispose();
    maxDiscountController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() => isLoading = true);

    final success = await VoucherService.createVoucher(
      name: nameController.text,
      description: descriptionController.text,
      requiredPoints: int.tryParse(pointController.text) ?? 0,
      discountPercent: int.tryParse(discountPercentController.text) ?? 0,
      maxDiscountAmount: int.tryParse(maxDiscountController.text) ?? 0,
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

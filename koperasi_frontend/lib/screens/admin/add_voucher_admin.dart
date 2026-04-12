import 'package:flutter/material.dart';
import '../../services/voucher_service.dart';

class AddVoucherAdminPage extends StatefulWidget {
  const AddVoucherAdminPage({super.key});

  @override
  State<AddVoucherAdminPage> createState() => _AddVoucherAdminPageState();
}

class _AddVoucherAdminPageState extends State<AddVoucherAdminPage> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final pointController = TextEditingController();
  final discountPercentController = TextEditingController();
  final maxDiscountController = TextEditingController();

  bool isLoading = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Voucher")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nama Voucher"),
            ),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Deskripsi Voucher"),
            ),
            TextField(
              controller: pointController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Required Points"),
            ),
            TextField(
              controller: discountPercentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Diskon (%)"),
            ),
            TextField(
              controller: maxDiscountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Maksimal Diskon (Rp)"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : save,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Simpan"),
            )
          ],
        ),
      ),
    );
  }
}

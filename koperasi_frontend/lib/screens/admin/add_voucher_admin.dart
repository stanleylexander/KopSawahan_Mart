import 'package:flutter/material.dart';
import '../../services/voucher_service.dart';

class AddVoucherAdminPage extends StatefulWidget {
  const AddVoucherAdminPage({super.key});

  @override
  State<AddVoucherAdminPage> createState() => _AddVoucherAdminPageState();
}

class _AddVoucherAdminPageState extends State<AddVoucherAdminPage> {
  final nameController = TextEditingController();
  final pointController = TextEditingController();

  bool isLoading = false;

  Future<void> save() async {
    setState(() => isLoading = true);

    bool success = await VoucherService.createVoucher(
      nameController.text,
      int.parse(pointController.text),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nama Voucher"),
            ),
            TextField(
              controller: pointController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Required Points"),
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
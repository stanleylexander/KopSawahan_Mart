import 'package:flutter/material.dart';
import '../../class/voucher.dart';
import '../../services/voucher_service.dart';

class VoucherDetailAdminPage extends StatefulWidget {
  final Voucher voucher;

  const VoucherDetailAdminPage({super.key, required this.voucher});

  @override
  State<VoucherDetailAdminPage> createState() =>
      _VoucherDetailAdminPageState();
}

class _VoucherDetailAdminPageState extends State<VoucherDetailAdminPage> {
  late TextEditingController nameController;
  late TextEditingController pointController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.voucher.name);
    pointController =
        TextEditingController(text: widget.voucher.requiredPoints.toString());
  }

  Future<void> update() async {
    setState(() => isLoading = true);

    bool success = await VoucherService.updateVoucher(
      widget.voucher.id,
      nameController.text,
      int.parse(pointController.text),
    );

    setState(() => isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Voucher berhasil diupdate")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal update voucher")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Voucher")),
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
              onPressed: isLoading ? null : update,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Update"),
            )
          ],
        ),
      ),
    );
  }
}
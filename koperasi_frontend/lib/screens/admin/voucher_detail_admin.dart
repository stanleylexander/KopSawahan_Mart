import 'package:flutter/material.dart';
import '../../class/voucher.dart';
import '../../services/voucher_service.dart';

class VoucherDetailAdminPage extends StatefulWidget {
  final Voucher voucher;

  const VoucherDetailAdminPage({super.key, required this.voucher});

  @override
  State<VoucherDetailAdminPage> createState() => _VoucherDetailAdminPageState();
}

class _VoucherDetailAdminPageState extends State<VoucherDetailAdminPage> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController pointController;
  late TextEditingController discountPercentController;
  late TextEditingController maxDiscountController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.voucher.name);
    descriptionController = TextEditingController(text: widget.voucher.description);
    pointController = TextEditingController(text: widget.voucher.requiredPoints.toString());
    discountPercentController = TextEditingController(text: widget.voucher.discountPercent.toString());
    maxDiscountController = TextEditingController(text: widget.voucher.maxDiscountAmount.toString());
  }

  Future<void> update() async {
    setState(() => isLoading = true);

    final success = await VoucherService.updateVoucher(
      id: widget.voucher.id,
      name: nameController.text,
      description: descriptionController.text,
      requiredPoints: int.tryParse(pointController.text) ?? 0,
      discountPercent: int.tryParse(discountPercentController.text) ?? 0,
      maxDiscountAmount: int.tryParse(maxDiscountController.text) ?? 0,
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

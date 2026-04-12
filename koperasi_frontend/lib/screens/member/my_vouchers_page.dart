import 'package:flutter/material.dart';
import '../../services/voucher_service.dart';

class MyVouchersPage extends StatefulWidget {
  final int? selectedUserVoucherId;

  const MyVouchersPage({
    super.key,
    required this.selectedUserVoucherId,
  });

  @override
  State<MyVouchersPage> createState() => _MyVouchersPageState();
}

class _MyVouchersPageState extends State<MyVouchersPage> {
  List<dynamic> vouchers = [];
  bool isLoading = true;
  int? selectedUserVoucherId;

  @override
  void initState() {
    super.initState();
    selectedUserVoucherId = widget.selectedUserVoucherId;
    loadVouchers();
  }

  Future<void> loadVouchers() async {
    final data = await VoucherService.getMyVouchers();

    setState(() {
      vouchers = data.where((item) => item['status'] == 'unused').toList();
      isLoading = false;
    });
  }

  Widget buildVoucherCard(dynamic item) {
    final voucher = item['voucher'];
    final isSelected = selectedUserVoucherId == item['id'];

    return InkWell(
      onTap: () {
        setState(() {
          selectedUserVoucherId = item['id'];
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.red.shade400 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    voucher['name'] ?? '-',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: Colors.red.shade700),
              ],
            ),
            const SizedBox(height: 8),
            Text("Diskon ${voucher['discount_amount']}%"),
            Text("Maksimal diskon Rp ${voucher['max_discount_amount']}"),
            Text(voucher['description'] ?? ''),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Voucher Saya"),
        backgroundColor: Colors.red.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : vouchers.isEmpty
              ? const Center(child: Text("Belum ada voucher yang bisa dipakai"))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context, null);
                      },
                      child: const Text("Tanpa Voucher"),
                    ),
                    const SizedBox(height: 12),
                    ...vouchers.map(buildVoucherCard),
                  ],
                ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context, selectedUserVoucherId);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text("Gunakan Voucher"),
        ),
      ),
    );
  }
}

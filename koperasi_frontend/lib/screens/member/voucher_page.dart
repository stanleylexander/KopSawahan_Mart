import 'package:flutter/material.dart';
import '../../class/voucher.dart';
import '../../services/voucher_service.dart';

class VoucherPage extends StatefulWidget {
  const VoucherPage({super.key});

  @override
  State<VoucherPage> createState() => _VoucherPageState();
}

class _VoucherPageState extends State<VoucherPage> {
  List<Voucher> vouchers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVouchers();
  }

  Future<void> fetchVouchers() async {
    final data = await VoucherService.getVouchers();

    setState(() {
      vouchers = data;
      isLoading = false;
    });
  }

  Future<void> redeem(int id) async {
    final success = await VoucherService.redeemVoucher(id);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Voucher berhasil ditukar")),
      );

      fetchVouchers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menukar voucher")),
      );
    }
  }

  Future<void> showVoucherDetail(Voucher voucher) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(voucher.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Diskon: ${voucher.discountPercent}%"),
            const SizedBox(height: 8),
            Text("Maksimal diskon: Rp ${voucher.maxDiscountAmount}"),
            const SizedBox(height: 8),
            Text("Poin dibutuhkan: ${voucher.requiredPoints}"),
            const SizedBox(height: 12),
            Text(
              voucher.description.isEmpty
                  ? "Belum ada deskripsi"
                  : voucher.description,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              redeem(voucher.id);
            },
            child: const Text("Tukar"),
          ),
        ],
      ),
    );
  }

  Widget buildVoucherCard(Voucher voucher) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        title: Text(voucher.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Diskon: ${voucher.discountPercent}%"),
            Text("Maksimal: Rp ${voucher.maxDiscountAmount}"),
            Text("Poin: ${voucher.requiredPoints}"),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => showVoucherDetail(voucher),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Voucher"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : vouchers.isEmpty
              ? const Center(child: Text("Tidak ada voucher"))
              : RefreshIndicator(
                  onRefresh: fetchVouchers,
                  child: ListView.builder(
                    itemCount: vouchers.length,
                    itemBuilder: (context, index) {
                      return buildVoucherCard(vouchers[index]);
                    },
                  ),
                ),
    );
  }
}

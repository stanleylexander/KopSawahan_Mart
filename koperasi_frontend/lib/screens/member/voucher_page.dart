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
    bool success = await VoucherService.redeemVoucher(id);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Voucher berhasil ditukar")),
      );

      fetchVouchers(); // refresh (optional)
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menukar voucher")),
      );
    }
  }

  Future<void> confirmRedeem(int id) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: const Text("Tukar voucher ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              redeem(id);
            },
            child: const Text("Ya"),
          ),
        ],
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
              : ListView.builder(
                  itemCount: vouchers.length,
                  itemBuilder: (context, index) {
                    final voucher = vouchers[index];

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(voucher.name),
                        subtitle: Text(
                          "${voucher.requiredPoints} poin",
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => confirmRedeem(voucher.id),
                          child: const Text("Tukar"),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
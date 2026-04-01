import 'package:flutter/material.dart';
import '../../class/voucher.dart';
import '../../services/voucher_service.dart';
import 'add_voucher_admin.dart';
import 'voucher_detail_admin.dart';
import '../drawer/drawer_admin.dart';

class VoucherAdminPage extends StatefulWidget {
  const VoucherAdminPage({super.key});

  @override
  State<VoucherAdminPage> createState() => _VoucherAdminPageState();
}

class _VoucherAdminPageState extends State<VoucherAdminPage> {
  List<Voucher> vouchers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final data = await VoucherService.getVouchers();
    setState(() {
      vouchers = data;
      isLoading = false;
    });
  }

  Future<void> deleteVoucher(int id) async {
    bool success = await VoucherService.deleteVoucher(id);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Voucher berhasil dihapus")),
      );
      fetchData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menghapus voucher")),
      );
    }
  }

  void confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: const Text("Hapus voucher ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteVoucher(id);
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AdminDrawer(),
      appBar: AppBar(
        title: const Text("Admin Voucher"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddVoucherAdminPage(),
            ),
          );
          fetchData();
        },
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: vouchers.length,
              itemBuilder: (context, index) {
                final v = vouchers[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(v.name),
                    subtitle: Text("Poin: ${v.requiredPoints}"),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VoucherDetailAdminPage(voucher: v),
                        ),
                      );
                      fetchData();
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => confirmDelete(v.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
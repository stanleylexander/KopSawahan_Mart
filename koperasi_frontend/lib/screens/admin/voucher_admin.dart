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
  final Color primaryRed = const Color(0xFFB71C1C);
  TextEditingController? _searchController;
  List<Voucher> vouchers = [];
  bool isLoading = true;

  TextEditingController get searchController {
    _searchController ??= TextEditingController();
    return _searchController!;
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  void dispose() {
    _searchController?.dispose();
    super.dispose();
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
      backgroundColor: const Color(0xFFFFF8F6),
      appBar: AppBar(
        title: const Text("Admin Voucher"),
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
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
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryRed))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: searchController,
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: "Cari voucher...",
                      prefixIcon: Icon(Icons.search, color: primaryRed),
                      filled: true,
                      fillColor: Colors.red.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.red.shade100),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.red.shade100),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: primaryRed, width: 2),
                      ),
                    ),
                  ),
                ),
                Expanded(child: buildVoucherList()),
              ],
            ),
    );
  }

  Widget buildVoucherList() {
    final keyword = searchController.text.toLowerCase();
    final filteredVouchers = vouchers.where((voucher) {
      return voucher.name.toLowerCase().contains(keyword);
    }).toList();

    if (filteredVouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 76, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "Voucher tidak ditemukan",
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredVouchers.length,
      itemBuilder: (context, index) {
        return buildVoucherCard(filteredVouchers[index]);
      },
    );
  }

  Widget buildVoucherCard(Voucher voucher) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VoucherDetailAdminPage(voucher: voucher),
          ),
        );
        fetchData();
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voucher.name,
                    style: TextStyle(
                      color: primaryRed,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${voucher.requiredPoints} poin",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${voucher.discountPercent}% diskon",
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VoucherDetailAdminPage(voucher: voucher),
                      ),
                    );
                    fetchData();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => confirmDelete(voucher.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

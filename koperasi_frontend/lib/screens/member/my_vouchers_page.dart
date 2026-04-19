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
  final Color primaryRed = const Color(0xFFB71C1C);
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

    if (!mounted) {
      return;
    }

    setState(() {
      vouchers = data.where((item) => item['status'] == 'unused').toList();
      isLoading = false;
    });
  }

  String formatRupiah(dynamic amount) {
    final value = int.tryParse(amount.toString()) ?? 0;
    return "Rp ${value.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        )}";
  }

  String formatDate(dynamic value) {
    final raw = value?.toString() ?? '';

    if (raw.isEmpty) {
      return "Tidak ada batas waktu";
    }

    final parsed = DateTime.tryParse(raw);

    if (parsed == null) {
      return raw;
    }

    return "${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}";
  }

  Widget buildVoucherImage(Map<String, dynamic> voucher) {
    final image = voucher['image']?.toString() ?? '';

    if (image.isNotEmpty) {
      return Image.network(
        VoucherService.getImageUrl(image),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => buildDefaultVoucherImage(voucher),
      );
    }

    return buildDefaultVoucherImage(voucher);
  }

  Widget buildDefaultVoucherImage(Map<String, dynamic> voucher) {
    final name = voucher['name']?.toString() ?? 'Voucher';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade100,
            Colors.orange.shade100,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              name.characters.first.toUpperCase(),
              style: TextStyle(
                color: primaryRed,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInfoChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF212121),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget buildVoucherCard(dynamic item) {
    final voucher = item['voucher'] as Map<String, dynamic>;
    final isSelected = selectedUserVoucherId == item['id'];

    return InkWell(
      onTap: () {
        setState(() {
          selectedUserVoucherId = item['id'];
        });
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? Colors.red.shade400 : Colors.red.shade100,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade50,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)),
              child: SizedBox(
                width: 118,
                height: 158,
                child: buildVoucherImage(voucher),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            voucher['name']?.toString() ?? '-',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: primaryRed,
                            size: 22,
                          ),
                      ],
                    ),
                    buildInfoChip(
                      "Diskon ${voucher['discount_amount']}%",
                      const Color(0xFFFFEBEE),
                    ),
                    buildInfoChip(
                      "Maks. ${formatRupiah(voucher['max_discount_amount'])}",
                      const Color(0xFFFFF3E0),
                    ),
                    buildInfoChip(
                      "Expired ${formatDate(item['expires_at'])}",
                      const Color(0xFFFFF8F6),
                    ),
                  ],
                ),
              ),
            ),
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
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFFFF8F6),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryRed))
          : vouchers.isEmpty
              ? const Center(child: Text("Belum ada voucher yang bisa dipakai"))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context, null);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryRed,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Tanpa Voucher",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 14),
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
            backgroundColor: primaryRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            "Gunakan Voucher",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

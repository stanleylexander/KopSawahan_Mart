import 'package:flutter/material.dart';
import '../../services/printer_service.dart';
import '../../services/receipt_service.dart';
import '../../utils/receipt_helper.dart';
import '../../utils/permission_helper.dart';

class ReceiptDetailPage extends StatefulWidget {
  final int? receiptId;
  final Map<String, dynamic>? initialReceipt;
  final bool showPrintButton;
  final bool autoPrintOnOpen;

  const ReceiptDetailPage({
    super.key,
    this.receiptId,
    this.initialReceipt,
    this.showPrintButton = false,
    this.autoPrintOnOpen = false,
  });

  @override
  State<ReceiptDetailPage> createState() => _ReceiptDetailPageState();
}

class _ReceiptDetailPageState extends State<ReceiptDetailPage> {
  final Color primaryRed = const Color(0xFFB71C1C);
  final Color creamBackground = const Color(0xFFFFF8F6);
  Map<String, dynamic>? receipt;
  bool isLoading = true;
  bool isPrinting = false;
  bool hasAutoPrinted = false;

  @override
  void initState() {
    super.initState();
    loadReceipt();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> loadReceipt() async {
    if (widget.initialReceipt != null) {
      setState(() {
        receipt = widget.initialReceipt;
        isLoading = false;
      });

      await tryAutoPrint();
      return;
    }

    if (widget.receiptId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final data = await ReceiptService.getReceiptDetail(widget.receiptId!);

    if (!mounted) {
      return;
    }

    setState(() {
      receipt = data;
      isLoading = false;
    });

    await tryAutoPrint();
  }

  Future<void> tryAutoPrint() async {
    if (!widget.autoPrintOnOpen || !widget.showPrintButton || hasAutoPrinted || receipt == null) {
      return;
    }

    hasAutoPrinted = true;

    final savedPrinter = await PrinterService.getSavedPrinter();

    if (savedPrinter == null) {
      return;
    }

    await printReceipt(
      macAddress: savedPrinter["mac"],
      printerName: savedPrinter["name"],
      showSuccessMessage: false,
    );
  }

  Future<void> printReceipt({
    String? macAddress,
    String? printerName,
    bool showSuccessMessage = true,
  }) async {
    if (receipt == null || isPrinting) {
      return;
    }

    setState(() {
      isPrinting = true;
    });

    final success = await PrinterService.printReceipt(
      receipt!,
      macAddress: macAddress,
      printerName: printerName,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      isPrinting = false;
    });

    if (!success) {
      showMessage("Gagal print nota. Coba pilih printer lagi.");
      return;
    }

    final receiptId = receipt?['id'];

    if (receiptId is int) {
      await ReceiptService.markAsPrinted(receiptId);
    }

    if (showSuccessMessage) {
      showMessage("Nota berhasil diprint");
    }
  }

  Future<void> openPrinterPicker() async {

    await PermissionHelper.requestBluetoothPermission();

    final devices = await PrinterService.getPairedDevices();

    if (!mounted) {
      return;
    }

    if (devices.isEmpty) {
      showMessage("Belum ada printer bluetooth yang terhubung");
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pilih Printer",
                  style: TextStyle(
                    color: primaryRed,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...devices.map((device) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade50,
                      child: Icon(Icons.print, color: primaryRed),
                    ),
                    title: Text(device.name),
                    subtitle: Text(device.macAdress),
                    onTap: () async {
                      Navigator.pop(context);
                      await printReceipt(
                        macAddress: device.macAdress,
                        printerName: device.name,
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  List<dynamic> getItems() {
    return (receipt?['order']?['items'] as List?) ?? [];
  }

  String getReceiptTypeLabel() {
    if (receipt?['receipt_type'] == 'digital') {
      return "Nota Digital";
    }

    return "Nota Print";
  }

  Widget buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount = (constraints.maxWidth / 10).floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (index) {
            return Container(
              width: 6,
              height: 1.5,
              color: Colors.grey.shade400,
            );
          }),
        );
      },
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text(": "),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItemRow(dynamic item) {
    final quantity = item['quantity'] ?? 0;
    final price = item['price'] ?? 0;
    final total = quantity * price;
    final name = item['product_name'] ?? item['product']?['name'] ?? 'Produk';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: primaryRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$quantity x ${ReceiptHelper.formatCurrency(price)}",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            ReceiptHelper.formatCurrency(total),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget buildSummaryRow(String label, int value, {bool isNegative = false, bool isTotal = false}) {
    final formattedValue = isNegative
        ? "-${ReceiptHelper.formatCurrency(value)}"
        : ReceiptHelper.formatCurrency(value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? primaryRed : Colors.grey[700],
              fontSize: isTotal ? 15 : 14,
            ),
          ),
          Text(
            formattedValue,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isTotal ? primaryRed : (isNegative ? Colors.green.shade700 : Colors.black87),
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildReceiptCard() {
    if (receipt == null) {
      return const Center(
        child: Text("Nota tidak ditemukan"),
      );
    }

    final order = receipt?['order'] ?? {};

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade50,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    getReceiptTypeLabel(),
                    style: TextStyle(
                      color: primaryRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "KOPSAWAHAN MART",
                  style: TextStyle(
                    color: primaryRed,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Koperasi Merah Putih",
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          buildDashedLine(),
          const SizedBox(height: 16),
          buildInfoRow("No Nota", receipt?['receipt_number'] ?? "-"),
          buildInfoRow("Tanggal", ReceiptHelper.formatDateTime(receipt?['created_at'])),
          buildInfoRow("Order", "#${order['id'] ?? '-'}"),
          buildInfoRow("Pelanggan", receipt?['customer_name'] ?? "-"),
          buildInfoRow("Pembayaran", (receipt?['payment_method'] ?? "-").toString().toUpperCase()),
          const SizedBox(height: 8),
          buildDashedLine(),
          const SizedBox(height: 16),
          Text(
            "Detail Belanja",
            style: TextStyle(
              color: primaryRed,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          ...getItems().map(buildItemRow),
          buildDashedLine(),
          const SizedBox(height: 16),
          buildSummaryRow("Subtotal", receipt?['subtotal_price'] ?? 0),
          if ((receipt?['worker_discount_amount'] ?? 0) > 0)
            buildSummaryRow(
              "Diskon Worker",
              receipt?['worker_discount_amount'] ?? 0,
              isNegative: true,
            ),
          if ((receipt?['voucher_discount_amount'] ?? 0) > 0)
            buildSummaryRow(
              "Diskon Voucher",
              receipt?['voucher_discount_amount'] ?? 0,
              isNegative: true,
            ),
          buildSummaryRow(
            "Total Bayar",
            receipt?['total_price'] ?? 0,
            isTotal: true,
          ),
          const SizedBox(height: 16),
          buildDashedLine(),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  "Terima kasih sudah berbelanja",
                  style: TextStyle(
                    color: primaryRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Simpan nota ini sebagai bukti transaksi",
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBackground,
      appBar: AppBar(
        title: const Text("Detail Nota"),
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.showPrintButton)
            IconButton(
              onPressed: isPrinting ? null : openPrinterPicker,
              icon: const Icon(Icons.print),
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: primaryRed),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  buildReceiptCard(),
                  if (widget.showPrintButton)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isPrinting ? null : openPrinterPicker,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: isPrinting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.print),
                          label: Text(isPrinting ? "Sedang print..." : "Cetak Nota"),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/receipt_helper.dart';

class PrinterService {
  static const String savedPrinterMacKey = "saved_printer_mac";
  static const String savedPrinterNameKey = "saved_printer_name";

  static Future<List<BluetoothInfo>> getPairedDevices() async {
    return PrintBluetoothThermal.pairedBluetooths;
  }

  static Future<void> savePrinter(BluetoothInfo device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(savedPrinterMacKey, device.macAdress);
    await prefs.setString(savedPrinterNameKey, device.name);
  }

  static Future<Map<String, String>?> getSavedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final mac = prefs.getString(savedPrinterMacKey);
    final name = prefs.getString(savedPrinterNameKey);

    if (mac == null || mac.isEmpty) {
      return null;
    }

    return {
      "mac": mac,
      "name": name ?? "Printer Bluetooth",
    };
  }

  static Future<bool> printReceipt(
    Map<String, dynamic> receipt, {
    String? macAddress,
    String? printerName,
  }) async {

    print("=== PRINT START ===");

    final savedPrinter = await getSavedPrinter();
    final address = macAddress ?? savedPrinter?["mac"];

    if (address == null || address.isEmpty) {
      print("❌ MAC address kosong");
      return false;
    }

    final isEnabled = await PrintBluetoothThermal.bluetoothEnabled;
    print("Bluetooth ON: $isEnabled");

    if (!isEnabled) {
      print("❌ Bluetooth mati");
      return false;
    }

    // 🔥 FIX 1: DISCONNECT DULU (WAJIB)
    try {
      await PrintBluetoothThermal.disconnect;
      print("Disconnected old connection");
    } catch (e) {
      print("No previous connection");
    }

    // 🔥 FIX 2: DELAY BIAR STABIL
    await Future.delayed(const Duration(milliseconds: 500));

    // 🔥 CONNECT
    bool isConnected = await PrintBluetoothThermal.connect(
      macPrinterAddress: address,
    );

    print("Connected: $isConnected");

    // 🔥 FIX 3: RETRY kalau gagal
    if (!isConnected) {
      print("Retry connect...");
      await Future.delayed(const Duration(seconds: 1));

      isConnected = await PrintBluetoothThermal.connect(
        macPrinterAddress: address,
      );

      print("Retry result: $isConnected");

      if (!isConnected) {
        print("❌ Gagal connect setelah retry");
        return false;
      }
    }

    // 🔥 BUILD RECEIPT
    final bytes = await buildReceiptBytes(receipt);
    print("Bytes length: ${bytes.length}");

    // 🔥 PRINT
    final result = await PrintBluetoothThermal.writeBytes(bytes);
    print("Print result: $result");

    // 🔥 SAVE PRINTER
    if (result && macAddress != null && printerName != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(savedPrinterMacKey, macAddress);
      await prefs.setString(savedPrinterNameKey, printerName);
    }

    // 🔥 FIX 4: DISCONNECT SETELAH PRINT
    await Future.delayed(const Duration(milliseconds: 300));
    await PrintBluetoothThermal.disconnect;

    print("=== PRINT END ===");

    return result;
  }

  static Future<List<int>> buildReceiptBytes(Map<String, dynamic> receipt) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];
    final order = receipt['order'] ?? {};
    final items = (order['items'] as List?) ?? [];
    final receiptType = receipt['receipt_type'] == 'digital' ? 'NOTA DIGITAL' : 'NOTA PEMBELIAN';

    bytes.addAll(generator.reset());
    bytes.addAll(generator.text(
      'KOPSAWAHAN MART',
      styles: const PosStyles(
        bold: true,
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    ));
    bytes.addAll(generator.text(
      'Koperasi Merah Putih',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    ));
    bytes.addAll(generator.text(
      receiptType,
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text("No Nota : ${receipt['receipt_number'] ?? '-'}"));
    bytes.addAll(generator.text("Tanggal : ${ReceiptHelper.formatDateTime(receipt['created_at'])}"));
    bytes.addAll(generator.text("Order   : #${order['id'] ?? receipt['order_id'] ?? '-'}"));
    bytes.addAll(generator.text("Kasir   : ${receipt['cashier_name'] ?? '-'}"));
    bytes.addAll(generator.text("Bayar   : ${receipt['payment_method'] ?? '-'}"));
    bytes.addAll(generator.hr());

    for (final item in items) {
      final quantity = item['quantity'] ?? 0;
      final price = item['price'] ?? 0;
      final total = quantity * price;
      final productName = item['product_name'] ??
          item['product']?['name'] ??
          'Produk';

      bytes.addAll(generator.text(
        productName.toString(),
        styles: const PosStyles(bold: true),
      ));
      bytes.addAll(generator.row([
        PosColumn(
          text: "$quantity x ${ReceiptHelper.formatCurrency(price)}",
          width: 7,
        ),
        PosColumn(
          text: ReceiptHelper.formatCurrency(total),
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }

    bytes.addAll(generator.hr());
    bytes.addAll(generator.row([
      PosColumn(text: "Subtotal", width: 7),
      PosColumn(
        text: ReceiptHelper.formatCurrency(receipt['subtotal_price'] ?? 0),
        width: 5,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]));

    if ((receipt['worker_discount_amount'] ?? 0) > 0) {
      bytes.addAll(generator.row([
        PosColumn(text: "Diskon Worker", width: 7),
        PosColumn(
          text: "-${ReceiptHelper.formatCurrency(receipt['worker_discount_amount'] ?? 0)}",
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }

    if ((receipt['voucher_discount_amount'] ?? 0) > 0) {
      bytes.addAll(generator.row([
        PosColumn(text: "Diskon Voucher", width: 7),
        PosColumn(
          text: "-${ReceiptHelper.formatCurrency(receipt['voucher_discount_amount'] ?? 0)}",
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }

    if ((receipt['amount_paid'] ?? 0) > 0) {
      bytes.addAll(generator.row([
        PosColumn(text: "Uang Bayar", width: 7),
        PosColumn(
          text: ReceiptHelper.formatCurrency(receipt['amount_paid'] ?? 0),
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }

    if ((receipt['change_amount'] ?? 0) > 0) {
      bytes.addAll(generator.row([
        PosColumn(text: "Kembalian", width: 7),
        PosColumn(
          text: ReceiptHelper.formatCurrency(receipt['change_amount'] ?? 0),
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }

    bytes.addAll(generator.row([
      PosColumn(
        text: "TOTAL",
        width: 5,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: ReceiptHelper.formatCurrency(receipt['total_price'] ?? 0),
        width: 7,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]));
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text(
      'Terima kasih sudah berbelanja',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    ));
    bytes.addAll(generator.text(
      'Simpan nota ini sebagai bukti \n transaksi',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.feed(3));
    bytes.addAll(generator.cut());

    return bytes;
  }
}

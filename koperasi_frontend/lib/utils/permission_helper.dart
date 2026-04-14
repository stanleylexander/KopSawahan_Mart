import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<void> requestBluetoothPermission() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    await Permission.location.request();
  }
}
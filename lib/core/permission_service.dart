import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return false; 

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final int sdkInt = androidInfo.version.sdkInt;

    Map<Permission, PermissionStatus> statuses;

    if (sdkInt >= 31) {
      // Android 12 and above (Requires new Bluetooth/Nearby permissions)
      statuses = await [
        Permission.location,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.nearbyWifiDevices,
        Permission.requestInstallPackages, // For sending APKs later
      ].request();
    } else {
      // Android 11 and below (Relies heavily on Location for discovery)
      statuses = await [
        Permission.location,
        Permission.bluetooth,
        Permission.requestInstallPackages,
      ].request();
    }

    // Handle Storage Permission separately because of Scoped Storage
    if (sdkInt >= 30) {
      await Permission.manageExternalStorage.request();
    } else {
      await Permission.storage.request();
    }

    // Check if location (the most critical one) was granted
    return statuses[Permission.location]?.isGranted ?? false;
  }
}